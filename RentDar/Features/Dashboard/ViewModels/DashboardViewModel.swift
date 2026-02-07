import SwiftUI
import CoreData

// MARK: - Filter Types

enum RentalTypeFilter: String, CaseIterable {
    case all = "All"
    case shortTerm = "Short-term"
    case longTerm = "Long-term"

    var displayName: String {
        switch self {
        case .all: return String(localized: "All")
        case .shortTerm: return String(localized: "Short-term")
        case .longTerm: return String(localized: "Long-term")
        }
    }
}

enum ShortTermStatusFilter: String, CaseIterable {
    case all = "All"
    case booked = "Booked"
    case available = "Available"

    var displayName: String {
        switch self {
        case .all: return String(localized: "All")
        case .booked: return String(localized: "Booked")
        case .available: return String(localized: "Available")
        }
    }
}

enum LongTermStatusFilter: String, CaseIterable {
    case all = "All"
    case occupied = "Occupied"
    case vacant = "Vacant"

    var displayName: String {
        switch self {
        case .all: return String(localized: "All")
        case .occupied: return String(localized: "Occupied")
        case .vacant: return String(localized: "Vacant")
        }
    }
}

@Observable
final class DashboardViewModel {
    var rentalTypeFilter: RentalTypeFilter = .all
    var shortTermStatusFilter: ShortTermStatusFilter = .all
    var longTermStatusFilter: LongTermStatusFilter = .all

    var userName: String {
        let name = AppSettings.shared.userName
        return name.isEmpty ? String(localized: "User") : name
    }

    var userInitial: String {
        AppSettings.shared.userInitial
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return String(localized: "Good morning")
        case 12..<17: return String(localized: "Good afternoon")
        case 17..<21: return String(localized: "Good evening")
        default: return String(localized: "Good night")
        }
    }

    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    // MARK: - Filter Selection

    func selectRentalType(_ type: RentalTypeFilter) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            rentalTypeFilter = type
            // Reset sub-filters when changing primary filter
            shortTermStatusFilter = .all
            longTermStatusFilter = .all
        }
    }

    func selectShortTermStatus(_ status: ShortTermStatusFilter) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            shortTermStatusFilter = status
        }
    }

    func selectLongTermStatus(_ status: LongTermStatusFilter) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            longTermStatusFilter = status
        }
    }

    // MARK: - Filtering

    func filteredProperties(_ all: [PropertyEntity]) -> [PropertyEntity] {
        var result = all

        // Filter by rental type
        switch rentalTypeFilter {
        case .all:
            break
        case .shortTerm:
            result = result.filter { $0.type == .shortTerm }
        case .longTerm:
            result = result.filter { $0.type == .longTerm }
        }

        // Apply secondary filter based on rental type
        if rentalTypeFilter == .shortTerm {
            switch shortTermStatusFilter {
            case .all:
                break
            case .booked:
                result = result.filter { isBookedTonight($0) }
            case .available:
                result = result.filter { !isBookedTonight($0) }
            }
        } else if rentalTypeFilter == .longTerm {
            switch longTermStatusFilter {
            case .all:
                break
            case .occupied:
                result = result.filter { hasActiveTenant($0) }
            case .vacant:
                result = result.filter { !hasActiveTenant($0) }
            }
        }

        return result
    }

    // MARK: - Filter Counts

    func shortTermCount(_ properties: [PropertyEntity]) -> Int {
        properties.filter { $0.type == .shortTerm }.count
    }

    func longTermCount(_ properties: [PropertyEntity]) -> Int {
        properties.filter { $0.type == .longTerm }.count
    }

    func shortTermBookedCount(_ properties: [PropertyEntity]) -> Int {
        properties.filter { $0.type == .shortTerm && isBookedTonight($0) }.count
    }

    func shortTermAvailableCount(_ properties: [PropertyEntity]) -> Int {
        properties.filter { $0.type == .shortTerm && !isBookedTonight($0) }.count
    }

    func longTermOccupiedCount(_ properties: [PropertyEntity]) -> Int {
        properties.filter { $0.type == .longTerm && hasActiveTenant($0) }.count
    }

    func longTermVacantCount(_ properties: [PropertyEntity]) -> Int {
        properties.filter { $0.type == .longTerm && !hasActiveTenant($0) }.count
    }

    // MARK: - Stats

    func totalRevenue(_ properties: [PropertyEntity]) -> Int {
        let sum = properties.reduce(0.0) { total, property in
            let transactions = property.transactions?.allObjects as? [TransactionEntity] ?? []
            let income = transactions.filter { $0.isIncome }.reduce(0.0) { $0 + $1.amount }
            return total + (income > 0 ? income : property.nightlyRate * 20)
        }
        return Int(sum)
    }

    func formattedRevenue(_ properties: [PropertyEntity]) -> String {
        "\(AppSettings.shared.currencySymbol)\(totalRevenue(properties).formatted())"
    }

    func revenueTrend(_ properties: [PropertyEntity]) -> Int {
        // Placeholder - would calculate based on previous month comparison
        return 12
    }

    func totalBookings(_ properties: [PropertyEntity]) -> Int {
        var count = 0
        for property in properties {
            let transactions = property.transactions?.allObjects as? [TransactionEntity] ?? []
            let bookings = transactions.filter { $0.isIncome }
            count += bookings.isEmpty ? 4 : bookings.count
        }
        return count
    }

    func totalNights(_ properties: [PropertyEntity]) -> Int {
        var nights = 0
        for property in properties {
            let transactions = property.transactions?.allObjects as? [TransactionEntity] ?? []
            let bookingNights = transactions.filter { $0.isIncome }.reduce(0) { $0 + $1.nights }
            nights += bookingNights > 0 ? bookingNights : 8
        }
        return nights
    }

    func occupancyRate(_ properties: [PropertyEntity]) -> Int {
        guard !properties.isEmpty else { return 0 }
        // Placeholder - would calculate based on actual booked nights / available nights
        return 86
    }

    // MARK: - Booking Status

    func bookedTonightCount(_ properties: [PropertyEntity]) -> Int {
        properties.filter { isBookedTonight($0) }.count
    }

    func isBookedTonight(_ property: PropertyEntity) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let transactions = property.transactions?.allObjects as? [TransactionEntity] ?? []

        return transactions.contains { transaction in
            guard transaction.isIncome,
                  let startDate = transaction.date else { return false }

            let endDate = transaction.endDate ?? startDate

            let start = Calendar.current.startOfDay(for: startDate)
            let end = Calendar.current.startOfDay(for: endDate)

            return today >= start && today <= end
        }
    }

    func hasActiveTenant(_ property: PropertyEntity) -> Bool {
        // For long-term rentals, check if there's an active lease/tenant
        // This could be based on a tenant field or recurring income transactions
        let today = Calendar.current.startOfDay(for: Date())
        let transactions = property.transactions?.allObjects as? [TransactionEntity] ?? []

        return transactions.contains { transaction in
            guard transaction.isIncome,
                  let startDate = transaction.date else { return false }

            let endDate = transaction.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: startDate)!

            let start = Calendar.current.startOfDay(for: startDate)
            let end = Calendar.current.startOfDay(for: endDate)

            return today >= start && today <= end
        }
    }

    func currentBookingPlatform(_ property: PropertyEntity) -> String? {
        let today = Calendar.current.startOfDay(for: Date())
        let transactions = property.transactions?.allObjects as? [TransactionEntity] ?? []

        let activeBooking = transactions.first { transaction in
            guard transaction.isIncome,
                  let startDate = transaction.date else { return false }

            let endDate = transaction.endDate ?? startDate

            let start = Calendar.current.startOfDay(for: startDate)
            let end = Calendar.current.startOfDay(for: endDate)

            return today >= start && today <= end
        }

        return activeBooking?.platform?.uppercased()
    }

    // MARK: - Conflict Detection

    private static let conflictResolvedKey = "dashboard_mockConflictResolved"

    // Store reference to first property for conflict demo
    private var conflictPropertyId: UUID?

    // For demo purposes - in production this would detect real overlaps
    var hasConflicts: Bool {
        // If mock conflict was resolved, don't show it again
        if UserDefaults.standard.bool(forKey: Self.conflictResolvedKey) {
            return false
        }
        return true // Demo: show conflict once
    }

    func markConflictResolved() {
        UserDefaults.standard.set(true, forKey: Self.conflictResolvedKey)
    }

    var conflictPropertyName: String {
        String(localized: "Beach Studio")
    }

    var conflictDateRange: String {
        String(localized: "· Feb 20–23 overlaps on 2 platforms")
    }

    func conflictInfo(for property: PropertyEntity) -> PropertyConflictInfo? {
        // Demo: Return conflict info for the first property only
        if conflictPropertyId == nil {
            conflictPropertyId = property.id
        }

        guard property.id == conflictPropertyId else { return nil }

        return PropertyConflictInfo(
            platform1: "Airbnb",
            dateRange1: "Feb 20–23",
            platform2: "Booking.com",
            dateRange2: "Feb 21–25",
            overlapDays: 3
        )
    }

    // Create mock BookingConflict for navigation
    func createMockConflict(for property: PropertyEntity) -> BookingConflict {
        let calendar = Calendar.current
        let today = Date()

        // Booking 1: Airbnb (Feb 20-23)
        let booking1Start = calendar.date(byAdding: .day, value: 13, to: today)!
        let booking1End = calendar.date(byAdding: .day, value: 16, to: today)!
        let booking1Booked = calendar.date(byAdding: .day, value: -2, to: today)!

        let booking1 = ConflictBooking(
            platform: "Airbnb",
            guestName: "Sarah M.",
            startDate: booking1Start,
            endDate: booking1End,
            bookedDate: booking1Booked,
            isConfirmed: true
        )

        // Booking 2: Booking.com (Feb 21-25)
        let booking2Start = calendar.date(byAdding: .day, value: 14, to: today)!
        let booking2End = calendar.date(byAdding: .day, value: 18, to: today)!
        let booking2Booked = calendar.date(byAdding: .day, value: -1, to: today)!

        let booking2 = ConflictBooking(
            platform: "Booking.com",
            guestName: "James W.",
            startDate: booking2Start,
            endDate: booking2End,
            bookedDate: booking2Booked,
            isConfirmed: true
        )

        // Overlap: Feb 21-23 (3 nights)
        let overlapStart = booking2Start
        let overlapEnd = booking1End

        return BookingConflict(
            propertyName: property.displayName,
            booking1: booking1,
            booking2: booking2,
            overlapStart: overlapStart,
            overlapEnd: overlapEnd
        )
    }
}
