import SwiftUI

struct LanguageSettingsView: View {
    var settings = AppSettings.shared
    var onDismiss: () -> Void
    @State private var searchText = ""

    private var filteredLanguages: [AppSettings.LanguageInfo] {
        if searchText.isEmpty { return AppSettings.languages }
        return AppSettings.languages.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundStyle(AppColors.textTertiary)

                        TextField("Search languages...", text: $searchText)
                            .font(AppTypography.body)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                    Text("AVAILABLE LANGUAGES")
                        .font(AppTypography.label)
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.bottom, 8)

                    VStack(spacing: 0) {
                        ForEach(Array(filteredLanguages.enumerated()), id: \.element.code) { index, lang in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    settings.languageCode = lang.code
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Text(lang.flag)
                                        .font(.system(size: 28))
                                        .frame(width: 40, height: 40)
                                        .background(AppColors.background)
                                        .cornerRadius(12)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(lang.name)
                                            .font(AppTypography.body)
                                            .foregroundStyle(AppColors.textPrimary)
                                        Text(lang.subtitle)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppColors.textTertiary)
                                    }

                                    Spacer()

                                    if settings.languageCode == lang.code {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(AppColors.teal500)
                                    } else {
                                        Circle()
                                            .stroke(AppColors.border, lineWidth: 1.5)
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(minHeight: 60)
                            }

                            if index < filteredLanguages.count - 1 {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, AppSpacing.screenPadding)
                }
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
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

            Text("Language")
                .font(AppTypography.heading2)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
        .background(AppColors.elevated)
    }
}
