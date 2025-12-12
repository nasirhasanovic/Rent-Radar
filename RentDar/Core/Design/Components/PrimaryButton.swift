import SwiftUI

// MARK: - Pressable Button Style

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Primary Button

struct PrimaryButton: View {
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
                            AppColors.teal300
                        } else {
                            LinearGradient(
                                colors: [Color(hex: "2DD4BF"), AppColors.teal600],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                .shadow(
                    color: isDisabled ? .clear : AppColors.teal500.opacity(0.35),
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
        PrimaryButton(title: "Sign In") {}
        PrimaryButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
}
