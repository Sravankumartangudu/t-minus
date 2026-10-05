import SwiftUI

enum Theme: String, CaseIterable {
    case matrix, synthwave, amber, ice

    var label: String {
        switch self {
        case .matrix: return "Matrix (green rain)"
        case .synthwave: return "Synthwave (pink/cyan)"
        case .amber: return "Amber CRT (hex dump)"
        case .ice: return "ICE (binary blue)"
        }
    }

    var primary: Color {
        switch self {
        case .matrix: return Color(red: 0.0, green: 1.0, blue: 0.45)
        case .synthwave: return Color(red: 1.0, green: 0.2, blue: 0.8)
        case .amber: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .ice: return Color(red: 0.3, green: 0.8, blue: 1.0)
        }
    }

    var accent: Color {
        switch self {
        case .matrix: return Color(red: 0.75, green: 1.0, blue: 0.85)
        case .synthwave: return Color(red: 0.2, green: 0.95, blue: 1.0)
        case .amber: return Color(red: 1.0, green: 0.4, blue: 0.1)
        case .ice: return Color(red: 0.85, green: 0.95, blue: 1.0)
        }
    }

    var glyphs: [String] {
        switch self {
        case .matrix: return "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789".map(String.init)
        case .synthwave: return "▲△◆◇○●□■▼▽◢◣◤◥01".map(String.init)
        case .amber: return "0123456789ABCDEF".map(String.init)
        case .ice: return "01".map(String.init)
        }
    }
}

/// Deterministic pseudo-random in [0, 1) — lets animations be pure functions of time.
func hash01(_ a: Int, _ b: Int) -> Double {
    var h = UInt64(truncatingIfNeeded: a) &* 0x9E37_79B9_7F4A_7C15
    h ^= UInt64(truncatingIfNeeded: b) &* 0xC2B2_AE3D_27D4_EB4F
    h ^= h >> 31
    h = h &* 0xBF58_476D_1CE4_E5B9
    h ^= h >> 29
    return Double(h >> 11) / Double(1 << 53)
}

extension Font {
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}
