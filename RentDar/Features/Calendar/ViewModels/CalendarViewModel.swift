import SwiftUI
import CoreData

@Observable
final class CalendarViewModel {
    private let context: NSManagedObjectContext

    var displayedMonth: Date = Date()
    var selectedProperty: PropertyEntity?
    var allProperties: [PropertyEntity] = []
    var bookings: [TransactionEntity] = []
    var blockedDates: [BlockedDateEntity] = []
    var dayBookingMap: [Int: [TransactionEntity]] = [:]
    var dayBlockedMap: [Int: [BlockedDateEntity]] = [:]
    var selectedDay: Int? = nil
    var selectedBlockedDate: BlockedDateEntity? = nil
    var showEditBlockedDate: Bool = false

    // MARK: - Init

    init(context: NSManagedObjectContext, preselectedProperty: PropertyEntity? = nil) {
        self.context = context
        self.selectedProperty = preselectedProperty
        fetchData()
    }

    // MARK: - Calendar Math

    private var calendar: Calendar { Calendar.current }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    var firstWeekdayOffset: Int {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = calendar.date(from: comps) else { return 0 }
        return (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
    }

    var todayDay: Int? {
        let now = Date()
        guard calendar.isDate(displayedMonth, equalTo: now, toGranularity: .month) else { return nil }
        return calendar.component(.day, from: now)
    }

    // MARK: - Month Navigation

    func shiftMonth(_ delta: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        displayedMonth = newMonth
        selectedDay = nil
        buildDayBookingMap()
        buildDayBlockedMap()
    }

    // MARK: - Data

    func fetchData() {
        fetchProperties()
        fetchBookings()
        fetchBlockedDates()
        buildDayBookingMap()
        buildDayBlockedMap()
    }

    private func fetchProperties() {
        let request = PropertyEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PropertyEntity.createdAt, ascending: false)]
        do {
            allProperties = try context.fetch(request)
        } catch {
            allProperties = []
        }
    }

    private func fetchBookings() {
        let request = TransactionEntity.fetchRequest()
        var predicates: [NSPredicate] = [NSPredicate(format: "isIncome == YES")]
        if let prop = selectedProperty {
            predicates.append(NSPredicate(format: "property == %@", prop))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: true)]
        do {
            bookings = try context.fetch(request)
        } catch {
            bookings = []
        }
    }

    private func fetchBlockedDates() {
        let request = BlockedDateEntity.fetchRequest()
        if let prop = selectedProperty {
            request.predicate = NSPredicate(format: "property == %@", prop)
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BlockedDateEntity.startDate, ascending: true)]
        do {
            blockedDates = try context.fetch(request)
        } catch {
            blockedDates = []
        }
    }

    func buildDayBookingMap() {
        dayBookingMap = [:]

        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let monthStart = calendar.date(from: comps),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)
        else { return }

        for booking in bookings {
            guard let bookingStart = booking.date else { continue }
            let bookingEnd = booking.endDate ?? bookingStart

            let rangeStart = max(bookingStart, monthStart)
            let rangeEnd = min(bookingEnd, monthEnd)

            guard rangeStart <= rangeEnd else { continue }

            var current = rangeStart
            while current <= rangeEnd {
                let day = calendar.component(.day, from: current)
                dayBookingMap[day, default: []].append(booking)
                guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                current = next
            }
        }
    }

    func buildDayBlockedMap() {
        dayBlockedMap = [:]

        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let monthStart = calendar.date(from: comps),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)
        else { return }

        for blocked in blockedDates {
            guard let blockedStart = blocked.startDate, let blockedEnd = blocked.endDate else { continue }

            let rangeStart = max(blockedStart, monthStart)
            let rangeEnd = min(blockedEnd, monthEnd)

            guard rangeStart <= rangeEnd else { continue }

            var current = rangeStart
            while current <= rangeEnd {
                let day = calendar.component(.day, from: current)
                dayBlockedMap[day, default: []].append(blocked)
                guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
                current = next
            }
        }
    }

    func isBlocked(day: Int) -> Bool {
        !(dayBlockedMap[day] ?? []).isEmpty
    }

    func blockedInfo(for day: Int) -> BlockedDateEntity? {
        dayBlockedMap[day]?.first
    }

    // MARK: - Filtering

    func selectFilter(_ property: PropertyEntity?) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedProperty = property
        }
        fetchBookings()
        fetchBlockedDates()
        buildDayBookingMap()
        buildDayBlockedMap()
    }

    // MARK: - Delete Blocked Date

    func deleteBlockedDate(_ blocked: BlockedDateEntity) {
        context.delete(blocked)
        do {
            try context.save()
            fetchBlockedDates()
            buildDayBlockedMap()
        } catch {
            print("Failed to delete blocked date: \(error)")
        }
    }

    // MARK: - Upcoming Bookings

    var upcomingBookings: [TransactionEntity] {
        let now = Date()
        return bookings
            .filter { ($0.date ?? .distantPast) >= calendar.startOfDay(for: now) }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    // MARK: - Day Selection

    func selectDay(_ day: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedDay = selectedDay == day ? nil : day
        }
    }

    var selectedDayBookings: [TransactionEntity] {
        guard let day = selectedDay else { return [] }
        return (dayBookingMap[day] ?? [])
            .reduce(into: [NSManagedObjectID: TransactionEntity]()) { dict, tx in
                dict[tx.objectID] = tx
            }
            .values
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    // MARK: - Platform Dots

    func platformDots(for day: Int) -> [String] {
        guard let dayBookings = dayBookingMap[day] else { return [] }
        var seen = Set<String>()
        var platforms: [String] = []
        for b in dayBookings {
            let p = b.platform ?? "Direct"
            if seen.insert(p).inserted {
                platforms.append(p)
            }
        }
        return platforms
    }

    // MARK: - Platform Colors

    static func platformColor(for platform: String) -> Color {
        switch platform {
        case "Airbnb": return AppColors.error
        case "Booking": return AppColors.info
        case "VRBO": return Color(hex: "8B5CF6")
        case "Direct": return AppColors.warning
        default: return AppColors.textTertiary
        }
    }

    static func platformTintedBg(for platform: String) -> Color {
        switch platform {
        case "Airbnb": return AppColors.tintedRed
        case "Booking": return AppColors.tintedBlue
        case "VRBO": return AppColors.tintedPurple
        case "Direct": return AppColors.tintedYellow
        default: return AppColors.tintedGray
        }
    }

    // MARK: - Property Name for Booking

    func propertyName(for booking: TransactionEntity) -> String {
        booking.property?.displayName ?? String(localized: "Unknown")
    }
}
