import SwiftUI

/// One animation frame of a superhero style.
struct HeroFrame {
    let t: Double               // seconds since the alert appeared
    let closing: Double?        // seconds since the user acted, nil while open
    let action: OverlayAction?  // what the user chose
    let size: CGSize
    let remaining: Double       // seconds until the meeting starts (negative once live)
    let card: MeetingCard

    var center: CGPoint { CGPoint(x: size.width / 2, y: size.height / 2) }

    /// 1 while open, easing to 0 over `d` seconds once the user acts.
    func fade(_ d: Double = 0.45) -> Double { closing.map { max(0, 1 - $0 / d) } ?? 1 }

    /// "T-01:58", or "+00:12" once the meeting is live.
    var countdown: String {
        let s = Int(abs(remaining))
        return String(format: remaining > 0 ? "T-%02d:%02d" : "+%02d:%02d", s / 60, s % 60)
    }
}

/// Shared shell for the superhero styles: animation timeline, a dimmed backdrop that dismisses
/// on click, keyboard shortcuts, and a short exit animation before the action is reported.
struct HeroStage<Content: View>: View {
    let meeting: Meeting
    let primary: Color
    let accent: Color
    var kicker = "STARTING IN"
    var dim = 0.4
    var exit = 0.7
    let onAction: (OverlayAction) -> Void
    @ViewBuilder let content: (HeroFrame) -> Content

    @State private var shownAt = Date()
    @State private var closingAt: Date?
    @State private var closingAction: OverlayAction?

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { tl in
                let frame = makeFrame(now: tl.date, size: geo.size)
                ZStack {
                    Color.black.opacity(dim * min(1, frame.t / 0.4) * frame.fade(exit))
                        .contentShape(Rectangle())
                        .onTapGesture { act(.dismiss) }
                    content(frame)
                }
            }
            .overlay(keyboardShortcuts)
        }
        .ignoresSafeArea()
    }

    private func makeFrame(now: Date, size: CGSize) -> HeroFrame {
        let card = MeetingCard(meeting: meeting, primary: primary, accent: accent, kicker: kicker, now: now,
                               t: now.timeIntervalSince(shownAt),
                               onJoin: { act(.join) }, onSnooze: { act(.snooze) }, onDismiss: { act(.dismiss) })
        return HeroFrame(t: now.timeIntervalSince(shownAt),
                         closing: closingAt.map { now.timeIntervalSince($0) },
                         action: closingAction,
                         size: size,
                         remaining: meeting.start.timeIntervalSince(now),
                         card: card)
    }

    private var keyboardShortcuts: some View {
        ZStack {
            Button("") { act(.join) }.keyboardShortcut(.defaultAction)
            Button("") { act(.dismiss) }.keyboardShortcut(.cancelAction)
            Button("") { act(.snooze) }.keyboardShortcut("s", modifiers: [])
        }
        .opacity(0)
        .frame(width: 0, height: 0)
    }

    private func act(_ a: OverlayAction) {
        guard closingAt == nil else { return }
        closingAt = Date()
        closingAction = a
        DispatchQueue.main.asyncAfter(deadline: .now() + exit) { onAction(a) }
    }
}

// MARK: - Animation helpers

func clamp01(_ x: Double) -> Double { min(1, max(0, x)) }

/// Progress (0…1) of an animation segment that starts at `start` and lasts `duration`.
func seg(_ t: Double, _ start: Double, _ duration: Double) -> Double { clamp01((t - start) / duration) }

func easeOutCubic(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
func easeInCubic(_ x: Double) -> Double { x * x * x }
func easeOutBack(_ x: Double) -> Double {
    let c1 = 1.70158, c3 = c1 + 1
    return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
}

func dot(_ c: CGPoint, _ r: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
}

func polyline(_ pts: [CGPoint]) -> Path {
    var p = Path()
    p.addLines(pts)
    return p
}

/// A deterministic jagged line from `a` to `b`, used for lightning bolts and glass cracks.
func jagged(from a: CGPoint, to b: CGPoint, segments n: Int, roughness: Double, seed: Int) -> [CGPoint] {
    let dx = b.x - a.x, dy = b.y - a.y
    let len = max(1, sqrt(dx * dx + dy * dy))
    let nx = -dy / len, ny = dx / len
    var walk = [0.0]
    for i in 1...n { walk.append(walk[i - 1] + (hash01(seed, i) - 0.5) * 2 * roughness) }
    let drift = walk[n]
    return (0...n).map { i in
        let f = CGFloat(Double(i) / Double(n))
        let off = CGFloat(walk[i] - drift * Double(f))
        return CGPoint(x: a.x + dx * f + nx * off, y: a.y + dy * f + ny * off)
    }
}

/// Comic-book starburst.
struct Burst: Shape {
    var spikes = 14

    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        for i in 0..<(spikes * 2) {
            let a = Double(i) / Double(spikes * 2) * 2 * .pi
            let k = i % 2 == 0 ? 1.25 : 0.9 + hash01(i, 77) * 0.08
            let pt = CGPoint(x: c.x + r.width / 2 * CGFloat(k * cos(a)), y: c.y + r.height / 2 * CGFloat(k * sin(a)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// A "THWIP!" / "SMASH!" style sound-effect pop.
struct ComicPop: View {
    let text: String
    let fill: Color
    var size: CGFloat = 48

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .italic()
            .foregroundColor(fill)
            .shadow(color: .black, radius: 0, x: 3, y: 3)
            .shadow(color: .black, radius: 0, x: -1, y: -1)
            .padding(.horizontal, 24).padding(.vertical, 16)
            .background(Burst().fill(Color.white))
            .overlay(Burst().stroke(Color.black, lineWidth: 3))
            .allowsHitTesting(false)
    }
}
