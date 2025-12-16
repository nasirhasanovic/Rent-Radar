import SwiftUI

@Observable
final class AppRouter {
    private static let isLoggedInKey = "app_isLoggedIn"
    private static let hasSeenOnboardingKey = "app_hasSeenOnboarding"

    var currentRoute: Route
    var selectedTab: Int = 0

    enum Route: Equatable {
        case onboarding
        case login
        case signUp
        case dashboard
    }

    init() {
        // Check if user is already logged in
        if UserDefaults.standard.bool(forKey: Self.isLoggedInKey) {
            currentRoute = .dashboard
        } else if UserDefaults.standard.bool(forKey: Self.hasSeenOnboardingKey) {
            currentRoute = .login
        } else {
            currentRoute = .onboarding
        }
    }

    func navigateTo(_ route: Route) {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentRoute = route
        }

        // Mark onboarding as seen when navigating away from it
        if route != .onboarding {
            UserDefaults.standard.set(true, forKey: Self.hasSeenOnboardingKey)
        }
    }

    func completeOnboarding() {
        navigateTo(.login)
    }

    func signIn() {
        // Persist login state
        UserDefaults.standard.set(true, forKey: Self.isLoggedInKey)
        navigateTo(.dashboard)
    }

    func signOut() {
        // Clear login state
        UserDefaults.standard.set(false, forKey: Self.isLoggedInKey)
        navigateTo(.login)
    }
}
