import SwiftUI

struct AppTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @State private var isPasswordVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(label)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.textPrimary)

            HStack {
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                }

                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Text(isPasswordVisible ? "Hide" : "Show")
                            .font(AppTypography.bodySmall)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            .font(AppTypography.body)
            .padding(.horizontal, AppSpacing.lg)
            .frame(height: AppSpacing.inputHeight)
            .background(isFocused ? AppColors.surface : AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadius)
                    .stroke(
                        isFocused ? AppColors.primary : AppColors.border,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppTextField(label: "Email", placeholder: "john@example.com", text: .constant(""))
        AppTextField(label: "Password", placeholder: "••••••••", text: .constant(""), isSecure: true)
    }
    .padding()
}
