import SwiftUI
import CoreData

@Observable
final class LogBookingViewModel {
    var selectedProperty: PropertyEntity?
    var guestName: String = ""
    var checkInDate: Date? = nil
    var checkOutDate: Date? = nil
    var displayedMonth: Date = Date()
    var selectedPlatform: String = "Airbnb"
    var nightlyRate: Double = 0
    var cleaningFee: Double = 45
    var platformFeePercent: Double = 15
    var guestCount: Int = 2
    var notes: String = ""

    // Toggles for optional fees
    var includeCleaningFee: Bool = true
    var includePlatformFee: Bool = true

    let platforms = ["Airbnb", "Booking", "Direct", "Other"]

    // Computed booked days for current displayed month
    var bookedDays: Set<Int> {
        guard let property = selectedProperty else { return [] }
        let transactions = property.transactions?.allObjects as? [TransactionEntity] ?? []
        let ranges = transactions.compactMap { tx -> (Date, Date)? in
            guard tx.isIncome, let start = tx.date else { return nil }
            let end = tx.endDate ?? start
            return (start, end)
        }
        return daysInMonthFor(ranges: ranges)
    }

    // Computed blocked days for current displayed month
    var blockedDays: Set<Int> {
        guard let property = selectedProperty else { return [] }
        let blockedDates = property.blockedDates?.allObjects as? [BlockedDateEntity] ?? []
        let ranges = blockedDates.compactMap { blocked -> (Date, Date)? in
            guard let start = blocked.startDate, let end = blocked.endDate else { return nil }
            return (start, end)
        }
        return daysInMonthFor(ranges: ranges)
    }

    private func daysInMonthFor(ranges: [(Date, Date)]) -> Set<Int> {
        let cal = Calendar.current
        var days = Set<Int>()
        let monthStart = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonth)?.count else {
            return days
        }

        for range in ranges {
            let rangeStart = cal.startOfDay(for: range.0)
            let rangeEnd = cal.startOfDay(for: range.1)

            for day in 1...daysInMonth {
                var comps = monthStart
                comps.day = day
                guard let date = cal.date(from: comps) else { continue }
                let dayStart = cal.startOfDay(for: date)

                if dayStart >= rangeStart && dayStart <= rangeEnd {
                    days.insert(day)
                }
            }
        }
        return days
    }

    var nights: Int {
        guard let start = checkInDate, let end = checkOutDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        return max(0, days)
    }

    var nightlySubtotal: Double {
        nightlyRate * Double(nights)
    }

    var effectiveCleaningFee: Double {
        includeCleaningFee ? cleaningFee : 0
    }

    var subtotal: Double {
        nightlySubtotal + effectiveCleaningFee
    }

    var platformFee: Double {
        includePlatformFee ? subtotal * (platformFeePercent / 100) : 0
    }

    var totalPayout: Double {
        subtotal - platformFee
    }

    var formattedNightlyRate: String {
        String(format: "%.0f", nightlyRate)
    }

    var formattedCleaningFee: String {
        String(format: "%.0f", cleaningFee)
    }

    var formattedPlatformFee: String {
        String(format: "-$%.2f", platformFee)
    }

    var formattedTotal: String {
        String(format: "$%.2f", totalPayout)
    }

    var canSave: Bool {
        selectedProperty != nil && !guestName.isEmpty && nights > 0
    }

    func selectProperty(_ property: PropertyEntity) {
        selectedProperty = property
        nightlyRate = property.nightlyRate
        // Reset dates when property changes
        checkInDate = nil
        checkOutDate = nil
    }

    func incrementGuests() {
        if guestCount < 20 {
            guestCount += 1
        }
    }

    func decrementGuests() {
        if guestCount > 1 {
            guestCount -= 1
        }
    }

    func toggleCleaningFee() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            includeCleaningFee.toggle()
        }
    }

    func togglePlatformFee() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            includePlatformFee.toggle()
        }
    }

    func save(context: NSManagedObjectContext) -> Bool {
        guard let property = selectedProperty,
              let start = checkInDate,
              let end = checkOutDate else { return false }

        // Create income transaction (booking)
        let incomeTransaction = TransactionEntity(context: context)
        incomeTransaction.id = UUID()
        incomeTransaction.name = guestName
        incomeTransaction.amount = totalPayout
        incomeTransaction.date = start
        incomeTransaction.endDate = end
        incomeTransaction.isIncome = true
        incomeTransaction.platform = selectedPlatform
        incomeTransaction.detail = notes.isEmpty ? nil : notes
        incomeTransaction.createdAt = Date()
        incomeTransaction.property = property

        // Create expense for cleaning fee if included
        if includeCleaningFee && cleaningFee > 0 {
            let cleaningExpense = TransactionEntity(context: context)
            cleaningExpense.id = UUID()
            cleaningExpense.name = "Cleaning Service"
            cleaningExpense.amount = cleaningFee
            cleaningExpense.date = start
            cleaningExpense.isIncome = false
            cleaningExpense.category = "cleaning"
            cleaningExpense.detail = "Turnover clean for \(guestName.isEmpty ? "guest" : guestName)"
            cleaningExpense.createdAt = Date()
            cleaningExpense.property = property
        }

        // Create expense for platform fee if included
        if includePlatformFee && platformFee > 0 {
            let platformExpense = TransactionEntity(context: context)
            platformExpense.id = UUID()
            platformExpense.name = "\(selectedPlatform) Service Fee"
            platformExpense.amount = platformFee
            platformExpense.date = start
            platformExpense.isIncome = false
            platformExpense.category = "marketing"
            platformExpense.detail = "\(Int(platformFeePercent))% platform fee for \(guestName.isEmpty ? "booking" : guestName)"
            platformExpense.createdAt = Date()
            platformExpense.property = property
        }

        do {
            try context.save()
            return true
        } catch {
            print("Error saving booking: \(error)")
            return false
        }
    }
}
