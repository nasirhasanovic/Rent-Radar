import SwiftUI

enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case auto = "Auto"

    var subtitle: String {
        switch self {
        case .light: return String(localized: "Always light")
        case .dark: return String(localized: "Always dark")
        case .auto: return String(localized: "Match system")
        }
    }

    var assetName: String {
        switch self {
        case .light: return "theme_light"
        case .dark: return "theme_dark"
        case .auto: return "theme_auto"
        }
    }
}

struct AppearanceSettingsView: View {
    var settings = AppSettings.shared
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // CHOOSE THEME
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CHOOSE THEME")
                            .font(AppTypography.label)
                            .foregroundStyle(AppColors.textTertiary)

                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                                ThemeCard(
                                    theme: theme,
                                    isSelected: settings.theme == theme
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        settings.theme = theme
                                    }
                                }
                            }
                        }
                    }

                    TipBar(text: "Auto mode will switch between light and dark themes based on your device's system settings.")

                    // PREVIEW
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PREVIEW")
                            .font(AppTypography.label)
                            .foregroundStyle(AppColors.textTertiary)

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.teal500, AppColors.teal300],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Beach Studio")
                                        .font(AppTypography.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppColors.textPrimary)
                                    Text("Miami Beach, FL")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.textTertiary)
                                }

                                Spacer()
                            }

                            HStack(spacing: 12) {
                                PreviewStat(value: "\(settings.currencySymbol)185", label: "per night")
                                PreviewStat(value: "12", label: "bookings")
                            }
                        }
                        .padding(16)
                        .background(AppColors.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(AppColors.background)
    }

    private var navBar: some View {
        HStack(spacing: 14) {
            Button { onDismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text("Appearance")
                .font(AppTypography.heading2)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
        .background(AppColors.elevated)
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(theme.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Text(theme.rawValue)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)

                Text(theme.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.teal500)
                } else {
                    Color.clear.frame(height: 20)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppColors.teal500 : AppColors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Preview Stat

private struct PreviewStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.textPrimary)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
