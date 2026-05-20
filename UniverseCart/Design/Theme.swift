import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)

        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

enum UCTheme {
    static let background = Color(hex: "#FFFFFF")
    static let surface = Color(hex: "#F7F6F3")
    static let textPrimary = Color(hex: "#111111")
    static let textSecondary = Color(hex: "#6B6B6B")
    static let textLight = Color(hex: "#B8B5AE")
    static let border = Color(hex: "#E4E2DC")

    static func mallColor(_ mall: Mall) -> Color {
        switch mall {
        case .cm29: return Color(hex: "#1A1A1A")
        case .musinsa: return Color(hex: "#2962FF")
        case .wconcept: return Color(hex: "#D81B60")
        case .naver: return Color(hex: "#03C75A")
        case .etc: return UCTheme.textLight
        }
    }
}
