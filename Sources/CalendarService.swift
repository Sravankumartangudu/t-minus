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

    var provider: String {
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
                attendees: 9)
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
                           attendees: e.attendees?.count ?? 0)
        }
        .sorted { $0.start < $1.start }
    }
}
