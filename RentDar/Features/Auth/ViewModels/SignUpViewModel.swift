import SwiftUI
import Combine

enum SignUpPhase: Equatable {
    case registration
    case verification
    case success
}

@Observable
final class SignUpViewModel {
    var phase: SignUpPhase = .registration
    var currentStep: Int = 1
    let totalSteps: Int = 4

    // Step 1 — Account
    var email: String = ""

    // Step 2 — Personal Info
    var firstName: String = ""
    var lastName: String = ""
    var countryCode: String = "+1"
    var phoneNumber: String = ""

    // Step 3 — Security
    var password: String = ""
    var confirmPassword: String = ""
    var isPasswordVisible: Bool = false
    var isConfirmPasswordVisible: Bool = false

    // Step 4 — Properties
    var selectedPropertyType: RentalManagementType = .shortTerm
    var propertyCount: Int = 1

    // Verification
    var verificationCode: [String] = Array(repeating: "", count: 6)
    var timerSeconds: Int = 300
    var isVerifying: Bool = false
    private var timerCancellable: AnyCancellable?

    var isLoading: Bool = false

    // MARK: - Navigation

    var progressPercent: Double {
        Double(currentStep) / Double(totalSteps)
    }

    var stepLabel: String {
        switch currentStep {
        case 1: return String(localized: "Account")
        case 2: return String(localized: "Personal Info")
        case 3: return String(localized: "Security")
        case 4: return String(localized: "Properties")
        default: return ""
        }
    }

    var canGoBack: Bool { currentStep > 1 }

    func goBack() {
        guard canGoBack else { return }
        currentStep -= 1
    }

    func goNext() {
        guard currentStep < totalSteps else { return }
        currentStep += 1
    }

    // MARK: - Step 1 Validation

    var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    // MARK: - Step 2 Helpers

    var fullName: String {
        let f = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let l = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if f.isEmpty && l.isEmpty { return "" }
        return "\(f) \(l)".trimmingCharacters(in: .whitespaces)
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        return String(parts.compactMap { $0.first }.prefix(2)).uppercased()
    }

    var isStep2Valid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Step 3 Password

    var hasMinLength: Bool { password.count >= 8 }
    var hasUppercase: Bool { password.range(of: "[A-Z]", options: .regularExpression) != nil }
    var hasNumber: Bool { password.range(of: "[0-9]", options: .regularExpression) != nil }
    var hasSpecialChar: Bool { password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil }
    var passwordsMatch: Bool { !password.isEmpty && password == confirmPassword }

    var passwordStrength: Int {
        var score = 0
        if hasMinLength { score += 1 }
        if hasUppercase { score += 1 }
        if hasNumber { score += 1 }
        if hasSpecialChar { score += 1 }
        return score
    }

    var strengthLabel: String {
        switch passwordStrength {
        case 0: return ""
        case 1: return String(localized: "Weak")
        case 2: return String(localized: "Fair")
        case 3: return String(localized: "Good")
        case 4: return String(localized: "Strong password")
        default: return ""
        }
    }

    var strengthColor: Color {
        switch passwordStrength {
        case 1: return AppColors.expense
        case 2: return Color(hex: "F59E0B")
        case 3: return Color(hex: "F59E0B")
        case 4: return Color(hex: "10B981")
        default: return AppColors.border
        }
    }

    var isAnyPasswordVisible: Bool {
        isPasswordVisible || isConfirmPasswordVisible
    }

    var isStep3Valid: Bool {
        hasMinLength && hasUppercase && hasNumber && hasSpecialChar && passwordsMatch
    }

    // MARK: - Sign Up (Step 4 → Verification)

    func createAccount() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.isLoading = false
            self?.phase = .verification
            self?.startTimer()
        }
    }

    // MARK: - Verification

    var timerFormatted: String {
        let m = timerSeconds / 60
        let s = timerSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var isCodeComplete: Bool {
        verificationCode.allSatisfy { !$0.isEmpty }
    }

    var enteredCode: String {
        verificationCode.joined()
    }

    func startTimer() {
        timerSeconds = 300
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timerSeconds > 0 {
                    self.timerSeconds -= 1
                } else {
                    self.timerCancellable?.cancel()
                }
            }
    }

    func resendCode() {
        verificationCode = Array(repeating: "", count: 6)
        startTimer()
    }

    func verifyEmail(onSuccess: @escaping () -> Void) {
        guard isCodeComplete else { return }
        isVerifying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isVerifying = false
            self?.timerCancellable?.cancel()
            self?.phase = .success
        }
    }

    // MARK: - Social Auth

    func signUpWithGoogle() {
        // TODO: Implement Google Sign-Up
    }

    func signUpWithApple() {
        // TODO: Implement Apple Sign-Up
    }

    func incrementPropertyCount() {
        if propertyCount < 50 { propertyCount += 1 }
    }

    func decrementPropertyCount() {
        if propertyCount > 1 { propertyCount -= 1 }
    }
}

// MARK: - Rental Management Type

enum RentalManagementType: String, CaseIterable {
    case shortTerm
    case longTerm
    case both

    var title: String {
        switch self {
        case .shortTerm: return String(localized: "Short-term Rentals")
        case .longTerm: return String(localized: "Long-term Rentals")
        case .both: return String(localized: "Both Types")
        }
    }

    var description: String {
        switch self {
        case .shortTerm: return String(localized: "Vacation rentals, Airbnb, VRBO, and nightly stays")
        case .longTerm: return String(localized: "Monthly tenants, leases, and traditional rentals")
        case .both: return String(localized: "I manage a mix of short and long-term rentals")
        }
    }

    var emoji: String {
        switch self {
        case .shortTerm: return "\u{1F3D6}\u{FE0F}"
        case .longTerm: return "\u{1F3E2}"
        case .both: return "\u{1F3D8}\u{FE0F}"
        }
    }

    var iconGradient: [Color] {
        switch self {
        case .shortTerm: return [Color(hex: "FEE2E2"), Color(hex: "FECACA")]
        case .longTerm: return [Color(hex: "DBEAFE"), Color(hex: "BFDBFE")]
        case .both: return [Color(hex: "D1FAE5"), Color(hex: "A7F3D0")]
        }
    }

    var chips: [String] {
        switch self {
        case .shortTerm: return ["Airbnb", "Booking.com", "VRBO", String(localized: "Direct")]
        case .longTerm: return [String(localized: "Monthly"), String(localized: "Annual Lease")]
        case .both: return []
        }
    }
}
