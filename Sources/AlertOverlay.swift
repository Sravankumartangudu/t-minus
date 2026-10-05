import AppKit
import SwiftUI

enum OverlayAction { case join, snooze, dismiss }

enum AlertStyle: String, CaseIterable {
    case takeover, flyby

    var label: String {
        switch self {
        case .takeover: return "Full takeover (incoming transmission)"
        case .flyby: return "Flyby (rocket tows a banner across)"
        }
    }
}

enum TerminalScript {
    private static let banter: [(String, String, String)] = [
        ("[WARN]", "coffee level", "CRITICALLY LOW"),
        ("[WARN]", "open browser tabs", "347"),
        ("[WARN]", "unsaved vim buffers", "3 (:wq pending)"),
        ("[WARN]", "hair", "NOT DEPLOYED"),
        ("[WARN]", "jira notifications", "IGNORED (412)"),
        ("[WARN]", "keyboard acoustics", "CHERRY MX BLUE"),
        ("[WARN]", "standup duration", "EXCEEDS SLA"),
        ("[FAIL]", "excuse generator", "OUT OF ENTROPY"),
        ("[ OK ]", "rubber duck", "ONLINE"),
        ("[ OK ]", "imposter syndrome", "NOMINAL"),
        ("[ OK ]", "pants", "OPTIONAL"),
        ("[ OK ]", "root cause", "IT WAS DNS"),
        ("[ OK ]", "git status", "CLEAN (ALLEGEDLY)"),
        ("[ OK ]", "camera", "SUSPICIOUSLY OFF"),
    ]

    static func lines(for m: Meeting) -> [String] {
        let seed = Int.random(in: 0..<Int(Int32.max))
        let target = m.link.map { ($0.host ?? "") + $0.path } ?? "localhost/no-uplink"
        let picks = banter.shuffled().prefix(2)
        return [
            "$ ./tminus --uplink \(target)",
            row("[ OK ]", "dns resolve", "142.250.\(seed % 255).\(seed / 255 % 255)"),
            row("[ OK ]", "tls1.3 handshake", "0x" + String(seed, radix: 16).uppercased()),
            row("[ OK ]", "crew manifest", m.attendees > 0 ? "\(m.attendees) operators" : "just you"),
        ] + picks.map { row($0.0, $0.1, $0.2) } + [
            row("[ OK ]", "microphone", "MUTE ADVISED"),
        ]
    }

    private static func row(_ tag: String, _ k: String, _ v: String) -> String {
        "\(tag) \(k) " + String(repeating: ".", count: max(2, 20 - k.count)) + " \(v)"
    }
}

struct AlertView: View {
    let meeting: Meeting
    let theme: Theme
    let leadSeconds: Double
    let onAction: (OverlayAction) -> Void

    @State private var shownAt = Date()
    @State private var powered = false
    @State private var flash = 0.85
    @State private var closing = false
    @State private var log: [String] = []

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
            MatrixRain(theme: theme).opacity(0.4)
            RadialGradient(colors: [.clear, .black.opacity(0.95)], center: .center, startRadius: 150, endRadius: 950)
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { tl in
                let t = tl.date.timeIntervalSince(shownAt)
                let remaining = meeting.start.timeIntervalSince(tl.date)
                ZStack {
                    hud(now: tl.date, t: t)
                    VStack(spacing: 36) {
                        VStack(spacing: 12) {
                            GlitchText(text: "INCOMING TRANSMISSION", t: t, theme: theme, size: 22)
                            Text("PRIORITY: \(priority(remaining))  //  CHANNEL: \(meeting.provider)")
                                .font(.mono(13, .semibold)).tracking(3)
                                .foregroundColor(theme.primary.opacity(0.85))
                        }
                        DecryptText(text: meeting.title, t: t - 0.3, theme: theme)
                        Text(meeting.subtitle)
                            .font(.mono(15)).tracking(1)
                            .foregroundColor(.white.opacity(0.65))
                        HStack(spacing: 80) {
                            CountdownRing(remaining: remaining, lead: leadSeconds, t: t, theme: theme)
                            TerminalLog(lines: log, t: t, theme: theme)
                        }
                        .padding(.vertical, 10)
                        controls
                    }
                    .padding(60)
                    ScanSweep(t: t, theme: theme)
                }
            }
            Scanlines()
            Color.white.opacity(flash).allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .scaleEffect(x: 1, y: powered ? 1 : 0.004)
        .opacity(closing ? 0 : 1)
        .onAppear {
            log = TerminalScript.lines(for: meeting)
            withAnimation(.easeOut(duration: 0.35)) { powered = true }
            withAnimation(.easeOut(duration: 0.7).delay(0.1)) { flash = 0 }
        }
    }

    private var controls: some View {
        HStack(spacing: 26) {
            NeonButton(label: meeting.link == nil ? "ACKNOWLEDGE" : "JOIN", key: "⏎", color: theme.primary, filled: true) { act(.join) }
                .keyboardShortcut(.defaultAction)
            NeonButton(label: "SNOOZE 1M", key: "S", color: theme.accent, filled: false) { act(.snooze) }
                .keyboardShortcut("s", modifiers: [])
            NeonButton(label: "DISMISS", key: "ESC", color: .gray, filled: false) { act(.dismiss) }
                .keyboardShortcut(.cancelAction)
        }
    }

    private func hud(now: Date, t: Double) -> some View {
        let clock = DateFormatter()
        clock.dateFormat = "HH:mm:ss"
        let cpu = 20 + Int(hash01(Int(t * 2), 9) * 60)
        let net = 100 + Int(hash01(Int(t * 2), 11) * 900)
        return ZStack {
            CornerBrackets(len: 46).stroke(theme.primary.opacity(0.8), lineWidth: 2).padding(18)
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("T-MINUS v1.0 // MEETING LAUNCH CONTROL").bold()
                        Text("UPLINK: ARMED  ·  PID \(ProcessInfo.processInfo.processIdentifier)")
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(clock.string(from: now)).font(.mono(26, .bold)).monospacedDigit()
                        Text(TimeZone.current.identifier.uppercased())
                    }
                }
                Spacer()
                HStack {
                    Text("CPU \(cpu)%  ·  MEM OK  ·  NET ▲▼ \(net) kb/s")
                    Spacer()
                    Text("[⏎] JOIN   [S] SNOOZE   [ESC] DISMISS")
                }
            }
            .padding(40)
            .font(.mono(12))
            .foregroundColor(theme.primary.opacity(0.75))
        }
    }

    private func priority(_ remaining: Double) -> String {
        remaining <= 0 ? "OVERDUE" : remaining < 60 ? "CRITICAL" : "HIGH"
    }

    private func act(_ a: OverlayAction) {
        guard !closing else { return }
        withAnimation(.easeIn(duration: 0.2)) {
            closing = true
            powered = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { onAction(a) }
    }
}

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class OverlayController {
    private var window: OverlayWindow?
    var isShowing: Bool { window != nil }

    func show(_ meeting: Meeting, style: AlertStyle, theme: Theme, leadSeconds: Double,
              onAction: @escaping (OverlayAction) -> Void) {
        close()
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main else { return }

        let w = OverlayWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        w.level = .screenSaver
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.isReleasedWhenClosed = false
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let finish: (OverlayAction) -> Void = { [weak self] action in
            self?.close()
            onAction(action)
        }
        let view: AnyView
        switch style {
        case .takeover: view = AnyView(AlertView(meeting: meeting, theme: theme, leadSeconds: leadSeconds, onAction: finish))
        case .flyby: view = AnyView(FlybyView(meeting: meeting, theme: theme, onAction: finish))
        }
        let host = NSHostingView(rootView: view)
        host.sizingOptions = []
        w.contentView = host
        w.setFrame(screen.frame, display: true)
        w.makeKeyAndOrderFront(nil)
        NSApp.activate()
        window = w
    }

    func close() {
        window?.orderOut(nil)
        window = nil
    }
}
