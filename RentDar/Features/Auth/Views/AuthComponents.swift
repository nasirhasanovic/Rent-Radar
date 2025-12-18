import SwiftUI

// MARK: - Password Field

struct AuthPasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        HStack {
            if isVisible {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textPrimary)
            } else {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Button {
                isVisible.toggle()
            } label: {
                Text(isVisible ? "\u{1F441}\u{FE0F}" : "\u{1F576}\u{FE0F}")
                    .font(.system(size: 18))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.border, lineWidth: 2)
        )
    }
}

// MARK: - Password Strength Bar

struct PasswordStrengthBar: View {
    let strength: Int // 0-4
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(index < strength ? color : AppColors.border)
                        .frame(height: 4)
                }
            }
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
                if strength == 4 {
                    Text("\u{1F4AA}")
                        .font(.system(size: 12))
                }
            }
        }
    }
}

// MARK: - Password Requirement Row

struct PasswordRequirementRow: View {
    let met: Bool
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(met ? "\u{2713}" : "\u{2022}")
                .font(.system(size: met ? 8 : 10, weight: .bold))
                .foregroundStyle(met ? Color(hex: "10B981") : AppColors.textTertiary)
                .frame(width: 16, height: 16)
                .background(met ? Color(hex: "D1FAE5") : AppColors.border)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(met ? Color(hex: "10B981") : AppColors.textTertiary)

            Spacer()
        }
        .animation(.easeInOut(duration: 0.2), value: met)
    }
}

// MARK: - Password Requirements Box

struct PasswordRequirementsBox: View {
    let hasMinLength: Bool
    let hasUppercase: Bool
    let hasNumber: Bool
    let hasSpecialChar: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REQUIREMENTS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
                .kerning(0.5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                PasswordRequirementRow(met: hasMinLength, text: "8+ characters")
                PasswordRequirementRow(met: hasUppercase, text: "Uppercase")
                PasswordRequirementRow(met: hasNumber, text: "Number")
                PasswordRequirementRow(met: hasSpecialChar, text: "Special char")
            }
        }
        .padding(14)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
