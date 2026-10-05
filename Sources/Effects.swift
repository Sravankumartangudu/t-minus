import SwiftUI

/// Falling glyph columns. Every position is derived from time + column hash, so there's no state to keep.
struct MatrixRain: View {
    let theme: Theme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                let cell: CGFloat = 20
                let cols = Int(size.width / cell) + 1
                let rows = Int(size.height / cell) + 1
                let trail = 18
                let font = Font.mono(16, .medium)
                let glyphs = theme.glyphs
                let bodyGlyphs = glyphs.map { ctx.resolve(Text($0).font(font).foregroundColor(theme.primary)) }
                let headGlyphs = glyphs.map { ctx.resolve(Text($0).font(font).foregroundColor(.white)) }
                let span = Double(rows + trail)

                for c in 0..<cols {
                    let speed = 5 + hash01(c, 1) * 15
                    let offset = hash01(c, 2) * span
                    let head = Int((t * speed + offset).truncatingRemainder(dividingBy: span))
                    let flicker = Int(t * 4 + hash01(c, 3) * 10)
                    for k in 0..<trail {
                        let r = head - k
                        guard r >= 0, r < rows else { continue }
                        let gi = Int(hash01(c &* 131 &+ r, flicker) * Double(glyphs.count)) % glyphs.count
                        var g = ctx
                        g.opacity = k == 0 ? 1 : (1 - Double(k) / Double(trail)) * 0.75
                        g.draw(k == 0 ? headGlyphs[gi] : bodyGlyphs[gi],
                               at: CGPoint(x: CGFloat(c) * cell + cell / 2, y: CGFloat(r) * cell + cell / 2))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct Scanlines: View {
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(0.28)))
                y += 3
            }
        }
        .allowsHitTesting(false)
    }
}

/// The bright CRT refresh band rolling down the screen.
struct ScanSweep: View {
    let t: Double
    let theme: Theme

    var body: some View {
        GeometryReader { g in
            let p = CGFloat(t.truncatingRemainder(dividingBy: 5) / 5)
            LinearGradient(colors: [.clear, theme.primary.opacity(0.07), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 180)
                .offset(y: p * (g.size.height + 360) - 180)
        }
        .allowsHitTesting(false)
    }
}

/// RGB-split title that occasionally "bursts" into scrambled glyphs.
struct GlitchText: View {
    let text: String
    let t: Double
    let theme: Theme
    let size: CGFloat

    var body: some View {
        let frame = Int(t * 14)
        let burst = hash01(frame, 7) < 0.08
        let amp: CGFloat = burst ? 9 : 1.2
        let o = { (k: Int) -> CGFloat in CGFloat(hash01(frame, k) * 2 - 1) * amp }
        let shown = burst ? scrambled(frame) : text
        ZStack {
            Text(shown).foregroundColor(Color(red: 1, green: 0, blue: 0.35)).offset(x: o(1), y: o(2)).blendMode(.screen)
            Text(shown).foregroundColor(Color(red: 0, green: 0.9, blue: 1)).offset(x: o(3), y: o(4)).blendMode(.screen)
            Text(shown).foregroundColor(.white)
        }
        .font(.mono(size, .black))
        .tracking(size * 0.35)
        .shadow(color: theme.primary, radius: 10)
    }

    private func scrambled(_ frame: Int) -> String {
        let glyphs = Array("#$%&@!?/\\<>*=+")
        return String(text.enumerated().map { i, ch in
            ch != " " && hash01(i, frame) < 0.3 ? glyphs[Int(hash01(frame, i) * Double(glyphs.count)) % glyphs.count] : ch
        })
    }
}

/// Typewriter reveal with a "decrypting" leading edge of random glyphs.
struct DecryptText: View {
    let text: String
    let t: Double
    let theme: Theme

    var body: some View {
        let chars = Array(text.uppercased())
        let n = max(0, min(chars.count, Int(t * 30)))
        let cursorOn = n < chars.count || Int(t * 2.4) % 2 == 0
        (Text(display(chars, n)) + Text(cursorOn ? "█" : " ").foregroundColor(theme.primary))
            .font(.mono(56, .heavy))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .shadow(color: theme.primary.opacity(0.9), radius: 16)
            .frame(maxWidth: 1150)
    }

    private func display(_ chars: [Character], _ n: Int) -> String {
        var s = String(chars.prefix(n))
        guard n < chars.count else { return s }
        let glyphs = theme.glyphs
        for i in n..<min(chars.count, n + 5) {
            s += chars[i] == " " ? " " : glyphs[Int(hash01(i, Int(t * 20)) * Double(glyphs.count)) % glyphs.count]
        }
        return s
    }
}

struct CountdownRing: View {
    let remaining: Double
    let lead: Double
    let t: Double
    let theme: Theme

    var body: some View {
        let live = remaining <= 0
        let frac = live ? 1 : max(0, min(1, remaining / lead))
        let color: Color = live ? .red : (remaining < 30 ? theme.accent : theme.primary)
        let pulse: CGFloat = (live || remaining < 30) ? 1 + 0.035 * CGFloat(sin(t * 8)) : 1
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: 10)
            Circle()
                .trim(from: 0, to: frac)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color, radius: 12)
            Circle()
                .stroke(color.opacity(0.55), style: StrokeStyle(lineWidth: 2, dash: [4, 10]))
                .padding(-24)
                .rotationEffect(.degrees(t * 40))
            Circle()
                .trim(from: 0, to: 0.18)
                .stroke(color.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .padding(-42)
                .rotationEffect(.degrees(-t * 130))
            Circle()
                .trim(from: 0.5, to: 0.58)
                .stroke(color.opacity(0.85), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .padding(-42)
                .rotationEffect(.degrees(-t * 130))
            VStack(spacing: 6) {
                Text(live ? "● LIVE" : "T-MINUS")
                    .font(.mono(16, .bold)).tracking(6)
                    .foregroundColor(color.opacity(live && Int(t * 3) % 2 == 0 ? 0.4 : 0.9))
                Text(format(remaining))
                    .font(.mono(64, .heavy)).monospacedDigit()
                    .foregroundColor(.white)
                    .shadow(color: color, radius: 14)
            }
        }
        .frame(width: 290, height: 290)
        .scaleEffect(pulse)
    }

    private func format(_ r: Double) -> String {
        let s = Int(abs(r))
        let sign = r < 0 ? "+" : ""
        return s >= 3600
            ? String(format: "%@%d:%02d:%02d", sign, s / 3600, s / 60 % 60, s % 60)
            : String(format: "%@%02d:%02d", sign, s / 60, s % 60)
    }
}

struct TerminalLog: View {
    let lines: [String]
    let t: Double
    let theme: Theme

    var body: some View {
        let visible = min(lines.count, Int(max(0, (t - 0.8) / 0.32)))
        VStack(alignment: .leading, spacing: 7) {
            ForEach(0..<visible, id: \.self) { i in styled(lines[i]) }
            if visible == lines.count {
                Text("> awaiting operator input" + (Int(t * 2.4) % 2 == 0 ? "_" : " "))
                    .foregroundColor(theme.accent)
            }
            Spacer(minLength: 0)
        }
        .font(.mono(14))
        .frame(width: 560, height: 250, alignment: .topLeading)
        .padding(20)
        .background(Chamfer(c: 14).fill(Color.black.opacity(0.65)))
        .overlay(Chamfer(c: 14).stroke(theme.primary.opacity(0.6), lineWidth: 1.5))
        .overlay(alignment: .topLeading) {
            Text(" /dev/tty0 ")
                .font(.mono(11, .bold))
                .foregroundColor(.black)
                .background(theme.primary)
                .offset(x: 22, y: -8)
        }
    }

    private func styled(_ s: String) -> Text {
        for (tag, color) in [("[ OK ]", theme.primary), ("[WARN]", Color.yellow), ("[FAIL]", Color.red)] where s.hasPrefix(tag) {
            return Text(tag).foregroundColor(color).bold() + Text(s.dropFirst(tag.count)).foregroundColor(.white.opacity(0.85))
        }
        return Text(s).foregroundColor(theme.accent)
    }
}

struct Chamfer: Shape {
    var c: CGFloat = 12

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + c, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - c))
        p.addLine(to: CGPoint(x: r.maxX - c, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + c))
        p.closeSubpath()
        return p
    }
}

/// L-shaped targeting brackets in each screen corner.
struct CornerBrackets: Shape {
    var len: CGFloat = 40

    func path(in r: CGRect) -> Path {
        var p = Path()
        for (x, y, dx, dy) in [(r.minX, r.minY, 1.0, 1.0), (r.maxX, r.minY, -1.0, 1.0),
                               (r.minX, r.maxY, 1.0, -1.0), (r.maxX, r.maxY, -1.0, -1.0)] {
            p.move(to: CGPoint(x: x + dx * len, y: y))
            p.addLine(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x, y: y + dy * len))
        }
        return p
    }
}

struct NeonButton: View {
    let label: String
    let key: String
    let color: Color
    let filled: Bool
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(key)
                    .font(.mono(11, .bold))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(filled ? Color.black.opacity(0.2) : color.opacity(0.2))
                Text(label).font(.mono(20, .heavy)).tracking(4)
            }
            .padding(.horizontal, 30).padding(.vertical, 15)
            .foregroundColor(filled ? .black : color)
            .background(Chamfer().fill(filled ? color : color.opacity(hover ? 0.18 : 0)))
            .overlay(Chamfer().stroke(color, lineWidth: 2))
            .shadow(color: color.opacity(hover ? 0.95 : 0.45), radius: hover ? 20 : 8)
            .scaleEffect(hover ? 1.06 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hover = h } }
    }
}
