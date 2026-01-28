import SwiftUI

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppRouter.self) private var router: AppRouter?
    private var settings = AppSettings.shared
    @State private var pushNotificationsEnabled = true
    @State private var showCurrency = false
    @State private var showAppearance = false
    @State private var showLanguage = false
    @State private var showEditProfile = false
    @State private var showExportData = false
    @State private var showLogoutConfirmation = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                profileHeader
                settingsSections
                appVersion
            }
        }
        .background(AppColors.background)
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(isPresented: $showCurrency) {
            CurrencySettingsView(onDismiss: { showCurrency = false })
                .preferredColorScheme(settings.colorScheme)
                .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: $showAppearance) {
            AppearanceSettingsView(onDismiss: { showAppearance = false })
                .preferredColorScheme(settings.colorScheme)
                .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: $showLanguage) {
            LanguageSettingsView(onDismiss: { showLanguage = false })
                .preferredColorScheme(settings.colorScheme)
                .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: $showEditProfile) {
            EditProfileView(onDismiss: { showEditProfile = false })
                .preferredColorScheme(settings.colorScheme)
                .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: $showExportData) {
            ExportDataView(onDismiss: { showExportData = false })
                .environment(\.managedObjectContext, viewContext)
                .preferredColorScheme(settings.colorScheme)
                .environment(\.locale, settings.locale)
        }
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                router?.signOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 60)

            Text("Profile")
                .font(AppTypography.heading1)
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.screenPadding)

            Spacer().frame(height: 16)

            // User card
            HStack(spacing: 14) {
                // Avatar with border ring
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(AppColors.teal100)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(settings.userInitial.uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AppColors.teal600)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2.5)
                        )

                    // Edit badge
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(AppColors.teal600)
                        )
                        .offset(x: 2, y: 2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.userName.isEmpty ? "User" : settings.userName)
                        .font(AppTypography.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text(settings.userEmail.isEmpty ? "tap to edit profile" : settings.userEmail)
                        .font(AppTypography.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    // Pro badge
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                        Text("Pro Member")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(0.08))
            )
            .padding(.horizontal, AppSpacing.screenPadding)
            .padding(.bottom, 24)
            .onTapGesture {
                showEditProfile = true
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0F766E"), Color(hex: "14B8A6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24,
                topTrailingRadius: 0
            )
        )
    }

    // MARK: - Settings Sections

    private var settingsSections: some View {
        VStack(spacing: 0) {
            // PREFERENCES
            ProfileSection(title: "PREFERENCES") {
                ProfileRow(
                    profileIcon: ProfileIcon(systemName: "dollarsign", color: AppColors.textSecondary, bg: AppColors.surface),
                    title: "Default Currency",
                    subtitle: settings.currencyDisplay
                ) { showCurrency = true }

                Divider().padding(.leading, 68)

                ProfileRow(
                    profileIcon: ProfileIcon(systemName: "globe", color: AppColors.textSecondary, bg: AppColors.surface),
                    title: "Language",
                    subtitle: settings.languageDisplayName
                ) { showLanguage = true }

                Divider().padding(.leading, 68)

                ProfileRow(
                    profileIcon: ProfileIcon(asset: "profile_moon", bg: Color(hex: "F97316")),
                    title: "Appearance",
                    subtitle: settings.theme.rawValue
                ) { showAppearance = true }
            }

            // NOTIFICATIONS
            ProfileSection(title: "NOTIFICATIONS") {
                ProfileToggleRow(
                    profileIcon: ProfileIcon(asset: "profile_bell", bg: Color(hex: "FFDEAD")),
                    title: "Push Notifications",
                    subtitle: "Bookings, Payments",
                    isOn: $pushNotificationsEnabled
                )

                Divider().padding(.leading, 68)

                ProfileRow(
                    profileIcon: ProfileIcon(systemName: "envelope.fill", bg: Color(hex: "8B5CF6")),
                    title: "Email Reports",
                    subtitle: "Weekly summary"
                )
            }

            // DATA & SECURITY
            ProfileSection(title: "DATA & SECURITY") {
                ProfileRow(
                    profileIcon: ProfileIcon(systemName: "square.and.arrow.up.fill", bg: Color(hex: "06B6D4")),
                    title: "Export Data",
                    subtitle: "Reports & tax documents"
                ) { showExportData = true }

                Divider().padding(.leading, 68)

                ProfileRow(
                    profileIcon: ProfileIcon(systemName: "lock.fill", bg: Color(hex: "F59E0B")),
                    title: "Privacy & Security",
                    subtitle: "Password, 2FA"
                )
            }

            // SUPPORT
            ProfileSection(title: "SUPPORT") {
                ProfileRow(
                    profileIcon: ProfileIcon(systemName: "questionmark", bg: Color(hex: "EF4444")),
                    title: "Help Center",
                    subtitle: "FAQs & tutorials"
                )

                Divider().padding(.leading, 68)

                ProfileRow(
                    profileIcon: ProfileIcon(asset: "profile_door", bg: Color(hex: "EBF8FF")),
                    title: "Log Out",
                    subtitle: nil
                ) { showLogoutConfirmation = true }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Version

    private var appVersion: some View {
        Text("RentDar v1.0.0")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }
}

// MARK: - Section

private struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(AppTypography.label)
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            .padding(.horizontal, AppSpacing.screenPadding)
        }
    }
}

// MARK: - Profile Icon

private struct ProfileIcon: View {
    let icon: String
    let isAsset: Bool
    let iconColor: Color
    let iconBG: Color

    init(systemName: String, color: Color = .white, bg: Color) {
        self.icon = systemName
        self.isAsset = false
        self.iconColor = color
        self.iconBG = bg
    }

    init(asset: String, bg: Color) {
        self.icon = asset
        self.isAsset = true
        self.iconColor = .white
        self.iconBG = bg
    }

    var body: some View {
        Group {
            if isAsset {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
        }
        .frame(width: 36, height: 36)
        .background(iconBG)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Row with Chevron

private struct ProfileRow: View {
    let profileIcon: ProfileIcon
    let title: String
    let subtitle: String?
    var action: (() -> Void)?

    init(profileIcon: ProfileIcon, title: String, subtitle: String?, action: (() -> Void)? = nil) {
        self.profileIcon = profileIcon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 14) {
                profileIcon

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.border)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 56)
        }
    }
}

// MARK: - Row with Toggle

private struct ProfileToggleRow: View {
    let profileIcon: ProfileIcon
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            profileIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.teal500)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 56)
    }
}

#Preview {
    ProfileView()
}
