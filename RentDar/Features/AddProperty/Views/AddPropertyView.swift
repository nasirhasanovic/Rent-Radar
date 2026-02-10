import SwiftUI
import CoreData

struct AddPropertyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var viewModel = AddPropertyViewModel()
    var onDismiss: () -> Void
    var onComplete: () -> Void
    var onAddBooking: ((PropertyEntity?) -> Void)?
    var onRecordIncome: ((PropertyEntity?) -> Void)?
    var onViewInsights: (() -> Void)?

    var body: some View {
        if viewModel.isCompleted {
            PropertySuccessView(
                viewModel: viewModel,
                onGoToDashboard: onComplete,
                onAddAnother: {
                    viewModel.reset()
                },
                onAddBooking: {
                    onAddBooking?(viewModel.savedProperty)
                },
                onRecordIncome: {
                    onRecordIncome?(viewModel.savedProperty)
                },
                onViewInsights: onViewInsights
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .opacity
            ))
        } else {
            VStack(spacing: 0) {
                // Navigation bar
                navBar

                // Step progress bar
                StepProgressBar(
                    currentStep: viewModel.currentStep,
                    totalSteps: viewModel.totalSteps
                )
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, 4)

                // Step content
                Group {
                    switch viewModel.currentStep {
                    case 1:
                        StepBasicInfoView(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    case 2:
                        StepDetailsView(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    case 3:
                        StepPhotosView(viewModel: viewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    default:
                        EmptyView()
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.currentStep)

                Spacer()

                // Continue button
                PrimaryButton(
                    title: viewModel.currentStep == viewModel.totalSteps ? String(localized: "Add Property") : String(localized: "Continue"),
                    isDisabled: !isCurrentStepValid
                ) {
                    if viewModel.currentStep == viewModel.totalSteps {
                        viewModel.saveProperty(context: viewContext)
                    } else {
                        viewModel.nextStep()
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.bottom, 40)
            }
            .background(AppColors.surface)
        }
    }

    private var isCurrentStepValid: Bool {
        switch viewModel.currentStep {
        case 1: return viewModel.isStep1Valid
        case 2: return viewModel.isStep2Valid
        case 3: return true
        default: return false
        }
    }

    private var navBar: some View {
        HStack {
            Button {
                if viewModel.currentStep > 1 {
                    viewModel.previousStep()
                } else {
                    onDismiss()
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            Button("Cancel") {
                onDismiss()
            }
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.vertical, 12)
    }
}

#Preview {
    AddPropertyView(onDismiss: {}, onComplete: {})
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
