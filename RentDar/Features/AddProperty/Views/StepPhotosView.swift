import SwiftUI
import PhotosUI

struct StepPhotosView: View {
    @Bindable var viewModel: AddPropertyViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Step indicator
                Text("Step 3 of \(viewModel.totalSteps)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)

                Text("Add Photos")
                    .font(AppTypography.heading2)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Add a cover photo to make your property stand out.")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textTertiary)

                // Upload area / Image preview
                if let image = viewModel.selectedImage {
                    // Show selected image
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))

                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedImage = nil
                                viewModel.selectedPhotoItem = nil
                                viewModel.selectedIllustrationIndex = 0
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }

                    // Replace photo button
                    PhotosPicker(
                        selection: $viewModel.selectedPhotoItem,
                        matching: .images
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 14))
                            Text("Replace Photo")
                                .font(AppTypography.bodySmall)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(AppColors.teal500)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(AppColors.teal100.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                    }
                } else {
                    // Upload area
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(AppColors.textTertiary)

                        Text("Upload cover photo")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textTertiary)

                        Text("JPG, PNG up to 10MB")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)

                        PhotosPicker(
                            selection: $viewModel.selectedPhotoItem,
                            matching: .images
                        ) {
                            Text("Choose File")
                                .font(AppTypography.body)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.textPrimary)
                                .frame(width: 140, height: AppSpacing.buttonHeight)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                                        .stroke(AppColors.border, lineWidth: 1.5)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                            .stroke(AppColors.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }

                // Or pick an illustration
                VStack(alignment: .leading, spacing: 12) {
                    Text("Or pick an illustration")
                        .font(AppTypography.bodySmall)
                        .foregroundStyle(AppColors.textTertiary)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(PropertyIllustration.presets) { preset in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: preset.colors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            viewModel.selectedIllustrationIndex == preset.id
                                                ? AppColors.surface
                                                : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            viewModel.selectedIllustrationIndex == preset.id
                                                ? AppColors.teal500
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                        .padding(-1)
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.2)) {
                                        viewModel.selectedIllustrationIndex = preset.id
                                        viewModel.selectedImage = nil
                                        viewModel.selectedPhotoItem = nil
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 24)
        }
    }
}
