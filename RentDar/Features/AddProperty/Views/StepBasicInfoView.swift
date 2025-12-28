import SwiftUI

struct StepBasicInfoView: View {
    @Bindable var viewModel: AddPropertyViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Step 1 of \(viewModel.totalSteps)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)

                Text("Basic Information")
                    .font(AppTypography.heading2)
                    .foregroundStyle(AppColors.textPrimary)

                AppTextField(
                    label: "Property Name",
                    placeholder: "Beach Studio",
                    text: $viewModel.propertyName
                )

                AppTextField(
                    label: "Address",
                    placeholder: "Enter property address",
                    text: $viewModel.address
                )

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("City")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textPrimary)

                        TextField("City", text: $viewModel.city)
                            .font(AppTypography.body)
                            .padding(.horizontal, AppSpacing.lg)
                            .frame(height: AppSpacing.inputHeight)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("State")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textPrimary)

                        TextField("Select", text: $viewModel.state)
                            .font(AppTypography.body)
                            .padding(.horizontal, AppSpacing.lg)
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
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 24)
        }
    }
}
