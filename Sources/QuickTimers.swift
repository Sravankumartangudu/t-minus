import AppKit

/// One-off countdown reminders started from the menu ("Remind me in 25 min"). Saved to
/// UserDefaults so they survive a restart.
final class QuickTimers {
    struct Item: Codable {
        let id: String
        let title: String
        let due: Date
    }

    private let key = "quickTimers"
    private(set) var items: [Item] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Item].self, from: data) {
            // Drop timers that went off long ago while the app wasn't running.
            items = saved.filter { $0.due > Date().addingTimeInterval(-300) }
        }
    }

    var meetings: [Meeting] {
        items.map {
            Meeting(id: $0.id, title: $0.title, start: $0.due, end: $0.due.addingTimeInterval(300),
                    link: nil, calendar: "Quick timer", attendees: 0, kind: .timer)
        }
    }

    func add(minutes: Int, title: String) {
        items.append(Item(id: "timer-\(UUID().uuidString)", title: title,
                          due: Date().addingTimeInterval(Double(minutes) * 60)))
        save()
    }

    func remove(_ id: String) {
        items.removeAll { $0.id == id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) { UserDefaults.standard.set(data, forKey: key) }
    }

    /// Asks for a label and duration. Returns nil if cancelled or the duration is invalid.
    static func prompt() -> (title: String, minutes: Int)? {
        let alert = NSAlert()
        alert.messageText = "New quick timer"
        alert.informativeText = "T-Minus will show your alert style when the time is up."

        let label = NSTextField(frame: NSRect(x: 0, y: 32, width: 260, height: 24))
        label.placeholderString = "What's it for? (e.g. Stretch break)"
        let minutes = NSTextField(frame: NSRect(x: 0, y: 0, width: 80, height: 24))
        minutes.stringValue = "25"
        let unit = NSTextField(labelWithString: "minutes")
        unit.frame = NSRect(x: 88, y: 3, width: 100, height: 18)
        let box = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 56))
        [label, minutes, unit].forEach(box.addSubview)
        alert.accessoryView = box
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = label

        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn,
              let m = Int(minutes.stringValue.trimmingCharacters(in: .whitespaces)), m > 0, m <= 24 * 60
        else { return nil }
        let title = label.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return (title.isEmpty ? "\(m)-min timer" : title, m)
    }
}
