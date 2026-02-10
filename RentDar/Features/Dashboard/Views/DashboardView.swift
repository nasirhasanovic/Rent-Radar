import SwiftUI
import CoreData

private enum ActiveCover: Identifiable {
    case addProperty
    case addBooking
    case propertyDetail(PropertyEntity)
    case editProperty(PropertyEntity)

    var id: String {
        switch self {
        case .addProperty: return "add"
        case .addBooking: return "booking"
        case .propertyDetail(let p): return "detail-\(p.objectID)"
        case .editProperty(let p): return "edit-\(p.objectID)"
        }
    }
}

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(AppRouter.self) private var router: AppRouter?
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PropertyEntity.createdAt, ascending: false)],
        animation: .default
    )
    private var properties: FetchedResults<PropertyEntity>

    private let settings = AppSettings.shared
    @State private var viewModel = DashboardViewModel()
    @State private var hasAppeared = false
    @State private var buttonPulse = false
    @State private var selectedPropertyForMenu: PropertyEntity?
    @State private var propertyToDelete: PropertyEntity?
    @State private var activeCover: ActiveCover?
    @State private var conflictToResolve: BookingConflict?
    @State private var showSearch = false

    private var filtered: [PropertyEntity] {
        viewModel.filteredProperties(Array(properties))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header section with gradient
                VStack(spacing: 0) {
                    headerContent
                }
                .padding(.bottom, 20)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E"), Color(hex: "10B981")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 28,
                            bottomTrailingRadius: 28,
                            topTrailingRadius: 0
                        )
                    )
                )

                if properties.isEmpty {
                    emptyState
                        .padding(.top, 20)
                } else {
                    // Conflict alert banner (if any conflicts)
                    if viewModel.hasConflicts {
                        ConflictAlertBanner(
                            propertyName: viewModel.conflictPropertyName,
                            dateRange: viewModel.conflictDateRange,
                            onResolve: {
                                if let firstProperty = properties.first {
                                    conflictToResolve = viewModel.createMockConflict(for: firstProperty)
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, -4)
                        .padding(.bottom, 8)
                    }

                    // Quick actions
                    quickActionsSection
                        .padding(.top, viewModel.hasConflicts ? 6 : 14)

                    // Properties section
                    propertiesSection
                        .padding(.top, 14)

                    // Insights teaser
                    insightsTeaser
                        .padding(.top, 6)
                }
            }
            .padding(.bottom, 100)
        }
        .background(AppColors.background)
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(item: $activeCover) { cover in
            Group {
                switch cover {
                case .addProperty:
                    AddPropertyView(
                        onDismiss: { activeCover = nil },
                        onComplete: { activeCover = nil },
                        onAddBooking: { _ in
                            activeCover = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                activeCover = .addBooking
                            }
                        },
                        onRecordIncome: { _ in
                            activeCover = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                activeCover = .addBooking
                            }
                        },
                        onViewInsights: {
                            activeCover = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                router?.selectedTab = 2
                            }
                        }
                    )
                    .environment(\.managedObjectContext, viewContext)
                case .addBooking:
                    LogBookingView(onDismiss: { activeCover = nil })
                        .environment(\.managedObjectContext, viewContext)
                case .propertyDetail(let property):
                    PropertyDetailView(
                        property: property,
                        onDismiss: { activeCover = nil }
                    )
                    .id(property.objectID)
                    .environment(\.managedObjectContext, viewContext)
                case .editProperty(let property):
                    EditPropertyView(
                        property: property,
                        onDismiss: { activeCover = nil },
                        onSave: { activeCover = nil }
                    )
                    .id(property.objectID)
                    .environment(\.managedObjectContext, viewContext)
                }
            }
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
        .fullScreenCover(item: $conflictToResolve) { conflict in
            ResolveConflictView(
                conflict: conflict,
                onDismiss: { conflictToResolve = nil },
                onResolved: { _ in
                    viewModel.markConflictResolved()
                }
            )
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: $showSearch) {
            SearchView(onDismiss: { showSearch = false })
                .environment(\.managedObjectContext, viewContext)
                .preferredColorScheme(settings.colorScheme)
                .environment(\.locale, settings.locale)
        }
        .overlay {
            if let property = selectedPropertyForMenu {
                PropertyMenuOverlay(
                    property: property,
                    onEdit: {
                        let prop = property
                        selectedPropertyForMenu = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            activeCover = .editProperty(prop)
                        }
                    },
                    onViewBookings: {
                        selectedPropertyForMenu = nil
                    },
                    onDelete: {
                        let prop = property
                        selectedPropertyForMenu = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            propertyToDelete = prop
                        }
                    },
                    onCancel: {
                        selectedPropertyForMenu = nil
                    }
                )
            }
        }
        .overlay {
            if let property = propertyToDelete {
                DeletePropertyOverlay(
                    property: property,
                    onConfirm: {
                        deleteProperty(property)
                        propertyToDelete = nil
                    },
                    onCancel: {
                        propertyToDelete = nil
                    }
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Header Content

    private var headerContent: some View {
        VStack(spacing: 0) {
            // Top row: Greeting + buttons
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.greeting)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(viewModel.userName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                HStack(spacing: 10) {
                    // Notification button
                    Button {
                        // TODO: Notifications
                    } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Search button
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 15)

            if !properties.isEmpty {
                // Portfolio summary pills
                portfolioSummaryPills
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)

                // Stats cards
                statsCardsRow
                    .padding(.horizontal, 20)
            }
        }
        .padding(.top, 100)
    }

    // MARK: - Portfolio Summary Pills

    private var portfolioSummaryPills: some View {
        HStack(spacing: 12) {
            // Properties count
            HStack(spacing: 5) {
                Circle()
                    .fill(Color(hex: "2DD4A8"))
                    .frame(width: 6, height: 6)
                Text("\(properties.count) Properties")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.12))
            .clipShape(Capsule())

            // Booked tonight
            let bookedCount = viewModel.bookedTonightCount(Array(properties))
            if bookedCount > 0 {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: "F59E0B"))
                        .frame(width: 6, height: 6)
                    Text("\(bookedCount) Booked Tonight")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.white.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer()
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 15)
    }

    // MARK: - Stats Cards Row

    private var statsCardsRow: some View {
        HStack(spacing: 10) {
            // Revenue card
            DashboardStatCard(
                title: String(localized: "Revenue"),
                value: viewModel.formattedRevenue(filtered),
                trend: viewModel.revenueTrend(filtered),
                showTrend: true
            )

            // Occupancy card
            DashboardStatCard(
                title: String(localized: "Occupancy"),
                value: "\(viewModel.occupancyRate(filtered))%",
                occupancyPercent: viewModel.occupancyRate(filtered)
            )

            // Bookings card
            DashboardStatCard(
                title: String(localized: "Bookings"),
                value: "\(viewModel.totalBookings(filtered))",
                subtitle: "\(viewModel.totalNights(filtered)) nights"
            )
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 15)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 10) {
            // Add Property
            QuickActionCard(
                icon: "plus",
                iconGradient: [Color(hex: "0D9488"), Color(hex: "2DD4A8")],
                title: String(localized: "Add Property"),
                subtitle: String(localized: "New listing")
            ) {
                activeCover = .addProperty
            }

            // Log Booking
            QuickActionCard(
                icon: "chart.line.uptrend.xyaxis",
                iconGradient: [Color(hex: "3B82F6"), Color(hex: "60A5FA")],
                title: String(localized: "Log Booking"),
                subtitle: String(localized: "Record stay")
            ) {
                activeCover = .addBooking
            }
        }
        .padding(.horizontal, 20)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }

    // MARK: - Properties Section

    private var propertiesSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("My Properties")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button {
                    // TODO: See all
                } label: {
                    Text("See all")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "0D9488"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            // Primary filter row (All, Short-term, Long-term)
            rentalTypeFilterRow
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            // Secondary filter row (status filters)
            if viewModel.rentalTypeFilter == .shortTerm {
                shortTermStatusFilterRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else if viewModel.rentalTypeFilter == .longTerm {
                longTermStatusFilterRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Property cards
            ForEach(Array(filtered.enumerated()), id: \.element.objectID) { index, property in
                CompactPropertyCard(
                    property: property,
                    isBooked: viewModel.isBookedTonight(property),
                    bookingPlatform: viewModel.currentBookingPlatform(property),
                    conflictInfo: viewModel.conflictInfo(for: property),
                    onResolveConflict: {
                        conflictToResolve = viewModel.createMockConflict(for: property)
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    activeCover = .propertyDetail(property)
                }
                .onLongPressGesture {
                    selectedPropertyForMenu = property
                }
                .offset(y: hasAppeared ? 0 : 30)
                .opacity(hasAppeared ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.75)
                        .delay(Double(index) * 0.1 + 0.2),
                    value: hasAppeared
                )
            }
        }
    }

    // MARK: - Rental Type Filter Row

    private var rentalTypeFilterRow: some View {
        HStack(spacing: 8) {
            ForEach(RentalTypeFilter.allCases, id: \.rawValue) { filter in
                RentalTypeChip(
                    title: filter.displayName,
                    isSelected: viewModel.rentalTypeFilter == filter
                ) {
                    viewModel.selectRentalType(filter)
                }
            }
            Spacer()
        }
    }

    // MARK: - Short-term Status Filter Row

    private var shortTermStatusFilterRow: some View {
        let allProperties = Array(properties)
        return HStack(spacing: 6) {
            // All
            StatusFilterChip(
                title: String(localized: "All"),
                count: viewModel.shortTermCount(allProperties),
                dotColor: Color(hex: "0D9488"),
                isSelected: viewModel.shortTermStatusFilter == .all
            ) {
                viewModel.selectShortTermStatus(.all)
            }

            // Booked
            StatusFilterChip(
                title: String(localized: "Booked"),
                count: viewModel.shortTermBookedCount(allProperties),
                dotColor: Color(hex: "10B981"),
                isSelected: viewModel.shortTermStatusFilter == .booked
            ) {
                viewModel.selectShortTermStatus(.booked)
            }

            // Available
            StatusFilterChip(
                title: String(localized: "Available"),
                count: viewModel.shortTermAvailableCount(allProperties),
                dotColor: Color(hex: "F59E0B"),
                isSelected: viewModel.shortTermStatusFilter == .available
            ) {
                viewModel.selectShortTermStatus(.available)
            }

            Spacer()
        }
    }

    // MARK: - Long-term Status Filter Row

    private var longTermStatusFilterRow: some View {
        let allProperties = Array(properties)
        return HStack(spacing: 6) {
            // All
            StatusFilterChip(
                title: String(localized: "All"),
                count: viewModel.longTermCount(allProperties),
                dotColor: Color(hex: "0D9488"),
                isSelected: viewModel.longTermStatusFilter == .all
            ) {
                viewModel.selectLongTermStatus(.all)
            }

            // Occupied
            StatusFilterChip(
                title: String(localized: "Occupied"),
                count: viewModel.longTermOccupiedCount(allProperties),
                dotColor: Color(hex: "10B981"),
                isSelected: viewModel.longTermStatusFilter == .occupied
            ) {
                viewModel.selectLongTermStatus(.occupied)
            }

            // Vacant
            StatusFilterChip(
                title: String(localized: "Vacant"),
                count: viewModel.longTermVacantCount(allProperties),
                dotColor: Color(hex: "F59E0B"),
                isSelected: viewModel.longTermStatusFilter == .vacant
            ) {
                viewModel.selectLongTermStatus(.vacant)
            }

            Spacer()
        }
    }

    // MARK: - Insights Teaser

    private var insightsTeaser: some View {
        Button {
            // TODO: Navigate to insights
        } label: {
            HStack {
                HStack(spacing: 10) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "2DD4A8").opacity(0.2))
                            .frame(width: 36, height: 36)

                        Image(systemName: "scope")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(hex: "2DD4A8"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Revenue up \(viewModel.revenueTrend(filtered))% this month")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("Tap to view full insights")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(14)
            .padding(.horizontal, 2)
            .background(
                LinearGradient(
                    colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F0FDFA"), Color(hex: "CCFBF1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Text("\u{1F3E0}")
                            .font(.system(size: 64))
                    )

                // Floating badges
                HStack(spacing: 4) {
                    Text("+")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(AppColors.teal600)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .offset(x: 80, y: -55)

                HStack(spacing: 6) {
                    Text("\u{1F4CA}")
                        .font(.system(size: 12))
                    Text("Track")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .offset(x: -75, y: 60)
            }
            .frame(width: 220, height: 200)
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .opacity(hasAppeared ? 1 : 0)

            Spacer().frame(height: 24)

            Text("Add your first property")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 15)

            Spacer().frame(height: 12)

            Text("Start managing your rentals by adding\nyour first property. Track bookings, income,\nand expenses all in one place.")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 15)

            Spacer().frame(height: 32)

            Button {
                activeCover = .addProperty
            } label: {
                HStack(spacing: 8) {
                    Text("+")
                        .font(.system(size: 16, weight: .bold))
                    Text("Add Property")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .scaleEffect(buttonPulse ? 1.05 : 1.0)
            .shadow(
                color: AppColors.teal500.opacity(buttonPulse ? 0.3 : 0.15),
                radius: buttonPulse ? 15 : 8,
                x: 0, y: 4
            )
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 15)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                    .delay(0.8)
                ) {
                    buttonPulse = true
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }

    // MARK: - Actions

    private func deleteProperty(_ property: PropertyEntity) {
        withAnimation {
            viewContext.delete(property)
            try? viewContext.save()
        }
    }
}

// MARK: - Dashboard Stat Card

private struct DashboardStatCard: View {
    let title: String
    let value: String
    var trend: Int? = nil
    var showTrend: Bool = false
    var occupancyPercent: Int? = nil
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(hex: "6B7280"))
                .textCase(.uppercase)
                .tracking(0.5)

            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(Color(hex: "1F2937"))

            if showTrend, let trend = trend {
                HStack(spacing: 3) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "10B981"))
                    Text("+\(trend)%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "10B981"))
                }
            } else if let occupancy = occupancyPercent {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "E5E7EB"))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "0D9488"), Color(hex: "2DD4A8")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(occupancy) / 100, height: 4)
                    }
                }
                .frame(height: 4)
            } else if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "6B7280"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 2)
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard: View {
    let icon: String
    let iconGradient: [Color]
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: iconGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "1F2937"))

                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }

                Spacer()
            }
            .padding(10)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Property Card

private struct CompactPropertyCard: View {
    let property: PropertyEntity
    let isBooked: Bool
    let bookingPlatform: String?
    var conflictInfo: PropertyConflictInfo?
    var onResolveConflict: (() -> Void)?

    private var hasConflict: Bool { conflictInfo != nil }

    private var thumbnailGradient: [Color] {
        if property.type == .longTerm {
            return [Color(hex: "1E3A5F"), Color(hex: "3B82F6")]
        }
        return property.illustrationGradient
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Thumbnail
                ZStack(alignment: .topTrailing) {
                    if let coverImage = property.coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                    } else {
                        LinearGradient(
                            colors: thumbnailGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: property.type == .longTerm ? "building.2.fill" : "house.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.3))
                        )
                    }

                    // Conflict badge on thumbnail
                    if hasConflict {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "EF4444"))
                                .frame(width: 18, height: 18)
                            Text("!")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 4, y: -4)
                    }
                }
                .frame(width: 100, height: 100)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(property.displayName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "1F2937"))
                            .lineLimit(1)

                        Spacer()

                        // Platform badge or Conflict badge
                        if hasConflict {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "EF4444"))
                                    .frame(width: 6, height: 6)
                                Text("Conflict")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color(hex: "EF4444"))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "FEF2F2"))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else if let platform = bookingPlatform {
                            Text(platform)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(platformColor(platform))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(platformBgColor(platform))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }

                    Text(property.shortAddress)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "9CA3AF"))

                    Spacer()

                    HStack {
                        // Price
                        HStack(spacing: 0) {
                            Text(property.formattedPrice)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(hex: "0D9488"))
                            Text(property.type.ratePeriod)
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "9CA3AF"))
                        }

                        Spacer()

                        // Status
                        if !hasConflict {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(isBooked ? Color(hex: "10B981") : Color(hex: "F59E0B"))
                                    .frame(width: 6, height: 6)
                                Text(isBooked ? String(localized: "Booked") : String(localized: "Available"))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(isBooked ? Color(hex: "10B981") : Color(hex: "F59E0B"))
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }

            // Conflict detail section
            if let conflict = conflictInfo {
                VStack(spacing: 10) {
                    // Conflict dates row
                    HStack(spacing: 6) {
                        // Platform 1
                        HStack(spacing: 4) {
                            platformIcon(conflict.platform1)
                            Text(conflict.dateRange1)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "991B1B"))
                        }

                        Text("overlaps with")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "B91C1C"))

                        // Platform 2
                        HStack(spacing: 4) {
                            platformIcon(conflict.platform2)
                            Text(conflict.dateRange2)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(hex: "991B1B"))
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "FEF2F2"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Bottom row with platforms and resolve button
                    HStack {
                        HStack(spacing: 6) {
                            HStack(spacing: 3) {
                                platformIcon(conflict.platform1)
                                platformIcon(conflict.platform2)
                            }

                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "EF4444"))
                                    .frame(width: 6, height: 6)
                                Text("Conflict detected")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color(hex: "EF4444"))
                            }
                        }

                        Spacer()

                        Button {
                            onResolveConflict?()
                        } label: {
                            Text("Resolve")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: "EF4444"))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
                .padding(.top, 4)
            }
        }
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(hasConflict ? Color(hex: "FECACA") : Color.clear, lineWidth: hasConflict ? 1.5 : 0)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    @ViewBuilder
    private func platformIcon(_ platform: String) -> some View {
        let upperPlatform = platform.uppercased()
        let bgColor = platformIconBgColor(upperPlatform)
        let iconColor = platformIconColor(upperPlatform)

        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(bgColor)
                .frame(width: 18, height: 18)

            switch upperPlatform {
            case "AIRBNB":
                Image("airbnb_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            case "BOOKING", "BOOKING.COM":
                Image("booking_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            case "VRBO":
                Text("V")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(iconColor)
            default:
                Image(systemName: "house.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(iconColor)
            }
        }
    }

    private func platformIconBgColor(_ platform: String) -> Color {
        switch platform {
        case "AIRBNB": return Color(hex: "FFF1F0")
        case "BOOKING", "BOOKING.COM": return Color(hex: "E8F0FE")
        case "VRBO": return Color(hex: "EDE9FE")
        default: return Color(hex: "ECFDF5")
        }
    }

    private func platformIconColor(_ platform: String) -> Color {
        switch platform {
        case "AIRBNB": return Color(hex: "FF5A5F")
        case "BOOKING", "BOOKING.COM": return Color(hex: "003580")
        case "VRBO": return Color(hex: "8B5CF6")
        default: return Color(hex: "10B981")
        }
    }

    private func platformColor(_ platform: String) -> Color {
        switch platform {
        case "AIRBNB": return Color(hex: "2563EB")
        case "DIRECT": return Color(hex: "16A34A")
        case "VRBO": return Color(hex: "7C3AED")
        default: return Color(hex: "6B7280")
        }
    }

    private func platformBgColor(_ platform: String) -> Color {
        switch platform {
        case "AIRBNB": return Color(hex: "DBEAFE")
        case "DIRECT": return Color(hex: "F0FDF4")
        case "VRBO": return Color(hex: "EDE9FE")
        default: return Color(hex: "F3F4F6")
        }
    }
}

// MARK: - Rental Type Chip

private struct RentalTypeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color(hex: "6B7280"))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: "0D9488") : .white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color(hex: "0D9488") : Color(hex: "E5E7EB"), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Filter Chip

private struct StatusFilterChip: View {
    let title: String
    let count: Int
    let dotColor: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 5, height: 5)
                Text("\(title) (\(count))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? Color(hex: "0D9488") : Color(hex: "6B7280"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(isSelected ? Color(hex: "F0FDF9") : .white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color(hex: "0D9488") : Color(hex: "E5E7EB"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip (kept for potential future use)

struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                }
                Text(title)
                    .font(AppTypography.caption)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
            .background(isSelected ? AppColors.textPrimary : AppColors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppColors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Property Conflict Info

struct PropertyConflictInfo {
    let platform1: String
    let dateRange1: String
    let platform2: String
    let dateRange2: String
    let overlapDays: Int
}

// MARK: - Conflict Alert Banner

private struct ConflictAlertBanner: View {
    let propertyName: String
    let dateRange: String
    let onResolve: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Warning icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "EF4444"))
                    .frame(width: 36, height: 36)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text("Double-booking detected!")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "991B1B"))

                Text("\(propertyName) \(dateRange)")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "B91C1C"))
                    .lineLimit(1)
            }

            Spacer()

            // Resolve button
            Button(action: onResolve) {
                Text("Resolve")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "EF4444"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(hex: "FEF2F2"), Color(hex: "FEE2E2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "FECACA"), lineWidth: 1)
        )
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
