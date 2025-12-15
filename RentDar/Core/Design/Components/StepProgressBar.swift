import SwiftUI

struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? AppColors.teal500 : AppColors.border)
                    .frame(height: 4)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StepProgressBar(currentStep: 1, totalSteps: 3)
        StepProgressBar(currentStep: 2, totalSteps: 3)
        StepProgressBar(currentStep: 3, totalSteps: 3)
    }
    .padding()
}
