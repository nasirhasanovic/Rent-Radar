import SwiftUI

struct PlatformInstructionsView: View {
    @Bindable var viewModel: ConnectPlatformViewModel
    @State private var animatedSteps: Set<Int> = []

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Step indicator
                    StepIndicator(currentStep: viewModel.currentStep)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    // Title
                    titleSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // Instruction cards
                    instructionCards
                        .padding(.horizontal, 20)

                    // URL hint
                    urlHintCard
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    Spacer(minLength: 120)
                }
            }

            // Continue button
            continueButton
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [AppColors.background.opacity(0), AppColors.background],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .allowsHitTesting(false)
                )
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Copy your calendar link")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text("Follow these steps in your \(viewModel.selectedPlatform.rawValue) app or browser")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Instruction Cards

    private var instructionCards: some View {
        VStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                if index < viewModel.selectedPlatform.instructions.count {
                    instructionCard(at: index)
                }
            }
        }
    }

    @ViewBuilder
    private func instructionCard(at index: Int) -> some View {
        let instructions = viewModel.selectedPlatform.instructions
        let instruction = instructions[index]
        let isLast = index == instructions.count - 1

        InstructionCard(
            step: instruction.step,
            title: instruction.title,
            description: instruction.description,
            isHighlighted: isLast,
            platformColor: viewModel.selectedPlatform.color,
            platformTint: viewModel.selectedPlatform.tintedBackground,
            isAnimated: animatedSteps.contains(instruction.step)
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1)) {
                _ = animatedSteps.insert(instruction.step)
            }
        }
    }

    // MARK: - URL Hint Card

    private var urlHintCard: some View {
        HStack(spacing: 10) {
            Text("\u{1F4A1}")
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text("The link looks like:")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)

                Text(viewModel.urlHint)
                    .font(.system(size: 11, weight: .medium).monospaced())
                    .foregroundStyle(AppColors.teal500)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            viewModel.nextStep()
        } label: {
            HStack(spacing: 8) {
                Text("I've Copied the Link")
                    .font(.system(size: 15, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppColors.teal600, Color(hex: "0D7C6E")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: AppColors.teal600.opacity(0.3), radius: 12, y: 4)
        }
    }
}

// MARK: - Instruction Card

private struct InstructionCard: View {
    let step: Int
    let title: String
    let description: String
    let isHighlighted: Bool
    let platformColor: Color
    let platformTint: Color
    var isAnimated: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHighlighted ? AppColors.teal500 : platformTint)
                    .frame(width: 32, height: 32)

                Text("\(step)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isHighlighted ? .white : platformColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isHighlighted ? AppColors.teal600 : AppColors.textPrimary)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(16)
        .background(isHighlighted ? AppColors.tintedTeal : AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isHighlighted ? AppColors.teal500 : AppColors.border, lineWidth: isHighlighted ? 1.5 : 1)
        )
        .scaleEffect(isAnimated ? 1 : 0.95)
        .opacity(isAnimated ? 1 : 0)
    }
}
