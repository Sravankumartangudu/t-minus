import EventKit
import Foundation

struct Meeting: Identifiable, Equatable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let link: URL?
    let calendar: String
    let attendees: Int
    var people: [String] = []
    var kind: Kind = .meeting

    enum Kind { case meeting, reminder, timer }

    var provider: String {
        if kind == .reminder { return "REMINDER" }
        if kind == .timer { return "QUICK TIMER" }
        guard let host = link?.host else { return "NO UPLINK" }
        if host.contains("meet.google") { return "GOOGLE MEET" }
        if host.contains("zoom") { return "ZOOM" }
        if host.contains("teams") { return "MS TEAMS" }
        return host.uppercased()
    }

    var subtitle: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let crew = attendees > 0 ? "\(attendees) crew" : "solo mission"
        return "\(f.string(from: start)) – \(f.string(from: end))  ·  \(calendar)  ·  \(crew)"
    }

    static func demo(startingIn seconds: Double) -> Meeting {
        Meeting(id: "demo-\(UUID().uuidString)",
                title: "Weekly Standup (Test Transmission)",
                start: Date().addingTimeInterval(seconds),
                end: Date().addingTimeInterval(seconds + 1800),
                link: URL(string: "https://meet.google.com/landing"),
                calendar: "Simulation",
                attendees: 9,
                people: ["Ada Lovelace", "Linus Torvalds", "Grace Hopper", "Alan Turing", "Margaret Hamilton",
                         "Dennis Ritchie", "Ken Thompson", "Barbara Liskov", "Tim Berners-Lee"])
    }
}

enum LinkFinder {
    private static let patterns = [
        #"https://meet\.google\.com/[a-z]{3,4}-[a-z]{4}-[a-z]{3,4}"#,
        #"https://[\w.-]*zoom\.us/j/[^\s<>"]+"#,
        #"https://teams\.microsoft\.com/l/meetup-join/[^\s<>"]+"#,
    ]

    static func find(in texts: [String?]) -> URL? {
        let haystacks = texts.compactMap { $0 }
        for p in patterns {
            for t in haystacks {
                if let r = t.range(of: p, options: .regularExpression) {
                    return URL(string: String(t[r]))
                }
            }
        }
        return nil
    }
}

final class CalendarService {
    let store = EKEventStore()

    var status: EKAuthorizationStatus { EKEventStore.authorizationStatus(for: .event) }

    func requestAccess(_ done: @escaping (Bool) -> Void) {
        if status == .fullAccess { return done(true) }
        store.requestFullAccessToEvents { ok, _ in
            DispatchQueue.main.async { done(ok) }
        }
    }

    var remindersStatus: EKAuthorizationStatus { EKEventStore.authorizationStatus(for: .reminder) }

    func requestRemindersAccess(_ done: @escaping (Bool) -> Void) {
        if remindersStatus == .fullAccess { return done(true) }
        store.requestFullAccessToReminders { ok, _ in
            DispatchQueue.main.async { done(ok) }
        }
    }

    /// Incomplete Apple Reminders that are due at a specific time in the window.
    /// Reminders with only a due date (no time) are skipped, like all-day events.
    func upcomingReminders(hours: Double = 18, _ done: @escaping ([Meeting]) -> Void) {
        guard remindersStatus == .fullAccess else { return done([]) }
        let now = Date()
        let pred = store.predicateForIncompleteReminders(withDueDateStarting: now.addingTimeInterval(-3600),
                                                         ending: now.addingTimeInterval(hours * 3600),
                                                         calendars: nil)
        store.fetchReminders(matching: pred) { items in
            let list = (items ?? []).compactMap { r -> Meeting? in
                guard let comps = r.dueDateComponents, comps.hour != nil,
                      let due = Calendar.current.date(from: comps) else { return nil }
                return Meeting(id: "rem-\(r.calendarItemIdentifier)@\(Int(due.timeIntervalSince1970))",
                               title: r.title?.isEmpty == false ? r.title! : "(untitled)",
                               start: due,
                               end: due.addingTimeInterval(900),
                               link: LinkFinder.find(in: [r.url?.absoluteString, r.location, r.notes]),
                               calendar: r.calendar?.title ?? "Reminders",
                               attendees: 0,
                               kind: .reminder)
            }
            DispatchQueue.main.async { done(list) }
        }
    }

    func upcoming(hours: Double = 18) -> [Meeting] {
        guard status == .fullAccess else { return [] }
        let now = Date()
        let pred = store.predicateForEvents(withStart: now.addingTimeInterval(-3600),
                                            end: now.addingTimeInterval(hours * 3600),
                                            calendars: nil)
        return store.events(matching: pred).compactMap { e -> Meeting? in
            if e.isAllDay || e.status == .canceled || e.endDate < now { return nil }
            if let me = e.attendees?.first(where: { $0.isCurrentUser }), me.participantStatus == .declined {
                return nil
            }
            return Meeting(id: "\(e.calendarItemIdentifier)@\(Int(e.startDate.timeIntervalSince1970))",
                           title: e.title?.isEmpty == false ? e.title! : "(untitled)",
                           start: e.startDate,
                           end: e.endDate,
                           link: LinkFinder.find(in: [e.url?.absoluteString, e.location, e.notes]),
                           calendar: e.calendar?.title ?? "Calendar",
                           attendees: e.attendees?.count ?? 0,
                           people: (e.attendees ?? []).map { p in
                               p.name ?? p.url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
                           })
        }
        .sorted { $0.start < $1.start }
    }
}
