import AppKit
import AVFoundation
import EventKit
import ServiceManagement
import SwiftUI

final class Settings {
    static let shared = Settings()
    private let d = UserDefaults.standard

    var leadMinutes: Int {
        get { d.object(forKey: "leadMinutes") as? Int ?? 2 }
        set { d.set(newValue, forKey: "leadMinutes") }
    }
    var theme: Theme {
        get { Theme(rawValue: d.string(forKey: "theme") ?? "") ?? .matrix }
        set { d.set(newValue.rawValue, forKey: "theme") }
    }
    var alertStyle: AlertStyle {
        get { AlertStyle(rawValue: d.string(forKey: "alertStyle") ?? "") ?? .portal }
        set { d.set(newValue.rawValue, forKey: "alertStyle") }
    }
    var sound: Bool {
        get { d.object(forKey: "sound") as? Bool ?? true }
        set { d.set(newValue, forKey: "sound") }
    }
    var voice: Bool {
        get { d.object(forKey: "voice") as? Bool ?? false }
        set { d.set(newValue, forKey: "voice") }
    }
    var videoOnly: Bool {
        get { d.object(forKey: "videoOnly") as? Bool ?? true }
        set { d.set(newValue, forKey: "videoOnly") }
    }
    var reminders: Bool {
        get { d.object(forKey: "reminders") as? Bool ?? false }
        set { d.set(newValue, forKey: "reminders") }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let cal = CalendarService()
    private let overlay = OverlayController()
    private let synth = AVSpeechSynthesizer()
    private let settings = Settings.shared
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    private var meetings: [Meeting] = []
    private var reminders: [Meeting] = []
    private let timers = QuickTimers()
    // Read live so the warning clears once access is granted in System Settings.
    private var remindersDenied: Bool { ![.fullAccess, .notDetermined].contains(cal.remindersStatus) }
    private var demo: Meeting?
    private var alerted = Set<String>()
    private var handled = Set<String>()
    private var snoozed: [String: Date] = [:]
    private var lastRefresh = Date.distantPast
    private var accessDenied = false

    private var relevant: [Meeting] {
        // The video-link filter only applies to calendar events; reminders and timers always count.
        let events = settings.videoOnly ? meetings.filter { $0.link != nil } : meetings
        let extras = (settings.reminders ? reminders : []) + timers.meetings
        return (events + extras + [demo].compactMap { $0 }).sorted { $0.start < $1.start }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        updateTitle()

        cal.requestAccess { [weak self] ok in
            self?.accessDenied = !ok
            self?.refresh()
        }
        if settings.reminders { enableReminders() }
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: cal.store, queue: .main) { [weak self] _ in
            self?.refresh()
        }

        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t

        let args = CommandLine.arguments
        // --demo uses the saved style; --demo-<style> (e.g. --demo-portal, --demo-webslinger) forces one.
        if let arg = args.first(where: { $0.hasPrefix("--demo") }) {
            let style = AlertStyle(rawValue: String(arg.dropFirst("--demo-".count)))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.fireTest(style: style) }
        }
    }

    // MARK: - Scheduling

    private func refresh() {
        meetings = cal.upcoming()
        lastRefresh = Date()
        if settings.reminders {
            cal.upcomingReminders { [weak self] list in
                self?.reminders = list
                self?.updateTitle()
            }
        }
        updateTitle()
    }

    private func tick() {
        if Date().timeIntervalSince(lastRefresh) > 60 { refresh() }
        updateTitle()
        // Wait while an alert is up or a dialog (e.g. "New timer…") is open: a modal session
        // would swallow clicks on the overlay.
        guard !overlay.isShowing, NSApp.modalWindow == nil else { return }

        let now = Date()
        for m in relevant where !handled.contains(m.id) {
            // Meetings warn ahead of time; reminders and timers fire when they're due.
            let lead = m.kind == .meeting ? Double(settings.leadMinutes * 60) : 0
            // How late an alert may still fire (e.g. after the Mac wakes from sleep). A meeting
            // is pointless after 5 minutes, but a timer should always say "time's up".
            let grace: Double
            switch m.kind {
            case .meeting: grace = 300
            case .reminder: grace = 3600
            case .timer: grace = .infinity
            }
            if let until = snoozed[m.id] {
                if now >= until {
                    snoozed[m.id] = nil
                    return present(m)
                }
                continue
            }
            let remaining = m.start.timeIntervalSince(now)
            if !alerted.contains(m.id), remaining <= lead, remaining > -grace {
                alerted.insert(m.id)
                return present(m)
            }
        }
    }

    private func present(_ m: Meeting, style: AlertStyle? = nil) {
        if settings.sound { NSSound(named: "Submarine")?.play() }
        if settings.voice {
            let mins = Int((m.start.timeIntervalSinceNow / 60).rounded())
            let plural = mins == 1 ? "" : "s"
            let line: String
            switch m.kind {
            case .meeting:
                line = "Incoming transmission. \(m.title) " + (mins <= 0 ? "is live now." : "launches in \(mins) minute\(plural).")
            case .reminder:
                line = "Reminder. \(m.title) " + (mins <= 0 ? "is due now." : "is due in \(mins) minute\(plural).")
            case .timer:
                line = "Time's up. \(m.title)."
            }
            synth.speak(AVSpeechUtterance(string: line))
        }
        overlay.show(m, style: style ?? settings.alertStyle, theme: settings.theme, leadSeconds: Double(max(1, settings.leadMinutes) * 60)) { [weak self] action in
            self?.handle(action, for: m)
        }
    }

    private func handle(_ action: OverlayAction, for m: Meeting) {
        synth.stopSpeaking(at: .immediate)
        switch action {
        case .join:
            handled.insert(m.id)
            if let url = m.link { NSWorkspace.shared.open(url) }
        case .snooze:
            snoozed[m.id] = Date().addingTimeInterval(60)
        case .dismiss:
            handled.insert(m.id)
        }
        if m.id == demo?.id, action != .snooze { demo = nil }
        if m.kind == .timer, action != .snooze { timers.remove(m.id) }
    }

    // MARK: - Menu bar

    private func updateTitle() {
        guard let button = statusItem?.button else { return }
        let now = Date()
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
        var text = "◎ T-∞"
        var color: NSColor? = nil

        if let next = relevant.first(where: { $0.start > now }), next.start.timeIntervalSince(now) < 3600 {
            let rem = Int(next.start.timeIntervalSince(now))
            let blink = rem < 60 && rem % 2 == 0
            let clock = rem < 60 ? String(format: "0:%02d", rem) : "\(rem / 60 + 1)m"
            text = "\(blink ? "○" : "◉") \(clock) · \(truncate(next.title))"
            if rem <= settings.leadMinutes * 60 { color = NSColor(settings.theme.primary) }
        } else if let live = relevant.first(where: { $0.start <= now && $0.end > now }) {
            text = "● LIVE · \(truncate(live.title))"
        }

        var attrs: [NSAttributedString.Key: Any] = [.font: font]
        if let color { attrs[.foregroundColor] = color }
        button.attributedTitle = NSAttributedString(string: text, attributes: attrs)
    }

    private func truncate(_ s: String, _ n: Int = 18) -> String {
        s.count > n ? String(s.prefix(n - 1)) + "…" : s
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let header = NSMenuItem(title: "T-MINUS // MEETING LAUNCH CONTROL", action: nil, keyEquivalent: "")
        header.attributedTitle = NSAttributedString(string: header.title, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold),
            .foregroundColor: NSColor(settings.theme.primary),
        ])
        menu.addItem(header)

        if accessDenied {
            menu.addItem(item("⚠ Calendar access denied — open Privacy settings", #selector(openPrivacy)))
        }
        if remindersDenied && settings.reminders {
            menu.addItem(item("⚠ Reminders access denied — open Privacy settings", #selector(openRemindersPrivacy)))
        }

        let now = Date()
        let upcoming = relevant.filter { $0.end > now }.prefix(12)
        if upcoming.isEmpty {
            menu.addItem(disabled("  no transmissions scheduled. touch grass."))
        }
        let today = DateFormatter(), later = DateFormatter()
        today.dateFormat = "HH:mm"
        later.dateFormat = "EEE HH:mm"
        for m in upcoming {
            let when = m.start <= now ? "LIVE " : (Calendar.current.isDateInToday(m.start) ? today : later).string(from: m.start)
            let tag: String
            switch m.kind {
            case .timer: tag = "  ⏱ timer"
            case .reminder: tag = "  ☑ reminder"
            case .meeting: tag = m.link == nil ? "" : "  ⟶ \(m.provider.lowercased())"
            }
            let mi = item("\(when)  \(truncate(m.title, 36))\(tag)", m.link == nil ? nil : #selector(joinFromMenu(_:)))
            mi.representedObject = m.link
            menu.addItem(mi)
        }

        menu.addItem(.separator())
        menu.addItem(item("⚡ Fire test alert", #selector(fireTestFromMenu), key: "t"))

        let timerMenu = NSMenu()
        timerMenu.addItem(item("New timer with a label…", #selector(newCustomTimer)))
        timerMenu.addItem(.separator())
        for n in [5, 10, 15, 25, 30, 45, 60] {
            let mi = item("In \(n) min", #selector(newPresetTimer(_:)))
            mi.tag = n
            timerMenu.addItem(mi)
        }
        if !timers.items.isEmpty {
            timerMenu.addItem(.separator())
            timerMenu.addItem(disabled("Running"))
            for t in timers.items {
                let left = max(0, Int(t.due.timeIntervalSince(now) / 60 + 1))
                let mi = item("✕ Cancel “\(truncate(t.title, 28))” (\(left)m left)", #selector(cancelTimer(_:)))
                mi.representedObject = t.id
                timerMenu.addItem(mi)
            }
        }
        menu.addItem(submenu("⏱ Quick timer", timerMenu))

        let styleMenu = NSMenu()
        for st in AlertStyle.allCases {
            if st == AlertStyle.heroes.first {
                styleMenu.addItem(.separator())
                styleMenu.addItem(disabled("Superhero styles"))
            }
            let mi = item(st.label, #selector(setStyle(_:)))
            mi.representedObject = st.rawValue
            mi.state = settings.alertStyle == st ? .on : .off
            styleMenu.addItem(mi)
        }
        menu.addItem(submenu("Alert style", styleMenu))

        let leadMenu = NSMenu()
        for n in [1, 2, 3, 5, 10] {
            let mi = item("\(n) min before", #selector(setLead(_:)))
            mi.tag = n
            mi.state = settings.leadMinutes == n ? .on : .off
            leadMenu.addItem(mi)
        }
        menu.addItem(submenu("Alert lead time", leadMenu))

        let themeMenu = NSMenu()
        for th in Theme.allCases {
            let mi = item(th.label, #selector(setTheme(_:)))
            mi.representedObject = th.rawValue
            mi.state = settings.theme == th ? .on : .off
            themeMenu.addItem(mi)
        }
        menu.addItem(submenu("Theme", themeMenu))

        menu.addItem(toggle("Sound", settings.sound, #selector(toggleSound)))
        menu.addItem(toggle("Voice announcement", settings.voice, #selector(toggleVoice)))
        menu.addItem(toggle("Only meetings with video links", settings.videoOnly, #selector(toggleVideoOnly)))
        menu.addItem(toggle("Include Apple Reminders", settings.reminders, #selector(toggleReminders)))
        menu.addItem(toggle("Launch at login", SMAppService.mainApp.status == .enabled, #selector(toggleLogin)))

        menu.addItem(.separator())
        menu.addItem(item("Refresh calendars", #selector(manualRefresh), key: "r"))
        menu.addItem(item("Quit T-Minus", #selector(NSApplication.terminate(_:)), key: "q"))
    }

    private func item(_ title: String, _ action: Selector?, key: String = "") -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: action, keyEquivalent: key)
        mi.target = action == #selector(NSApplication.terminate(_:)) ? NSApp : self
        return mi
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        mi.isEnabled = false
        return mi
    }

    private func toggle(_ title: String, _ on: Bool, _ action: Selector) -> NSMenuItem {
        let mi = item(title, action)
        mi.state = on ? .on : .off
        return mi
    }

    private func submenu(_ title: String, _ sub: NSMenu) -> NSMenuItem {
        let mi = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        mi.submenu = sub
        return mi
    }

    // MARK: - Actions

    @objc private func joinFromMenu(_ sender: NSMenuItem) {
        if let url = sender.representedObject as? URL { NSWorkspace.shared.open(url) }
    }

    @objc private func fireTestFromMenu() { fireTest() }

    private func fireTest(style: AlertStyle? = nil) {
        // Don't replace a real alert: it would close without its Join/Snooze/Dismiss handling.
        guard !overlay.isShowing else { return }
        let m = Meeting.demo(startingIn: Double(settings.leadMinutes * 60))
        demo = m
        alerted.insert(m.id)
        present(m, style: style)
    }

    @objc private func setStyle(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let st = AlertStyle(rawValue: raw) { settings.alertStyle = st }
    }

    @objc private func setLead(_ sender: NSMenuItem) { settings.leadMinutes = sender.tag }

    @objc private func setTheme(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let th = Theme(rawValue: raw) { settings.theme = th }
        updateTitle()
    }

    @objc private func toggleSound() { settings.sound.toggle() }
    @objc private func toggleVoice() { settings.voice.toggle() }
    @objc private func toggleVideoOnly() { settings.videoOnly.toggle() }
    @objc private func manualRefresh() { refresh() }

    @objc private func toggleReminders() {
        settings.reminders.toggle()
        if settings.reminders { enableReminders() } else { reminders = []; updateTitle() }
    }

    private func enableReminders() {
        cal.requestRemindersAccess { [weak self] _ in self?.refresh() }
    }

    @objc private func newPresetTimer(_ sender: NSMenuItem) {
        timers.add(minutes: sender.tag, title: "\(sender.tag)-min timer")
        updateTitle()
    }

    @objc private func newCustomTimer() {
        guard let (title, minutes) = QuickTimers.prompt() else { return }
        timers.add(minutes: minutes, title: title)
        updateTitle()
    }

    @objc private func cancelTimer(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? String { timers.remove(id) }
        updateTitle()
    }

    @objc private func openRemindersPrivacy() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("T-Minus: launch-at-login change failed: \(error)")
        }
    }

    @objc private func openPrivacy() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}
