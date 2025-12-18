import SwiftUI

@Observable
final class LoginViewModel {
    var email = ""
    var password = ""
    var isLoading = false

    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    func signIn(onSuccess: @escaping () -> Void) {
        guard isFormValid else { return }
        isLoading = true
        // Simulate sign-in for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            onSuccess()
        }
    }

    func signInWithGoogle() {
        // TODO: Implement Google Sign-In
    }

    func signInWithApple() {
        // TODO: Implement Apple Sign-In
    }
}
