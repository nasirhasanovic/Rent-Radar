import SwiftUI

struct PropertySuccessView: View {
    let viewModel: AddPropertyViewModel
    var onGoToDashboard: () -> Void
    var onAddAnother: () -> Void
    var onAddBooking: (() -> Void)?
    var onRecordIncome: (() -> Void)?
    var onViewInsights: (() -> Void)?
    @State private var hasAppeared = false
    @State private var ringExpand = false
    @State private var ring2Expand = false
    @State private var checkBounce = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Success checkmark with animated rings
            ZStack {
                // Outer expanding ring
                Circle()
                    .stroke(AppColors.teal300.opacity(ring2Expand ? 0.0 : 0.3), lineWidth: 2)
                    .frame(width: ring2Expand ? 130 : 56, height: ring2Expand ? 130 : 56)
                    .animation(
                        .easeOut(duration: 1.0).delay(0.3),
                        value: ring2Expand
                    )

                // Inner expanding ring
                Circle()
                    .stroke(AppColors.teal500.opacity(ringExpand ? 0.0 : 0.4), lineWidth: 2.5)
                    .frame(width: ringExpand ? 100 : 56, height: ringExpand ? 100 : 56)
                    .animation(
                        .easeOut(duration: 0.8).delay(0.2),
                        value: ringExpand
                    )

                // Soft glow background
                Circle()
                    .fill(AppColors.teal100.opacity(0.4))
                    .frame(width: 100, height: 100)
                    .scaleEffect(hasAppeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: hasAppeared)

                // Main checkmark circle
                Circle()
                    .fill(AppColors.teal500)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(hasAppeared ? 0 : -30))
                    )
                    .scaleEffect(checkBounce ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.5).delay(0.1),
                        value: checkBounce
                    )
            }
            .onAppear {
                checkBounce = true
                ringExpand = true
                ring2Expand = true
            }

            Spacer().frame(height: 24)

            Text("Property Added!")
                .font(AppTypography.heading1)
                .foregroundStyle(AppColors.textPrimary)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)

            Spacer().frame(height: 8)

            Text("\(viewModel.propertyName) has been added to\nyour property portfolio.")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)

            Spacer().frame(height: 32)

            // Property summary card
            if let property = viewModel.savedProperty {
                HStack(spacing: 12) {
                    // Cover image or illustration
                    if let coverImage = property.coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: property.illustrationGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(property.displayName)
                                .font(AppTypography.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.textPrimary)

                            Text(property.source.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(property.source.tagColor)
                                .clipShape(Capsule())
                        }

                        Text(property.shortAddress)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)

                        Text("\(property.formattedPrice)\(property.type.ratePeriod) · \(property.bedrooms) bed · \(property.bathrooms) bath")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }

                    Spacer()
                }
                .padding(14)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, AppSpacing.screenPadding)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
            }

            Spacer().frame(height: 32)

            // What's Next section
            VStack(spacing: 8) {
                Text("WHAT'S NEXT?")
                    .font(AppTypography.label)
                    .foregroundStyle(AppColors.textTertiary)
                    .textCase(.uppercase)

                HStack(spacing: 24) {
                    NextActionItem(icon: "calendar.badge.plus", title: String(localized: "Add\nBooking"), action: onAddBooking)
                    NextActionItem(icon: "dollarsign.circle", title: String(localized: "Record\nIncome"), action: onRecordIncome)
                    NextActionItem(icon: "chart.bar", title: String(localized: "View\nInsights"), action: onViewInsights)
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                PrimaryButton(title: String(localized: "Go to Dashboard")) {
                    onGoToDashboard()
                }

                SecondaryButton(title: String(localized: "Add Another Property")) {
                    onAddAnother()
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 40)
            .opacity(hasAppeared ? 1 : 0)
        }
        .background(AppColors.surface)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                hasAppeared = true
            }
        }
    }
}

private struct NextActionItem: View {
    let icon: String
    let title: String
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.teal500)
                    .frame(width: 44, height: 44)
                    .background(AppColors.teal100.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
