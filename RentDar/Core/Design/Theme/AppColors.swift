import SwiftUI

enum AppColors {
    // MARK: - Adaptive Helper

    private static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)
            return UIColor(
                red: CGFloat((int >> 16) & 0xFF) / 255,
                green: CGFloat((int >> 8) & 0xFF) / 255,
                blue: CGFloat(int & 0xFF) / 255,
                alpha: 1
            )
        })
    }

    // MARK: - Primary (constant)
    static let teal600 = Color(hex: "0D9488")
    static let teal500 = Color(hex: "14B8A6")
    static let teal300 = Color(hex: "5EEAD4")
    static let teal100 = adaptive(light: "CCFBF1", dark: "134E4A")

    // MARK: - Semantic
    static let success = adaptive(light: "059669", dark: "22C55E")
    static let error = Color(hex: "EF4444")
    static let warning = Color(hex: "F59E0B")
    static let info = Color(hex: "3B82F6")

    // MARK: - Raw Neutrals (non-adaptive)
    static let slate900 = Color(hex: "0F172A")
    static let slate600 = Color(hex: "475569")
    static let slate500 = Color(hex: "64748B")
    static let slate200 = Color(hex: "E2E8F0")
    static let slate50 = Color(hex: "F8FAFC")

    // MARK: - Adaptive Semantic Colors
    static let primary = teal500
    static let primaryDark = teal600
    static let background = adaptive(light: "F1F5F9", dark: "0F172A")
    static let surface = adaptive(light: "F8FAFC", dark: "1E293B")
    static let elevated = adaptive(light: "FFFFFF", dark: "283548")
    static let border = adaptive(light: "E2E8F0", dark: "334155")
    static let textPrimary = adaptive(light: "0F172A", dark: "F1F5F9")
    static let textSecondary = adaptive(light: "475569", dark: "94A3B8")
    static let textTertiary = adaptive(light: "64748B", dark: "64748B")

    // MARK: - Tinted Backgrounds (adaptive)
    static let tintedRed = adaptive(light: "FEE2E2", dark: "3C2024")
    static let tintedBlue = adaptive(light: "DBEAFE", dark: "1E2C48")
    static let tintedLightBlue = adaptive(light: "EFF6FF", dark: "1A2540")
    static let tintedYellow = adaptive(light: "FEF3C7", dark: "362D1A")
    static let tintedTeal = adaptive(light: "CCFBF1", dark: "163432")
    static let tintedOrange = adaptive(light: "FED7AA", dark: "3A261A")
    static let tintedGreen = adaptive(light: "D1FAE5", dark: "1A3326")
    static let tintedGray = adaptive(light: "E2E8F0", dark: "2D3441")
    static let tintedPurple = adaptive(light: "EDE9FE", dark: "2D2248")

    // MARK: - Aliases
    static let expense = error
    static let income = success
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
