import SwiftUI

struct CurrencySettingsView: View {
    var settings = AppSettings.shared
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("POPULAR CURRENCIES")
                        .font(AppTypography.label)
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    VStack(spacing: 0) {
                        ForEach(Array(AppSettings.currencies.enumerated()), id: \.element.code) { index, currency in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    settings.currencyCode = currency.code
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    Text(currency.flag)
                                        .font(.system(size: 28))
                                        .frame(width: 40, height: 40)
                                        .background(AppColors.background)
                                        .cornerRadius(12)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(currency.name)
                                            .font(AppTypography.body)
                                            .foregroundStyle(AppColors.textPrimary)
                                        Text(currency.display)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppColors.textTertiary)
                                    }

                                    Spacer()

                                    if settings.currencyCode == currency.code {
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

                            if index < AppSettings.currencies.count - 1 {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, AppSpacing.screenPadding)

                    TipBar(text: "Currency affects how prices are displayed throughout the app. Actual transactions use your property's local currency.")
                        .padding(.horizontal, AppSpacing.screenPadding)
                        .padding(.top, 16)
                }
                .padding(.bottom, 40)
            }
        }
        .background(AppColors.surface)
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

            Text("Currency")
                .font(AppTypography.heading2)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
        .background(AppColors.elevated)
    }
}
