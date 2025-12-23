import Foundation

struct OnboardingPage: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let imageName: String
}

extension OnboardingPage {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: String(localized: "Manage all your\nrental properties"),
            subtitle: String(localized: "Track short-term rentals, Airbnb, VRBO,\nand long-term tenants all in one place."),
            imageName: "onboarding_properties"
        ),
        OnboardingPage(
            id: 1,
            title: String(localized: "Track your income\neffortlessly"),
            subtitle: String(localized: "See earnings from Airbnb, direct bookings,\nand monthly rentals all in one place."),
            imageName: "onboarding_income"
        ),
        OnboardingPage(
            id: 2,
            title: String(localized: "Manage all\nyour expenses"),
            subtitle: String(localized: "Categorize cleaning, marketing, repairs,\nand more for easy tax reporting."),
            imageName: "onboarding_expenses"
        ),
        OnboardingPage(
            id: 3,
            title: String(localized: "Ready to boost\nyour profits?"),
            subtitle: String(localized: "Start tracking bookings, insights, and\nmaximize your rental income."),
            imageName: "onboarding_calendar"
        )
    ]
}
