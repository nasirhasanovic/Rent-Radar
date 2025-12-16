import SwiftUI

@Observable
final class AppSettings {
    static let shared = AppSettings()

    var currencyCode: String {
        didSet { UserDefaults.standard.set(currencyCode, forKey: "app_currency") }
    }

    var themeRaw: String {
        didSet { UserDefaults.standard.set(themeRaw, forKey: "app_theme") }
    }

    var languageCode: String {
        didSet {
            UserDefaults.standard.set(languageCode, forKey: "app_language")
            // Trigger refresh for all observing views
            refreshID = UUID()
        }
    }

    // Used to force view refreshes when language changes
    var refreshID: UUID = UUID()

    // User Profile
    var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "user_name") }
    }

    var userEmail: String {
        didSet { UserDefaults.standard.set(userEmail, forKey: "user_email") }
    }

    var userPhone: String {
        didSet { UserDefaults.standard.set(userPhone, forKey: "user_phone") }
    }

    var businessName: String {
        didSet { UserDefaults.standard.set(businessName, forKey: "business_name") }
    }

    var userLocation: String {
        didSet { UserDefaults.standard.set(userLocation, forKey: "user_location") }
    }

    var userInitial: String {
        userName.first.map(String.init) ?? "U"
    }

    var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .light }
        set { themeRaw = newValue.rawValue }
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }

    var currencySymbol: String {
        Self.currencies.first { $0.code == currencyCode }?.symbol ?? "$"
    }

    var currencyDisplay: String {
        Self.currencies.first { $0.code == currencyCode }?.display ?? "USD ($)"
    }

    private init() {
        self.currencyCode = UserDefaults.standard.string(forKey: "app_currency") ?? "USD"
        self.themeRaw = UserDefaults.standard.string(forKey: "app_theme") ?? AppTheme.light.rawValue
        self.languageCode = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        self.userName = UserDefaults.standard.string(forKey: "user_name") ?? ""
        self.userEmail = UserDefaults.standard.string(forKey: "user_email") ?? ""
        self.userPhone = UserDefaults.standard.string(forKey: "user_phone") ?? ""
        self.businessName = UserDefaults.standard.string(forKey: "business_name") ?? ""
        self.userLocation = UserDefaults.standard.string(forKey: "user_location") ?? ""
    }

    // MARK: - Currency Data

    struct CurrencyInfo {
        let flag: String
        let name: String
        let code: String
        let symbol: String
        let display: String
    }

    static let currencies: [CurrencyInfo] = [
        CurrencyInfo(flag: "🇺🇸", name: "US Dollar", code: "USD", symbol: "$", display: "USD ($)"),
        CurrencyInfo(flag: "🇪🇺", name: "Euro", code: "EUR", symbol: "€", display: "EUR (€)"),
        CurrencyInfo(flag: "🇬🇧", name: "British Pound", code: "GBP", symbol: "£", display: "GBP (£)"),
        CurrencyInfo(flag: "🇯🇵", name: "Japanese Yen", code: "JPY", symbol: "¥", display: "JPY (¥)"),
        CurrencyInfo(flag: "🇨🇦", name: "Canadian Dollar", code: "CAD", symbol: "C$", display: "CAD (C$)"),
        CurrencyInfo(flag: "🇦🇺", name: "Australian Dollar", code: "AUD", symbol: "A$", display: "AUD (A$)"),
        CurrencyInfo(flag: "🇨🇭", name: "Swiss Franc", code: "CHF", symbol: "Fr", display: "CHF (Fr)"),
        CurrencyInfo(flag: "🇧🇦", name: "Bosnian Mark", code: "BAM", symbol: "KM", display: "BAM (KM)")
    ]

    // MARK: - Language Data

    struct LanguageInfo {
        let flag: String
        let name: String
        let subtitle: String
        let code: String
    }

    static let languages: [LanguageInfo] = [
        LanguageInfo(flag: "🇺🇸", name: "English", subtitle: "English (US)", code: "en"),
        LanguageInfo(flag: "🇪🇸", name: "Español", subtitle: "Spanish", code: "es"),
        LanguageInfo(flag: "🇫🇷", name: "Français", subtitle: "French", code: "fr"),
        LanguageInfo(flag: "🇩🇪", name: "Deutsch", subtitle: "German", code: "de"),
        LanguageInfo(flag: "🇮🇹", name: "Italiano", subtitle: "Italian", code: "it"),
        LanguageInfo(flag: "🇵🇹", name: "Português", subtitle: "Portuguese", code: "pt"),
        LanguageInfo(flag: "🇳🇱", name: "Nederlands", subtitle: "Dutch", code: "nl"),
        LanguageInfo(flag: "🇧🇦", name: "Bosanski", subtitle: "Bosnian", code: "bs")
    ]

    var languageDisplayName: String {
        Self.languages.first { $0.code == languageCode }?.name ?? "English"
    }

    var locale: Locale {
        Locale(identifier: languageCode)
    }
}
