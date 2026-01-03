import SwiftUI
import CoreData
import PhotosUI

struct EditPropertyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var viewModel: EditPropertyViewModel
    @State private var showIllustrationPicker = false

    var onDismiss: () -> Void
    var onSave: () -> Void

    init(property: PropertyEntity, onDismiss: @escaping () -> Void, onSave: @escaping () -> Void) {
        _viewModel = State(initialValue: EditPropertyViewModel(property: property))
        self.onDismiss = onDismiss
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            navBar

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    illustrationSection

                    AppTextField(
                        label: "Property Name",
                        placeholder: "Beach Studio",
                        text: $viewModel.propertyName
                    )

                    // Address (combined city, state)
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Address")
                            .font(AppTypography.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.textPrimary)

                        TextField("Miami Beach, FL", text: $viewModel.address)
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

                    rentalTypeSection
                    nightlyRateSection

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

                    StepperField(
                        label: "Max Guests",
                        value: viewModel.maxGuests,
                        displayText: "\(viewModel.maxGuests) guests",
                        onIncrement: viewModel.incrementGuests,
                        onDecrement: viewModel.decrementGuests
                    )
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            PrimaryButton(
                title: "Save Changes",
                isDisabled: !viewModel.isFormValid
            ) {
                viewModel.saveChanges(context: viewContext)
                onSave()
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 40)
        }
        .background(AppColors.surface)
    }

    // MARK: - Navigation Bar

    private var navBar: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            Text("Edit Property")
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button("Save") {
                viewModel.saveChanges(context: viewContext)
                onSave()
            }
            .font(AppTypography.body)
            .fontWeight(.semibold)
            .foregroundStyle(viewModel.isFormValid ? AppColors.teal500 : AppColors.textTertiary)
            .disabled(!viewModel.isFormValid)
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
    }

    // MARK: - Illustration

    private var illustrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if let coverImage = viewModel.selectedImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    LinearGradient(
                        colors: illustrationColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                HStack(spacing: 8) {
                    if viewModel.hasCoverImage {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.removeImage()
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showIllustrationPicker.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.system(size: 12, weight: .medium))
                            Text("Change")
                                .font(AppTypography.caption)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
                .padding(12)
            }

            if showIllustrationPicker {
                // Photo picker
                PhotosPicker(
                    selection: $viewModel.selectedPhotoItem,
                    matching: .images
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 14))
                        Text("Choose from Library")
                            .font(AppTypography.bodySmall)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppColors.teal500)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppColors.teal100.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSmall))
                }

                // Illustration grid
                Text("Or pick an illustration")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textTertiary)

                IllustrationPickerView(selectedIndex: Binding(
                    get: { viewModel.selectedIllustrationIndex },
                    set: { newValue in
                        viewModel.selectedIllustrationIndex = newValue
                        viewModel.selectedImage = nil
                        viewModel.selectedPhotoItem = nil
                    }
                ))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var illustrationColors: [Color] {
        if let idx = viewModel.selectedIllustrationIndex,
           idx >= 0 && idx < PropertyIllustration.presets.count {
            return PropertyIllustration.presets[idx].colors
        }
        return [AppColors.teal100, AppColors.teal300.opacity(0.3)]
    }

    // MARK: - Rental Type

    private var rentalTypeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Rental Type")
                .font(AppTypography.bodySmall)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: 12) {
                RentalTypeCard(
                    emoji: "\u{1F3D6}\u{FE0F}",
                    title: "Short-term",
                    subtitle: "Nightly bookings",
                    isSelected: viewModel.propertyType == .shortTerm
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.propertyType = .shortTerm
                    }
                }

                RentalTypeCard(
                    emoji: "\u{1F3E2}",
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
    }

    // MARK: - Rate

    private var nightlyRateSection: some View {
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
    }
}
