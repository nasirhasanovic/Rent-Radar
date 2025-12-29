import SwiftUI

struct StepDetailsView: View {
    @Bindable var viewModel: AddPropertyViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Step 2 of \(viewModel.totalSteps)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)

                Text("Property Details")
                    .font(AppTypography.heading2)
                    .foregroundStyle(AppColors.textPrimary)

                // Rental Type
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Rental Type")
                        .font(AppTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)

                    HStack(spacing: 12) {
                        RentalTypeCard(
                            emoji: "🏖️",
                            title: "Short-term",
                            subtitle: "Nightly bookings",
                            isSelected: viewModel.propertyType == .shortTerm
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.propertyType = .shortTerm
                            }
                        }

                        RentalTypeCard(
                            emoji: "🏢",
                            title: "Long-term",
                            subtitle: "Monthly tenants",
                            isSelected: viewModel.propertyType == .longTerm
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.propertyType = .longTerm
                            }
                        }
                    }
                }

                // Rate
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(viewModel.propertyType.rateLabel)
                        .font(AppTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)

                    HStack(spacing: 0) {
                        Text(AppSettings.shared.currencySymbol)
                            .font(AppTypography.heading2)
                            .foregroundStyle(AppColors.textPrimary)
                            .padding(.leading, AppSpacing.lg)

                        TextField("185", text: $viewModel.nightlyRate)
                            .font(AppTypography.heading2)
                            .keyboardType(.decimalPad)

                        Spacer()

                        Text(viewModel.propertyType.ratePeriod)
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textTertiary)
                            .padding(.trailing, AppSpacing.lg)
                    }
                    .frame(height: AppSpacing.inputHeight)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }

                // Bedrooms & Bathrooms
                HStack(spacing: 24) {
                    StepperField(
                        label: "Bedrooms",
                        value: viewModel.bedrooms,
                        onIncrement: viewModel.incrementBedrooms,
                        onDecrement: viewModel.decrementBedrooms
                    )

                    StepperField(
                        label: "Bathrooms",
                        value: viewModel.bathrooms,
                        onIncrement: viewModel.incrementBathrooms,
                        onDecrement: viewModel.decrementBathrooms
                    )
                }

                // Max Guests
                StepperField(
                    label: "Max Guests",
                    value: viewModel.maxGuests,
                    displayText: "\(viewModel.maxGuests) guests",
                    onIncrement: viewModel.incrementGuests,
                    onDecrement: viewModel.decrementGuests
                )

                // Info note
                HStack(spacing: 8) {
                    Text("💡")
                        .font(.system(size: 14))
                    Text("You'll select the booking platform (Airbnb, Direct, etc.) when adding bookings.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(12)
                .background(AppColors.teal100.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - Rental Type Card

struct RentalTypeCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Text(emoji)
                        .font(.system(size: 24))
                        .frame(maxWidth: .infinity)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.teal500)
                    }
                }

                Text(title)
                    .font(AppTypography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? AppColors.teal100.opacity(0.3) : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .stroke(isSelected ? AppColors.teal500 : AppColors.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }
}

// MARK: - Stepper Field

struct StepperField: View {
    let label: String
    let value: Int
    var displayText: String? = nil
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(label)
                .font(AppTypography.bodySmall)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)

            HStack {
                Button {
                    withAnimation(.spring(response: 0.2)) { onDecrement() }
                } label: {
                    Text("–")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(width: 36, height: 36)
                }

                Spacer()

                Text(displayText ?? "\(value)")
                    .font(AppTypography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.2)) { onIncrement() }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(AppColors.teal500)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 8)
            .frame(height: AppSpacing.inputHeight)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
}
