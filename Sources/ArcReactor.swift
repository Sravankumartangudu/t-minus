import SwiftUI

/// Superhero style inspired by a genius billionaire's armor HUD: holographic rings boot up,
/// a targeting reticle locks onto the card, and suit telemetry types out on both sides.
struct ArcReactorView: View {
    let meeting: Meeting
    let onAction: (OverlayAction) -> Void

    private let gold = Color(red: 1.0, green: 0.78, blue: 0.28)
    private let red = Color(red: 0.88, green: 0.14, blue: 0.14)
    private let holo = Color(red: 0.45, green: 0.9, blue: 1.0)

    var body: some View {
        HeroStage(meeting: meeting, primary: gold, accent: red, kicker: "LAUNCH WINDOW", dim: 0.55, exit: 0.5,
                  onAction: onAction) { f in
            let p = seg(f.t, 0.6, 0.35)
            let flicker = p < 1 && hash01(Int(f.t * 40), 3) < 0.35 ? 0.25 : 1.0
            let locked = f.t > 0.95
            let joinBoost = f.action == .join ? 1 + (1 - f.fade(0.3)) * 0.2 : 1
            ZStack {
                HUDRings(t: f.t, center: f.center, holo: holo, gold: gold, collapse: 1 - f.fade(0.4))
                Reticle(t: f.t, size: f.size, center: f.center, color: red, lockedColor: gold)
                    .opacity(f.fade(0.3))
                Telemetry(lines: leftLines(f), t: f.t, color: holo)
                    .opacity(f.fade(0.3))
                    .position(x: f.size.width * 0.13, y: f.center.y)
                Telemetry(lines: rightLines(f), t: f.t, color: holo)
                    .opacity(f.fade(0.3))
                    .position(x: f.size.width * 0.87, y: f.center.y)
                Text(locked ? "◆ TARGET LOCKED ◆" : "ACQUIRING…")
                    .font(.mono(13, .bold)).tracking(4)
                    .foregroundColor(locked ? gold : red)
                    .opacity(f.t > 0.2 ? f.fade(0.3) * (locked && Int(f.t * 3) % 2 == 0 ? 0.6 : 1) : 0)
                    .position(x: f.center.x, y: f.center.y - 245)
                    .allowsHitTesting(false)
                f.card
                    .scaleEffect((0.9 + 0.1 * easeOutBack(p)) * joinBoost)
                    .opacity(p * flicker * f.fade(0.3))
                    .position(f.center)
                Color.white
                    .opacity(f.action == .join ? max(0, 0.5 - (f.closing ?? 0)) : 0)
                    .allowsHitTesting(false)
            }
        }
    }

    private func leftLines(_ f: HeroFrame) -> [String] {
        let n = { (i: Int, lo: Int, hi: Int) in lo + Int(hash01(Int(f.t * 5), i) * Double(hi - lo)) }
        return [
            "SYS.BOOT ............ OK",
            "REPULSORS ......... \(n(1, 96, 100))%",
            "THRUSTERS ....... ARMED",
            "ALTITUDE .... \(n(3, 30_000, 31_000)) FT",
            "HULL TEMP ........ \(n(4, 40, 44))°C",
            "CAFFEINE .......... \(n(2, 8, 15))%",
            "SARCASM ......... MAXED",
        ]
    }

    private func rightLines(_ f: HeroFrame) -> [String] {
        [
            "TARGET ....... CALENDAR",
            "CHANNEL .. \(meeting.provider)",
            "CREW ................ \(meeting.attendees)",
            "ETA ........... \(f.countdown)",
            "SHIELDS ........... 100%",
            "MUTE ........... ADVISED",
            "SNACKS .............. NIL",
        ]
    }
}

private struct HUDRings: View {
    let t: Double
    let center: CGPoint
    let holo: Color
    let gold: Color
    let collapse: Double  // 0 open → 1 collapsed into the center

    var body: some View {
        Canvas { ctx, size in
            let k = CGFloat(1 - collapse)
            guard k > 0.01 else { return }
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
                Gradient(colors: [holo.opacity(0.16), .clear]), center: center, startRadius: 0, endRadius: 700))
            ctx.blendMode = .plusLighter

            // Rings boot up one after another, alternating spin direction.
            for i in 0..<5 {
                let grow = easeOutCubic(seg(t, 0.1 + Double(i) * 0.12, 0.5))
                guard grow > 0 else { continue }
                let r = CGFloat(270 + i * 48) * k
                let dir = i % 2 == 0 ? 1.0 : -1.0
                let start = t * dir * (0.25 + Double(i) * 0.08)
                var arc = Path()
                arc.addArc(center: center, radius: r, startAngle: .radians(start),
                           endAngle: .radians(start + grow * 2 * .pi), clockwise: false)
                let style = i % 2 == 0 ? StrokeStyle(lineWidth: 2, dash: [3, 7]) : StrokeStyle(lineWidth: 1)
                ctx.stroke(arc, with: .color(holo.opacity(0.8 - Double(i) * 0.1)), style: style)
            }

            // Tick marks on the inner ring.
            let tickR = 270 * k
            let ticks = Int(60 * easeOutCubic(seg(t, 0.2, 0.6)))
            var tickPath = Path()
            for j in 0..<ticks {
                let a = Double(j) / 60 * 2 * .pi - t * 0.1
                let r1 = tickR - 6
                let r2 = tickR - (j % 5 == 0 ? 22 : 12)
                tickPath.move(to: CGPoint(x: center.x + r1 * CGFloat(cos(a)), y: center.y + r1 * CGFloat(sin(a))))
                tickPath.addLine(to: CGPoint(x: center.x + r2 * CGFloat(cos(a)), y: center.y + r2 * CGFloat(sin(a))))
            }
            ctx.stroke(tickPath, with: .color(holo.opacity(0.7)), lineWidth: 1.5)

            // Heavy gold segments sweeping around the middle ring.
            let segR = 366 * k
            let segAlpha = 0.8 * easeOutCubic(seg(t, 0.5, 0.4))
            for s in 0..<3 {
                let a = Double(s) * 2 * .pi / 3 + t * 0.6
                var p = Path()
                p.addArc(center: center, radius: segR, startAngle: .radians(a), endAngle: .radians(a + 0.5), clockwise: false)
                ctx.stroke(p, with: .color(gold.opacity(segAlpha)), lineWidth: 6)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Four corner brackets that slide in from the screen edges and lock around the card.
private struct Reticle: View {
    let t: Double
    let size: CGSize
    let center: CGPoint
    let color: Color
    let lockedColor: Color

    var body: some View {
        Canvas { ctx, _ in
            let p = CGFloat(easeOutCubic(seg(t, 0.2, 0.7)))
            let fromW = size.width / 2 - 40, fromH = size.height / 2 - 40
            let hw = fromW + (250 - fromW) * p
            let hh = fromH + (215 - fromH) * p
            let len: CGFloat = 36
            let corners: [(CGFloat, CGFloat)] = [(-1, -1), (1, -1), (-1, 1), (1, 1)]
            var path = Path()
            for (sx, sy) in corners {
                let corner = CGPoint(x: center.x + sx * hw, y: center.y + sy * hh)
                path.move(to: CGPoint(x: corner.x, y: corner.y - sy * len))
                path.addLine(to: corner)
                path.addLine(to: CGPoint(x: corner.x - sx * len, y: corner.y))
            }
            ctx.stroke(path, with: .color(t > 0.95 ? lockedColor : color), lineWidth: 3)
        }
        .allowsHitTesting(false)
    }
}

/// A column of suit readouts that types itself out.
private struct Telemetry: View {
    let lines: [String]
    let t: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                let shown = max(0, Int((t - 0.5 - Double(i) * 0.12) * 70))
                Text(String(line.prefix(shown)))
                    .font(.mono(12, .semibold))
                    .foregroundColor(color.opacity(0.85))
                    .lineLimit(1)
            }
        }
        .frame(width: 230, alignment: .leading)
        .padding(14)
        .overlay(CornerBrackets(len: 14).stroke(color.opacity(0.6), lineWidth: 1.5))
        .allowsHitTesting(false)
    }
}
