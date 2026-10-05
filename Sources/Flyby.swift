import SwiftUI

/// Lightweight alert: a pixel rocket tows a banner with the meeting details across the screen.
/// The whole screen catches clicks — clicking the banner joins, clicking anywhere else dismisses.
struct FlybyView: View {
    let meeting: Meeting
    let theme: Theme
    let onAction: (OverlayAction) -> Void

    @State private var shownAt = Date()
    @State private var dim = 0.0
    @State private var closing = false

    private let passDuration = 9.0
    private let pause = 1.5
    private let convoyWidth: CGFloat = 620

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(dim)
                    .contentShape(Rectangle())
                    .onTapGesture { act(.dismiss) }

                TimelineView(.animation(minimumInterval: 1.0 / 60)) { tl in
                    let t = tl.date.timeIntervalSince(shownAt)
                    ZStack {
                        DataTrail(theme: theme, t: t) { position(at: $0, in: geo.size) }
                        if let p = position(at: t, in: geo.size) {
                            Convoy(meeting: meeting, theme: theme, t: t, now: tl.date)
                                .rotationEffect(.degrees(cos(t * 2.2) * 3))
                                .position(p)
                                .onTapGesture { act(.join) }
                        }
                    }
                }

                keyboardShortcuts
            }
        }
        .ignoresSafeArea()
        .opacity(closing ? 0 : 1)
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { dim = 0.18 } }
    }

    /// Convoy centre at time `t`, or nil while it's between passes.
    private func position(at t: Double, in size: CGSize) -> CGPoint? {
        guard t >= 0 else { return nil }
        let cycle = passDuration + pause
        let p = t.truncatingRemainder(dividingBy: cycle) / passDuration
        guard p <= 1 else { return nil }
        let pass = Int(t / cycle)
        let x = -convoyWidth / 2 + CGFloat(p) * (size.width + convoyWidth)
        let baseY = size.height * (0.18 + 0.14 * CGFloat(hash01(pass, 5)))
        return CGPoint(x: x, y: baseY + CGFloat(sin(t * 2.2)) * 12)
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
        guard !closing else { return }
        withAnimation(.easeIn(duration: 0.2)) { closing = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { onAction(a) }
    }
}

/// Banner ── tether ── flame + rocket, left to right.
private struct Convoy: View {
    let meeting: Meeting
    let theme: Theme
    let t: Double
    let now: Date

    var body: some View {
        HStack(spacing: 0) {
            card
            Tether(sag: CGFloat(sin(t * 3)) * 5)
                .stroke(theme.primary.opacity(0.75), style: StrokeStyle(lineWidth: 2, dash: [5, 4], dashPhase: CGFloat(-t * 30)))
                .frame(width: 56, height: 24)
            Flame(t: t).frame(width: 28, height: 20)
            PixelShip(theme: theme).frame(width: 72, height: 44)
        }
    }

    private var card: some View {
        let remaining = meeting.start.timeIntervalSince(now)
        let s = Int(abs(remaining))
        let clock = remaining > 0
            ? String(format: "T-%02d:%02d", s / 60, s % 60)
            : String(format: "● LIVE +%02d:%02d", s / 60, s % 60)
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        let crew = meeting.attendees > 0 ? "\(meeting.attendees) crew" : "solo"

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("▸ INCOMING TRANSMISSION")
                Spacer()
                Text(clock)
                    .monospacedDigit()
                    .foregroundColor(remaining > 0 ? theme.primary : .red)
            }
            .font(.mono(11, .bold))
            .foregroundColor(theme.primary)

            Text(meeting.title)
                .font(.mono(20, .heavy))
                .foregroundColor(.white)
                .lineLimit(1)

            Text("\(f.string(from: meeting.start))–\(f.string(from: meeting.end))  ·  \(meeting.provider)  ·  \(crew)")
                .font(.mono(11))
                .foregroundColor(.white.opacity(0.65))
                .lineLimit(1)

            Text(meeting.link == nil ? "click me to ACK  ·  click anywhere to dismiss" : "click me to JOIN  ·  click anywhere to dismiss")
                .font(.mono(10, .semibold))
                .foregroundColor(theme.accent.opacity(0.9))
        }
        .padding(14)
        .frame(width: 440)
        .background(Chamfer(c: 10).fill(Color.black.opacity(0.88)))
        .overlay(Chamfer(c: 10).stroke(theme.primary, lineWidth: 1.5))
        .shadow(color: theme.primary.opacity(0.6), radius: 12)
    }
}

private struct Tether: Shape {
    var sag: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.midY), control: CGPoint(x: r.midX, y: r.midY + sag))
        return p
    }
}

private struct PixelShip: View {
    let theme: Theme

    private static let art = [
        "....##............",
        "....####..........",
        "....######........",
        "..############....",
        ".###wwww#oo#####..",
        "################ww",
        ".###wwww#oo#####..",
        "..############....",
        "....######........",
        "....####..........",
        "....##............",
    ]

    var body: some View {
        Canvas { ctx, size in
            let px = size.width / CGFloat(Self.art[0].count)
            for (r, row) in Self.art.enumerated() {
                for (c, ch) in row.enumerated() {
                    let color: Color? = ch == "#" ? theme.primary : ch == "w" ? .white : ch == "o" ? theme.accent : nil
                    guard let color else { continue }
                    ctx.fill(Path(CGRect(x: CGFloat(c) * px, y: CGFloat(r) * px, width: px + 0.5, height: px + 0.5)),
                             with: .color(color))
                }
            }
        }
        .shadow(color: theme.primary, radius: 6)
    }
}

/// Flickering pixel exhaust, hottest next to the rocket.
private struct Flame: View {
    let t: Double

    var body: some View {
        Canvas { ctx, size in
            let px: CGFloat = 4
            let cols = Int(size.width / px)
            let rows = Int(size.height / px)
            let colors: [Color] = [.white, .yellow, .orange, .red]
            let frame = Int(t * 20)
            for r in 0..<rows {
                let edge = r == 0 || r == rows - 1
                let len = Int(hash01(r, frame) * Double(cols - 1)) + (edge ? 1 : 2)
                for k in 0..<min(len, cols) {
                    let color = colors[min(colors.count - 1, k * colors.count / cols)]
                    ctx.fill(Path(CGRect(x: size.width - CGFloat(k + 1) * px, y: CGFloat(r) * px, width: px, height: px)),
                             with: .color(color.opacity(1 - Double(k) / Double(cols + 1))))
                }
            }
        }
    }
}

/// Glyphs shed from the banner's tail, drifting down and fading out.
private struct DataTrail: View {
    let theme: Theme
    let t: Double
    let position: (Double) -> CGPoint?

    var body: some View {
        Canvas { ctx, _ in
            let step = 0.06
            let count = 26
            let glyphs = theme.glyphs.map { ctx.resolve(Text($0).font(.mono(13, .bold)).foregroundColor(theme.primary)) }
            let newest = Int(t / step)
            for e in stride(from: newest, to: newest - count, by: -1) {
                let emitted = Double(e) * step
                guard let p = position(emitted) else { continue }
                let age = t - emitted
                var g = ctx
                g.opacity = max(0, 1 - age / (Double(count) * step))
                let x = p.x - 300 + CGFloat(hash01(e, 1) * 40 - 20)
                let y = p.y + CGFloat(hash01(e, 2) * 50 - 25) + CGFloat(age * 70)
                g.draw(glyphs[Int(hash01(e, 3) * Double(glyphs.count)) % glyphs.count], at: CGPoint(x: x, y: y))
            }
        }
        .allowsHitTesting(false)
    }
}
