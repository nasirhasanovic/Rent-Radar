import SwiftUI

struct DangerButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.body)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppSpacing.buttonHeight)
                .background(
                    Group {
                        if isDisabled {
                            AppColors.error.opacity(0.5)
                        } else {
                            LinearGradient(
                                colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                .shadow(
                    color: isDisabled ? .clear : AppColors.error.opacity(0.35),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isDisabled)
    }
}

#Preview {
    VStack(spacing: 16) {
        DangerButton(title: "Yes, Delete Property") {}
        DangerButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
}
