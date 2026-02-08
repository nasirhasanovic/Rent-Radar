import SwiftUI
import CoreData

// MARK: - Booking Filter

enum BookingFilter: String, CaseIterable {
    case upcoming = "Upcoming"
    case current = "Current"
    case past = "Past"
    case cancelled = "Cancelled"

    var displayName: String {
        switch self {
        case .upcoming: return String(localized: "Upcoming")
        case .current: return String(localized: "Current")
        case .past: return String(localized: "Past")
        case .cancelled: return String(localized: "Cancelled")
        }
    }
}

// MARK: - Booking Status

enum BookingStatus {
    case confirmed, pending, checkedIn

    var label: String {
        switch self {
        case .confirmed: return String(localized: "Confirmed")
        case .pending: return String(localized: "Pending")
        case .checkedIn: return String(localized: "Checked In")
        }
    }

    var color: Color {
        switch self {
        case .confirmed: return Color(hex: "059669")
        case .pending: return Color(hex: "D97706")
        case .checkedIn: return Color(hex: "2563EB")
        }
    }

    var bgColor: Color {
        switch self {
        case .confirmed: return AppColors.tintedGreen
        case .pending: return AppColors.tintedYellow
        case .checkedIn: return AppColors.tintedBlue
        }
    }
}

// MARK: - Date Group

struct BookingDateGroup: Identifiable {
    let id: String
    let title: String
    let bookings: [TransactionEntity]
}

// MARK: - BookingsListView

struct BookingsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var onDismiss: () -> Void

    @State private var selectedFilter: BookingFilter = .upcoming
    @State private var allBookings: [TransactionEntity] = []

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            statsBar
            content
        }
        .background(AppColors.background)
        .onAppear { fetchBookings() }
    }

    // MARK: - Filtered Bookings

    private var filteredBookings: [TransactionEntity] {
        let now = Calendar.current.startOfDay(for: Date())
        switch selectedFilter {
        case .upcoming:
            return allBookings.filter { ($0.date ?? .distantPast) > now }
                .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
        case .current:
            return allBookings.filter {
                let start = $0.date ?? .distantFuture
                let end = $0.endDate ?? start
                return start <= now && end >= now
            }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
        case .past:
            return allBookings.filter { ($0.endDate ?? $0.date ?? .distantFuture) < now }
                .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        case .cancelled:
            return []
        }
    }

    private var dateGroups: [BookingDateGroup] {
        let cal = Calendar.current
        let now = Date()
        let bookings = filteredBookings

        guard selectedFilter == .upcoming else {
            if bookings.isEmpty { return [] }
            return [BookingDateGroup(id: "all", title: selectedFilter.displayName, bookings: bookings)]
        }

        var thisWeek: [TransactionEntity] = []
        var nextWeek: [TransactionEntity] = []
        var laterThisMonth: [TransactionEntity] = []
        var future: [TransactionEntity] = []

        let endOfThisWeek = cal.date(byAdding: .day, value: 7 - cal.component(.weekday, from: now), to: cal.startOfDay(for: now))!
        let endOfNextWeek = cal.date(byAdding: .day, value: 7, to: endOfThisWeek)!
        let monthEnd: Date = {
            let comps = cal.dateComponents([.year, .month], from: now)
            return cal.date(byAdding: DateComponents(month: 1, day: -1), to: cal.date(from: comps)!)!
        }()

        for booking in bookings {
            let checkIn = booking.date ?? .distantFuture
            if checkIn <= endOfThisWeek {
                thisWeek.append(booking)
            } else if checkIn <= endOfNextWeek {
                nextWeek.append(booking)
            } else if checkIn <= monthEnd {
                laterThisMonth.append(booking)
            } else {
                future.append(booking)
            }
        }

        var groups: [BookingDateGroup] = []
        if !thisWeek.isEmpty { groups.append(BookingDateGroup(id: "this-week", title: String(localized: "This Week"), bookings: thisWeek)) }
        if !nextWeek.isEmpty { groups.append(BookingDateGroup(id: "next-week", title: String(localized: "Next Week"), bookings: nextWeek)) }
        if !laterThisMonth.isEmpty { groups.append(BookingDateGroup(id: "later", title: String(localized: "Later This Month"), bookings: laterThisMonth)) }
        if !future.isEmpty { groups.append(BookingDateGroup(id: "future", title: String(localized: "Upcoming"), bookings: future)) }
        return groups
    }

    // MARK: - Stats

    private var totalBookings: Int { filteredBookings.count }
    private var totalNights: Int { filteredBookings.reduce(0) { $0 + $1.nights } }
    private var totalRevenue: Double { filteredBookings.reduce(0) { $0 + $1.amount } }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Button { onDismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("All Bookings")
                    .font(AppTypography.heading2)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()
            }

            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BookingFilter.allCases, id: \.rawValue) { filter in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedFilter = filter
                            }
                        } label: {
                            Text(filter.displayName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedFilter == filter ? .white : AppColors.textTertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedFilter == filter ? AppColors.teal500 : AppColors.surface)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 16)
        .background(AppColors.elevated)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        HStack(spacing: 12) {
            StatItem(value: "\(totalBookings)", label: "BOOKINGS")
            StatItem(value: "\(totalNights)", label: "NIGHTS")
            StatItem(
                value: "\(AppSettings.shared.currencySymbol)\(Int(totalRevenue).formatted())",
                label: "REVENUE",
                valueColor: Color(hex: "10B981")
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppColors.elevated)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AppColors.surface).frame(height: 1)
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if dateGroups.isEmpty {
                    emptyState
                } else {
                    ForEach(dateGroups) { group in
                        dateGroupSection(group)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 80)
        }
    }

    private func dateGroupSection(_ group: BookingDateGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header with line
            HStack(spacing: 8) {
                Text(group.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.textTertiary)

                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1)
            }

            ForEach(group.bookings, id: \.objectID) { booking in
                BookingListCard(booking: booking)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 48)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FEF3C7"), Color(hex: "FDE68A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .overlay(
                    Text("\u{1F50D}")
                        .font(.system(size: 56))
                )

            Spacer().frame(height: 24)

            Text(emptyTitle)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Spacer().frame(height: 8)

            Text(emptyDescription)
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)

            if selectedFilter != .upcoming {
                Spacer().frame(height: 20)
                Button {
                    withAnimation { selectedFilter = .upcoming }
                } label: {
                    Text("View upcoming bookings \u{2192}")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                }
            }

            Spacer().frame(height: 48)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyTitle: String {
        switch selectedFilter {
        case .upcoming: return String(localized: "No upcoming bookings")
        case .current: return String(localized: "No current bookings")
        case .past: return String(localized: "No past bookings")
        case .cancelled: return String(localized: "No cancelled bookings")
        }
    }

    private var emptyDescription: String {
        switch selectedFilter {
        case .upcoming: return String(localized: "You don't have any upcoming bookings.\nThey'll appear here when guests book.")
        case .current: return String(localized: "No guests are currently checked in.\nActive stays will show here.")
        case .past: return String(localized: "You don't have any completed bookings\nyet. They'll appear here once guests check out.")
        case .cancelled: return String(localized: "No cancelled bookings to show.\nThat's a good thing!")
        }
    }

    // MARK: - Data

    private func fetchBookings() {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isIncome == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: true)]
        do {
            allBookings = try viewContext.fetch(request)
        } catch {
            allBookings = []
        }
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let value: String
    let label: String
    var valueColor: Color = AppColors.textPrimary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(valueColor)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Booking List Card

private struct BookingListCard: View {
    let booking: TransactionEntity

    private var platform: String { booking.platform ?? "Direct" }
    private var platformColor: Color { CalendarViewModel.platformColor(for: platform) }
    private var platformTintedBg: Color { CalendarViewModel.platformTintedBg(for: platform) }
    private var propertyName: String { booking.property?.displayName ?? String(localized: "Unknown") }
    private var guestName: String { booking.name ?? String(localized: "Guest") }
    private var checkIn: Date { booking.date ?? Date() }
    private var nightCount: Int { booking.nights }
    private var city: String { booking.property?.shortAddress ?? "" }

    private var guestInitials: String {
        let words = guestName.split(separator: " ")
        return String(words.compactMap { $0.first }.prefix(2))
    }

    private var status: BookingStatus {
        let now = Calendar.current.startOfDay(for: Date())
        let start = booking.date ?? .distantFuture
        let end = booking.endDate ?? start
        if start <= now && end >= now { return .checkedIn }
        if platform == "Direct" { return .pending }
        return .confirmed
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top section
            HStack(alignment: .top, spacing: 0) {
                // Left stripe
                platformColor
                    .frame(width: 4)

                VStack(spacing: 12) {
                    // Header: property + amount
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(propertyName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)

                            Text("\(booking.displayDateRange) \u{2022} \(nightCount) nights")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("+\(AppSettings.shared.currencySymbol)\(Int(booking.amount).formatted())")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))

                            Text(platform)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(platformColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(platformTintedBg)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    // Guest info
                    Divider()
                        .foregroundStyle(AppColors.surface)

                    HStack(spacing: 12) {
                        // Avatar
                        Text(guestInitials)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(platformColor)
                            .frame(width: 40, height: 40)
                            .background(platformTintedBg)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(guestName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)

                            HStack(spacing: 12) {
                                Text("2 guests")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.textTertiary)
                                if !city.isEmpty {
                                    Text(city)
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppColors.textTertiary)
                                }
                            }
                        }

                        Spacer()

                        Text(status.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(status.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(status.bgColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(16)
            }
        }
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}
