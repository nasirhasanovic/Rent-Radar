import SwiftUI

struct MainTabView: View {
    private var settings = AppSettings.shared
    @Environment(AppRouter.self) private var router: AppRouter?

    var body: some View {
        @Bindable var router = router ?? AppRouter()
        TabView(selection: $router.selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: router.selectedTab == 0 ? "square.grid.2x2.fill" : "square.grid.2x2")
                    Text("Home")
                }
                .tag(0)

            CalendarView()
                .tabItem {
                    Image(systemName: router.selectedTab == 1 ? "calendar.circle.fill" : "calendar")
                    Text("Calendar")
                }
                .tag(1)

            InsightsView()
                .tabItem {
                    Image(systemName: router.selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    Text("Insights")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Image(systemName: router.selectedTab == 3 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(3)
        }
        .tint(AppColors.teal600)
        .id(settings.refreshID) // Force rebuild when language changes
    }
}

private struct PlaceholderTabView: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppColors.teal300)
            Text(title)
                .font(AppTypography.heading2)
                .foregroundStyle(AppColors.textPrimary)
            Text("Coming soon")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

#Preview {
    MainTabView()
}
