import SwiftUI

/// The floating meeting card shared by Portal and the superhero styles: rolling countdown,
/// title, time, attendee avatars, and Join / Snooze / Dismiss.
struct MeetingCard: View {
    let meeting: Meeting
    let primary: Color
    let accent: Color
    var kicker = "STARTING IN"
    let now: Date
    let t: Double
    let onJoin: () -> Void
    let onSnooze: () -> Void
    let onDismiss: () -> Void

    private var liveLabel: String {
        switch meeting.kind {
        case .meeting: return "LIVE NOW"
        case .reminder: return "DUE NOW"
        case .timer: return "TIME'S UP"
        }
    }

    private static let clock: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        let remaining = meeting.start.timeIntervalSince(now)
        let live = remaining <= 0
        let s = Int(abs(remaining))
        let f = Self.clock

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(live ? Color.red : primary).frame(width: 8, height: 8)
                        .opacity(live && Int(t * 2) % 2 == 0 ? 0.3 : 1)
                    Text(live ? liveLabel : kicker)
                        .font(.system(size: 12, weight: .bold, design: .rounded)).tracking(2)
                        .foregroundColor(live ? .red : primary)
                        .lineLimit(1)
                }
                Spacer()
                Text(meeting.provider.capitalized)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }

            Text(String(format: "%@%02d:%02d", live ? "+" : "", s / 60, s % 60))
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: !live))
                .animation(.snappy, value: s)
                .foregroundStyle(LinearGradient(colors: [.white, accent], startPoint: .top, endPoint: .bottom))
                .shadow(color: primary.opacity(0.6), radius: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text("\(f.string(from: meeting.start)) – \(f.string(from: meeting.end))  ·  \(meeting.calendar)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            Avatars(people: meeting.people, total: meeting.attendees, primary: primary, accent: accent)

            HStack(spacing: 18) {
                ShimmerButton(title: meeting.link == nil ? "Got it" : "Join now  ⏎",
                              primary: primary, accent: accent, t: t, action: onJoin)
                Button("Snooze 1m", action: onSnooze).buttonStyle(.plain)
                Button("Dismiss", action: onDismiss).buttonStyle(.plain)
                Spacer()
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.7))
        }
        .padding(28)
        .frame(width: 440)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(LinearGradient(colors: [Color(red: 0.09, green: 0.09, blue: 0.16).opacity(0.96),
                                              Color.black.opacity(0.96)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(AngularGradient(colors: [primary, accent, .white.opacity(0.4), primary],
                                        center: .center, angle: .degrees(t * 60)),
                        lineWidth: 1.5)
        )
        .shadow(color: primary.opacity(0.45), radius: 30)
        .contentShape(RoundedRectangle(cornerRadius: 26))
        .onTapGesture {}  // clicks on the card itself shouldn't fall through and dismiss
    }
}

private struct Avatars: View {
    let people: [String]
    let total: Int
    let primary: Color
    let accent: Color

    var body: some View {
        let shown = Array(people.prefix(5))
        let extra = max(total, people.count) - shown.count
        let palette: [Color] = [primary, accent, .pink, .orange, .purple, .teal]

        HStack(spacing: 10) {
            if shown.isEmpty {
                Text("Just you this time")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                HStack(spacing: -9) {
                    ForEach(Array(shown.enumerated()), id: \.offset) { i, name in
                        Text(initials(name))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(palette[abs(name.hashValue) % palette.count]))
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                            .zIndex(Double(-i))
                    }
                    if extra > 0 {
                        Text("+\(extra)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    }
                }
                Text("\(max(total, people.count)) joining")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private func initials(_ s: String) -> String {
        let base = s.contains("@") ? String(s.split(separator: "@")[0]) : s
        let parts = base.split(whereSeparator: { " ._-".contains($0) })
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

private struct ShimmerButton: View {
    let title: String
    let primary: Color
    let accent: Color
    let t: Double
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 22).padding(.vertical, 12)
                .background(
                    ZStack {
                        Capsule().fill(LinearGradient(colors: [primary, accent], startPoint: .leading, endPoint: .trailing))
                        GeometryReader { g in
                            let p = CGFloat((t * 0.6).truncatingRemainder(dividingBy: 1))
                            LinearGradient(colors: [.clear, .white.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 50)
                                .rotationEffect(.degrees(20))
                                .offset(x: p * (g.size.width + 100) - 75)
                        }
                        .clipShape(Capsule())
                    }
                )
                .shadow(color: primary.opacity(hover ? 0.9 : 0.5), radius: hover ? 16 : 8)
                .scaleEffect(hover ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hover = h } }
    }
}
