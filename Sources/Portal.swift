import SwiftUI

/// A glowing portal swirls open, throws off sparks, and a floating meeting card flips out of it.
/// Clicking the card's Join button joins (with confetti); clicking anywhere else closes the portal.
struct PortalView: View {
    let meeting: Meeting
    let theme: Theme
    let onAction: (OverlayAction) -> Void

    @State private var shownAt = Date()
    @State private var closingAt: Date?
    @State private var closingAction: OverlayAction?

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1.0 / 60)) { tl in
                let t = tl.date.timeIntervalSince(shownAt)
                let c = closingAt.map { tl.date.timeIntervalSince($0) }
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.46)
                let open = openness(t: t, closing: c)
                let card = cardProgress(t: t, closing: c)

                ZStack {
                    Color.black.opacity(0.35 * min(1, t / 0.4) * (c.map { max(0, 1 - $0 / 0.5) } ?? 1))
                        .contentShape(Rectangle())
                        .onTapGesture { act(.dismiss) }

                    PortalRing(theme: theme, t: t, open: open, center: center)

                    MeetingCard(meeting: meeting, primary: theme.primary, accent: theme.accent, now: tl.date, t: t,
                                onJoin: { act(.join) }, onSnooze: { act(.snooze) }, onDismiss: { act(.dismiss) })
                        .scaleEffect(max(0.01, card))
                        .rotation3DEffect(.degrees((1 - min(1, card)) * 80), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                        .opacity(min(1, card * 1.5))
                        .offset(y: CGFloat(sin(t * 1.6)) * 6)
                        .position(center)

                    if closingAction == .join, let c {
                        ConfettiBurst(t: c, center: center, theme: theme)
                    }
                }
            }
            .overlay(keyboardShortcuts)
        }
        .ignoresSafeArea()
    }

    /// Ring radius factor: springs open, collapses when closing.
    private func openness(t: Double, closing c: Double?) -> Double {
        let opening = easeOutBack(min(1, t / 0.9))
        guard let c else { return opening }
        return opening * max(0, 1 - c / 0.45)
    }

    /// Card emerges after the ring opens, and shrinks back into it first when closing.
    private func cardProgress(t: Double, closing c: Double?) -> Double {
        let p = easeOutBack(max(0, min(1, (t - 0.45) / 0.7)))
        guard let c else { return p }
        return p * max(0, 1 - c / 0.25)
    }

    private func easeOutBack(_ x: Double) -> Double {
        let c1 = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + (a == .join ? 1.0 : 0.5)) { onAction(a) }
    }
}

// MARK: - Portal ring and sparks

private struct PortalRing: View {
    let theme: Theme
    let t: Double
    let open: Double
    let center: CGPoint

    var body: some View {
        Canvas { ctx, _ in
            guard open > 0.01 else { return }
            let R = 290 * open
            let colors: [Color] = [theme.primary, theme.accent, .white, .orange]

            // Outer glow and the darker "event horizon" inside the ring.
            ctx.drawLayer { layer in
                layer.addFilter(.blur(radius: 45))
                layer.stroke(circle(R), with: .color(theme.primary.opacity(0.55)), lineWidth: 40)
            }
            ctx.fill(circle(R * 0.97), with: .radialGradient(
                Gradient(colors: [theme.primary.opacity(0.18), .black.opacity(0.55)]),
                center: center, startRadius: 0, endRadius: R))

            ctx.blendMode = .plusLighter

            // Swirling arcs that make up the ring.
            for i in 0..<280 {
                let speed = 0.7 + hash01(i, 1) * 1.5
                let a = hash01(i, 2) * 2 * .pi + t * speed
                let r = R * (0.93 + hash01(i, 3) * 0.14) + CGFloat(sin(t * 3 + Double(i))) * 3
                let len = 0.06 + hash01(i, 4) * 0.3
                var p = Path()
                p.addArc(center: center, radius: r, startAngle: .radians(a - len), endAngle: .radians(a), clockwise: false)
                let color = colors[Int(hash01(i, 5) * 3)]
                ctx.stroke(p, with: .color(color.opacity(0.35 + 0.6 * hash01(i, 6))),
                           style: StrokeStyle(lineWidth: 1 + hash01(i, 7) * 2.2, lineCap: .round))
            }

            // Sparks flung tangentially off the ring, falling under gravity.
            let step = 1.0 / 140
            let newest = Int(t / step)
            for e in stride(from: newest, to: max(0, newest - 220), by: -1) {
                let emitted = Double(e) * step
                let age = t - emitted
                let life = 0.6 + hash01(e, 8) * 0.9
                guard emitted > 0.25, age < life else { continue }
                let theta = hash01(e, 9) * 2 * .pi + emitted * 1.2
                let start = CGPoint(x: center.x + R * cos(theta), y: center.y + R * sin(theta))
                let v = 140 + hash01(e, 10) * 220
                let vx = -sin(theta) * v + cos(theta) * 40
                let vy = cos(theta) * v + sin(theta) * 40
                let x = start.x + vx * age
                let y = start.y + vy * age + 380 * age * age
                let dt = 0.025
                var seg = Path()
                seg.move(to: CGPoint(x: x - vx * dt, y: y - (vy + 760 * age) * dt))
                seg.addLine(to: CGPoint(x: x, y: y))
                let color = colors[1 + Int(hash01(e, 11) * 3) % 3]
                ctx.stroke(seg, with: .color(color.opacity(1 - age / life)),
                           style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }

    private func circle(_ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
    }
}

private struct ConfettiBurst: View {
    let t: Double
    let center: CGPoint
    let theme: Theme

    var body: some View {
        Canvas { ctx, _ in
            let colors: [Color] = [theme.primary, theme.accent, .pink, .yellow, .orange, .purple, .white]
            for i in 0..<160 {
                let angle = hash01(i, 1) * 2 * .pi
                let speed = 350 + hash01(i, 2) * 650
                let x = center.x + CGFloat(cos(angle) * speed * t)
                let y = center.y + CGFloat(sin(angle) * speed * t + 900 * t * t)
                let w = 6 + hash01(i, 3) * 6, h = 3 + hash01(i, 4) * 4
                var g = ctx
                g.opacity = max(0, 1 - t / 1.0)
                g.translateBy(x: x, y: y)
                g.rotate(by: .radians(t * (4 + hash01(i, 5) * 10)))
                g.fill(Path(CGRect(x: -w / 2, y: -h / 2, width: w, height: h)),
                       with: .color(colors[i % colors.count]))
            }
        }
        .allowsHitTesting(false)
    }
}
