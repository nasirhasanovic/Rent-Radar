import SwiftUI
import CoreData

struct ConnectPlatformView: View {
    let property: PropertyEntity
    let platform: PlatformType
    let onDismiss: () -> Void

    @State private var viewModel: ConnectPlatformViewModel
    private let settings = AppSettings.shared

    init(property: PropertyEntity, platform: PlatformType, onDismiss: @escaping () -> Void) {
        self.property = property
        self.platform = platform
        self.onDismiss = onDismiss

        let context = property.managedObjectContext ?? PersistenceController.shared.container.viewContext
        let vm = ConnectPlatformViewModel(property: property, context: context)
        vm.selectedPlatform = platform
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Group {
                switch viewModel.currentStep {
                case .instructions:
                    PlatformInstructionsView(viewModel: viewModel)
                case .pasteURL:
                    PlatformPasteURLView(viewModel: viewModel)
                case .syncing:
                    PlatformSyncingView(viewModel: viewModel)
                case .success:
                    PlatformSuccessView(viewModel: viewModel, onDismiss: onDismiss)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Button {
                    if viewModel.currentStep == .instructions {
                        onDismiss()
                    } else if viewModel.currentStep != .syncing && viewModel.currentStep != .success {
                        viewModel.previousStep()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .opacity(viewModel.currentStep == .syncing ? 0.5 : 1)
                .disabled(viewModel.currentStep == .syncing)

                VStack(alignment: .leading, spacing: 2) {
                    Text(headerTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text(property.displayName)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // Platform icon
                if viewModel.currentStep != .success {
                    platformIcon(viewModel.selectedPlatform)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var headerTitle: String {
        switch viewModel.currentStep {
        case .instructions, .pasteURL:
            return "Connect \(viewModel.selectedPlatform.rawValue)"
        case .syncing:
            return "Syncing Calendar"
        case .success:
            return "Sync Complete"
        }
    }

    @ViewBuilder
    private func platformIcon(_ platform: PlatformType) -> some View {
        switch platform {
        case .airbnb:
            Image("airbnb_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        case .booking:
            Image("booking_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        case .vrbo:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(platform.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text("V")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
            }
        case .direct:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(platform.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "house.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let currentStep: ConnectPlatformStep
    let totalSteps: Int = 3

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                let isComplete = step < currentStep.rawValue
                let isCurrent = step == currentStep.rawValue

                // Circle
                ZStack {
                    Circle()
                        .fill(isComplete ? Color(hex: "2DD4A8") : (isCurrent ? AppColors.teal500 : Color(hex: "E5E7EB")))
                        .frame(width: 28, height: 28)

                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(step)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(isCurrent ? .white : Color(hex: "9CA3AF"))
                    }
                }
                .scaleEffect(isCurrent ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)

                // Connector line (not after last)
                if step < totalSteps {
                    GeometryReader { geo in
                        let progress: CGFloat = isComplete ? 1.0 : (isCurrent ? 0.5 : 0.0)

                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(hex: "E5E7EB"))
                                .frame(height: 2)

                            Rectangle()
                                .fill(Color(hex: "2DD4A8"))
                                .frame(width: geo.size.width * progress, height: 2)
                                .animation(.easeInOut(duration: 0.4), value: currentStep)
                        }
                    }
                    .frame(height: 2)
                }
            }
        }
    }
}
