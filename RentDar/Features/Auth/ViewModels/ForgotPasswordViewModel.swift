import SwiftUI

enum ForgotPasswordStep: Int, CaseIterable {
    case enterEmail = 1
    case verifyCode = 2
    case newPassword = 3
    case success = 4

    var title: String {
        switch self {
        case .enterEmail: return "Email"
        case .verifyCode: return "Verification"
        case .newPassword: return "Security"
        case .success: return "Complete"
        }
    }
}

@Observable
final class ForgotPasswordViewModel {
    var currentStep: ForgotPasswordStep = .enterEmail
    var email = ""
    var verificationCode: [String] = Array(repeating: "", count: 4)
    var newPassword = ""
    var confirmPassword = ""
    var isPasswordVisible = false
    var isConfirmPasswordVisible = false
    var isLoading = false
    var resendTimer = 60

    private var timer: Timer?

    // MARK: - Validation

    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    var isCodeComplete: Bool {
        verificationCode.allSatisfy { !$0.isEmpty }
    }

    var codeString: String {
        verificationCode.joined()
    }

    // Password requirements
    var hasMinLength: Bool { newPassword.count >= 8 }
    var hasUppercase: Bool { newPassword.range(of: "[A-Z]", options: .regularExpression) != nil }
    var hasNumber: Bool { newPassword.range(of: "[0-9]", options: .regularExpression) != nil }
    var hasSpecialChar: Bool { newPassword.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil }

    var passwordStrengthLevel: Int {
        var score = 0
        if hasMinLength { score += 1 }
        if hasUppercase { score += 1 }
        if hasNumber { score += 1 }
        if hasSpecialChar { score += 1 }
        return score
    }

    var passwordStrength: String {
        switch passwordStrengthLevel {
        case 0: return ""
        case 1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong password"
        default: return ""
        }
    }

    var passwordStrengthColor: Color {
        switch passwordStrengthLevel {
        case 1: return AppColors.expense
        case 2: return Color(hex: "F59E0B")
        case 3: return Color(hex: "F59E0B")
        case 4: return Color(hex: "10B981")
        default: return AppColors.border
        }
    }

    var passwordsMatch: Bool {
        !confirmPassword.isEmpty && newPassword == confirmPassword
    }

    var canResetPassword: Bool {
        hasMinLength && hasUppercase && hasNumber && passwordsMatch
    }

    var timerFormatted: String {
        String(format: "0:%02d", resendTimer)
    }

    // MARK: - Actions

    func sendResetCode(onComplete: @escaping () -> Void) {
        guard isEmailValid else { return }
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isLoading = false
            self?.currentStep = .verifyCode
            self?.startResendTimer()
            onComplete()
        }
    }

    func verifyCode(onComplete: @escaping () -> Void) {
        guard isCodeComplete else { return }
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            self?.currentStep = .newPassword
            onComplete()
        }
    }

    func resetPassword(onComplete: @escaping () -> Void) {
        guard canResetPassword else { return }
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isLoading = false
            self?.currentStep = .success
            onComplete()
        }
    }

    func resendCode() {
        guard resendTimer == 0 else { return }
        startResendTimer()
    }

    private func startResendTimer() {
        resendTimer = 60
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.resendTimer > 0 {
                self.resendTimer -= 1
            } else {
                self.timer?.invalidate()
            }
        }
    }

    func goBack() {
        switch currentStep {
        case .enterEmail:
            break
        case .verifyCode:
            currentStep = .enterEmail
        case .newPassword:
            currentStep = .verifyCode
        case .success:
            break
        }
    }

    deinit {
        timer?.invalidate()
    }
}
