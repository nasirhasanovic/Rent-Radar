import SwiftUI
import CoreData

struct PropertyDetailView: View {
    let property: PropertyEntity
    var onDismiss: () -> Void

    @State private var viewModel: PropertyDetailViewModel
    private let settings = AppSettings.shared

    init(property: PropertyEntity, onDismiss: @escaping () -> Void) {
        self.property = property
        self.onDismiss = onDismiss
        _viewModel = State(initialValue: PropertyDetailViewModel(property: property))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection

                // White content area with rounded top corners overlapping header
                VStack(spacing: 0) {
                    tabSelector
                    tabContent
                }
                .padding(.top, 16)
                .background(AppColors.elevated)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24
                    )
                )
                .offset(y: -8)
            }
        }
        .background(AppColors.elevated)
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: Bindable(viewModel).showCalendar) {
            CalendarView(
                preselectedProperty: viewModel.property,
                onDismiss: { viewModel.showCalendar = false }
            )
            .environment(\.managedObjectContext, property.managedObjectContext!)
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: Bindable(viewModel).showConnectPlatform, onDismiss: {
            // Refresh transactions after platform sync
            viewModel.fetchTransactions()
        }) {
            PlatformSelectionView(
                property: viewModel.property,
                onSelect: { platform in
                    // Will be handled by PlatformSelectionView internally
                },
                onDismiss: { viewModel.showConnectPlatform = false }
            )
            .environment(\.managedObjectContext, property.managedObjectContext!)
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: Bindable(viewModel).showPlatformsOverview, onDismiss: {
            viewModel.fetchTransactions()
        }) {
            ConnectedPlatformsView(
                property: viewModel.property,
                onDismiss: { viewModel.showPlatformsOverview = false },
                onConnectNew: {
                    viewModel.showPlatformsOverview = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showConnectPlatform = true
                    }
                }
            )
            .environment(\.managedObjectContext, property.managedObjectContext!)
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: Bindable(viewModel).showEditProperty) {
            EditPropertyView(
                property: viewModel.property,
                onDismiss: { viewModel.showEditProperty = false },
                onSave: { viewModel.fetchTransactions() }
            )
            .environment(\.managedObjectContext, property.managedObjectContext!)
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                // Top bar
                HStack {
                    Button { onDismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button { viewModel.showEditProperty = true } label: {
                            Text("\u{270F}\u{FE0F}")
                                .font(.system(size: 16))
                                .frame(width: 40, height: 40)
                                .background(.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Button { } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                Spacer().frame(height: 12)

                // Property row
                HStack(spacing: 12) {
                    // Thumbnail
                    if let coverImage = property.coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        LinearGradient(
                            colors: [AppColors.teal300, Color(hex: "2DD4BF")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            Image(systemName: property.source.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(.white.opacity(0.7))
                        )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Badge
                        Text("\(property.source.rawValue) \u{2022} \(property.type == .shortTerm ? String(localized: "Short-term") : String(localized: "Long-term"))")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColors.error)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        // Name
                        Text(property.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)

                        // Location
                        Text("\u{1F4CD} \(property.shortAddress)")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .padding(.top, 52)
        }
        .frame(minHeight: 200)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 6) {
            ForEach(PropertyDetailTab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.selectedTab = tab
                    }
                } label: {
                    Text(tab.displayName)
                        .font(.system(size: 13, weight: viewModel.selectedTab == tab ? .semibold : .medium))
                        .foregroundStyle(viewModel.selectedTab == tab ? .white : AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            viewModel.selectedTab == tab
                                ? (tab == .expenses ? AppColors.expense : AppColors.teal600)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .overview:
            PropertyOverviewTab(viewModel: viewModel)
        case .income:
            PropertyIncomeTab(viewModel: viewModel)
        case .expenses:
            PropertyExpensesTab(viewModel: viewModel)
        }
    }
}
