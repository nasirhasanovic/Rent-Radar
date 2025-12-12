import SwiftUI

struct SecondaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.body)
                .fontWeight(.medium)
                .foregroundStyle(isDisabled ? AppColors.textTertiary : AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppSpacing.buttonHeight)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                        .stroke(isDisabled ? AppColors.border : AppColors.border, lineWidth: 1.5)
                )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "I already have an account") {}
        SecondaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
}
