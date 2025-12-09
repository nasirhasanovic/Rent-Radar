import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter()
    private var settings = AppSettings.shared

    var body: some View {
        Group {
            switch router.currentRoute {
            case .onboarding:
                OnboardingContainerView(
                    onGetStarted: {
                        router.navigateTo(.signUp)
                    },
                    onAlreadyHaveAccount: {
                        router.navigateTo(.login)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .login:
                LoginView(
                    onBack: {
                        router.navigateTo(.onboarding)
                    },
                    onSignIn: {
                        router.signIn()
                    },
                    onSignUp: {
                        router.navigateTo(.signUp)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .signUp:
                SignUpView(
                    onBack: {
                        router.navigateTo(.onboarding)
                    },
                    onLogin: {
                        router.navigateTo(.login)
                    },
                    onComplete: {
                        router.signIn()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .dashboard:
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .environment(router)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: router.currentRoute)
        .preferredColorScheme(settings.colorScheme)
        .environment(\.locale, settings.locale)
        .id(settings.refreshID) // Force rebuild when language changes
    }
}

#Preview {
    ContentView()
}
