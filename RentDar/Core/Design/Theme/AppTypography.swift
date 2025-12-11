import SwiftUI

enum AppTypography {
    // Display / 42px / Bold
    static let display = Font.system(size: 42, weight: .bold)

    // Heading 1 / 28px / Semibold
    static let heading1 = Font.system(size: 28, weight: .semibold)

    // Heading 2 / 22px / Bold
    static let heading2 = Font.system(size: 22, weight: .bold)

    // Heading 3 / 18px / Semibold
    static let heading3 = Font.system(size: 18, weight: .semibold)

    // Body / 16px / Regular
    static let body = Font.system(size: 16, weight: .regular)

    // Body Small / 14px / Regular
    static let bodySmall = Font.system(size: 14, weight: .regular)

    // Caption / 12px / Medium
    static let caption = Font.system(size: 12, weight: .medium)

    // Label / 13px / Semibold / Uppercase
    static let label = Font.system(size: 13, weight: .semibold)
}
