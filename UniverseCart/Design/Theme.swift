import SwiftUI

extension Color {
    init(hex: String) {
        let s = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var v: UInt64 = 0
        s.scanHexInt64(&v)
        self.init(
            .sRGB,
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum UCColor {
    // Neutral scale (29CM ruler scale)
    static let gray0 = Color(hex: "FFFFFF")
    static let gray100 = Color(hex: "F4F4F4")
    static let gray200 = Color(hex: "E4E4E4")
    static let gray300 = Color(hex: "C4C4C4")
    static let gray400 = Color(hex: "A0A0A0")
    static let gray500 = Color(hex: "5D5D5D")
    static let gray700 = Color(hex: "303030")
    static let gray900 = Color(hex: "19191A")
    static let gray950 = Color(hex: "000000")

    // Accent — use sparingly
    static let accent = Color(hex: "FF4800")
    static let accentSoft = Color(hex: "FFEFEB")
    static let accentDeep = Color(hex: "D53F00")

    // Semantic roles
    static let bg = gray0
    static let surface = gray100
    static let border = gray200
    static let textPrimary = gray900
    static let textSecond = gray500
    static let textDisabled = gray400

    static func mallColor(_ mall: Mall) -> Color {
        switch mall {
        case .cm29: return gray900
        case .musinsa: return Color(hex: "2962FF")
        case .wconcept: return Color(hex: "D81B60")
        case .naver: return Color(hex: "03C75A")
        case .etc: return gray400
        }
    }
}

enum UCLayout {
    static let gnbHeight: CGFloat = 50
    static let tabBarHeight: CGFloat = 52
}
