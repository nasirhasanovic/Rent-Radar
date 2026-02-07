import SwiftUI
import CoreData

// MARK: - Tab Enum

enum PropertyDetailTab: String, CaseIterable {
    case overview = "Overview"
    case income = "Income"
    case expenses = "Expenses"

    var displayName: String {
        switch self {
        case .overview: return String(localized: "Overview")
        case .income: return String(localized: "Income")
        case .expenses: return String(localized: "Expenses")
        }
    }
}

// MARK: - UI Data Models

struct MockBooking: Identifiable {
    let id = UUID()
    let guestName: String
    let guestInitials: String
    let source: BookingSource
    let nights: Int
    let guests: Int
    let checkIn: Date
    let checkOut: Date
    let amount: Double
    let daysUntilCheckIn: Int

    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: checkIn))-\(formatter.string(from: checkOut))"
    }

    var badgeText: String {
        if daysUntilCheckIn == 0 { return String(localized: "TODAY") }
        if daysUntilCheckIn == 1 { return String(localized: "TOMORROW") }
        return String(localized: "IN \(daysUntilCheckIn) DAYS")
    }
}

struct MockTransaction: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let iconBg: Color
    let dateRange: String
    let detail: String
    let amount: Double
    let isIncome: Bool
    var isEmojiIcon: Bool = false

    var formattedAmount: String {
        let symbol = AppSettings.shared.currencySymbol
        let value = Int(abs(amount)).formatted()
        return isIncome ? "+\(symbol)\(value)" : "-\(symbol)\(value)"
    }
}

struct MockSourceBreakdown: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    var bgColor: Color = AppColors.surface
    var textColor: Color = Color(hex: "10B981")

    var formattedAmount: String {
        "\(AppSettings.shared.currencySymbol)\(Int(amount).formatted())"
    }
}

struct MockExpenseCategory: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    var bgColor: Color = AppColors.surface

    var formattedAmount: String {
        "\(AppSettings.shared.currencySymbol)\(Int(amount).formatted())"
    }
}

// MARK: - Income Platform

enum IncomePlatform: String, CaseIterable {
    case airbnb = "Airbnb"
    case booking = "Booking"
    case vrbo = "VRBO"
    case direct = "Direct"
    case other = "Other"

    var emoji: String {
        switch self {
        case .airbnb: return "\u{1F3E0}"
        case .booking: return "\u{1F171}\u{FE0F}"
        case .vrbo: return "\u{1F3E1}"
        case .direct: return "\u{1F4DE}"
        case .other: return "\u{1F4DD}"
        }
    }

    var iconBg: Color {
        switch self {
        case .airbnb: return AppColors.tintedRed
        case .booking: return AppColors.tintedBlue
        case .vrbo: return AppColors.tintedLightBlue
        case .direct: return AppColors.tintedYellow
        case .other: return AppColors.tintedGray
        }
    }

    var selectedBorder: Color {
        switch self {
        case .airbnb: return Color(hex: "EF4444")
        case .booking: return Color(hex: "3B82F6")
        case .vrbo: return Color(hex: "3D67E5")
        case .direct: return Color(hex: "F59E0B")
        case .other: return AppColors.teal600
        }
    }

    var selectedBg: Color {
        switch self {
        case .airbnb: return AppColors.tintedRed
        case .booking: return AppColors.tintedLightBlue
        case .vrbo: return AppColors.tintedLightBlue
        case .direct: return AppColors.tintedYellow
        case .other: return AppColors.tintedTeal
        }
    }

    var selectedText: Color {
        switch self {
        case .airbnb: return Color(hex: "DC2626")
        case .booking: return Color(hex: "1D4ED8")
        case .vrbo: return Color(hex: "3D67E5")
        case .direct: return Color(hex: "D97706")
        case .other: return AppColors.teal600
        }
    }
}

// MARK: - Expense Category

enum ExpenseCategory: String, CaseIterable {
    case cleaning, repairs, marketing, supplies, utilities, other

    var emoji: String {
        switch self {
        case .cleaning: return "\u{1F9F9}"
        case .repairs: return "\u{1F527}"
        case .marketing: return "\u{1F4E2}"
        case .supplies: return "\u{1F9F4}"
        case .utilities: return "\u{1F4A1}"
        case .other: return "\u{1F4CB}"
        }
    }

    var label: String {
        switch self {
        case .cleaning: return String(localized: "Cleaning")
        case .repairs: return String(localized: "Repairs")
        case .marketing: return String(localized: "Marketing")
        case .supplies: return String(localized: "Supplies")
        case .utilities: return String(localized: "Utilities")
        case .other: return String(localized: "Other")
        }
    }

    var iconBg: Color {
        switch self {
        case .cleaning: return AppColors.tintedTeal
        case .repairs: return AppColors.tintedRed
        case .marketing: return AppColors.tintedOrange
        case .supplies: return AppColors.tintedBlue
        case .utilities: return AppColors.tintedYellow
        case .other: return AppColors.tintedGray
        }
    }
}

// MARK: - ViewModel

@Observable
final class PropertyDetailViewModel {
    let property: PropertyEntity
    private let context: NSManagedObjectContext
    var selectedTab: PropertyDetailTab = .overview
    var showAddExpense: Bool = false
    var showAddIncome: Bool = false
    var showCalendar: Bool = false
    var showBlockDates: Bool = false
    var showConnectPlatform: Bool = false
    var showPlatformsOverview: Bool = false
    var showEditProperty: Bool = false
    var selectedTransaction: TransactionEntity?

    var allTransactions: [TransactionEntity] = []
    let occupancyPercent: Double = 78
    var selectedIncomeSource: String? = nil
    var selectedExpenseCategory: String? = nil

    // MARK: - Connected Platforms

    struct ConnectedPlatform: Identifiable {
        let id = UUID()
        let name: String
        let isConnected: Bool
        let lastSyncDate: Date?
        let bookingCount: Int

        var lastSyncText: String {
            guard let date = lastSyncDate else { return String(localized: "Connect") }
            let minutes = Int(-date.timeIntervalSinceNow / 60)
            if minutes < 1 { return String(localized: "Just now") }
            if minutes < 60 { return String(localized: "\(minutes)m ago") }
            let hours = minutes / 60
            if hours < 24 { return String(localized: "\(hours)h ago") }
            let days = hours / 24
            return String(localized: "\(days)d ago")
        }
    }

    var connectedPlatforms: [ConnectedPlatform] {
        let propertyId = property.id?.uuidString ?? ""

        let platforms: [(name: String, key: String)] = [
            ("Airbnb", "platform_\(propertyId)_Airbnb"),
            ("Booking", "platform_\(propertyId)_Booking.com"),
            ("VRBO", "platform_\(propertyId)_VRBO"),
            ("Direct", "platform_\(propertyId)_Direct")
        ]

        return platforms.map { platform in
            let url = UserDefaults.standard.string(forKey: platform.key)
            let lastSync = UserDefaults.standard.object(forKey: "\(platform.key)_lastSync") as? Date
            let isConnected = url != nil && !url!.isEmpty

            // Count bookings from this platform
            let count = allTransactions.filter {
                $0.isIncome && ($0.platform ?? "").lowercased().contains(platform.name.lowercased())
            }.count

            return ConnectedPlatform(
                name: platform.name,
                isConnected: isConnected,
                lastSyncDate: lastSync,
                bookingCount: count
            )
        }
    }

    var hasConnectedPlatforms: Bool {
        connectedPlatforms.contains { $0.isConnected }
    }

    var totalPlatformBookings: Int {
        connectedPlatforms.reduce(0) { $0 + $1.bookingCount }
    }

    var connectedPlatformCount: Int {
        connectedPlatforms.filter { $0.isConnected }.count
    }

    // MARK: - Computed Totals

    var revenue: Double {
        allTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var expenses: Double {
        allTransactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }

    var netProfit: Double { revenue - expenses }

    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: Date())
    }

    // MARK: - Overview

    var nextBooking: MockBooking {
        let cal = Calendar.current
        let now = Date()
        let upcoming = allTransactions
            .filter { $0.isIncome && ($0.date ?? .distantPast) > now }
            .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }

        if let next = upcoming.first {
            let name = next.name ?? String(localized: "Guest")
            let words = name.split(separator: " ")
            let initials = String(words.compactMap { $0.first }.prefix(2))
            let start = next.date ?? now
            let end = next.endDate ?? cal.date(byAdding: .day, value: 1, to: start)!
            let nights = max(0, cal.dateComponents([.day], from: start, to: end).day ?? 0)
            let daysUntil = max(0, cal.dateComponents([.day], from: now, to: start).day ?? 0)
            return MockBooking(
                guestName: name,
                guestInitials: initials,
                source: BookingSource(rawValue: next.platform ?? "Airbnb") ?? .airbnb,
                nights: nights,
                guests: 2,
                checkIn: start,
                checkOut: end,
                amount: next.amount,
                daysUntilCheckIn: daysUntil
            )
        }

        return MockBooking(
            guestName: "Sarah Mitchell",
            guestInitials: "SM",
            source: .airbnb,
            nights: 4,
            guests: 2,
            checkIn: cal.date(byAdding: .day, value: 2, to: now)!,
            checkOut: cal.date(byAdding: .day, value: 6, to: now)!,
            amount: 740,
            daysUntilCheckIn: 2
        )
    }

    // MARK: - Income Data

    var incomeSourceBreakdown: [MockSourceBreakdown] {
        let incomes = allTransactions.filter { $0.isIncome }
        var platformTotals: [String: Double] = [:]
        for tx in incomes {
            let p = tx.platform ?? "Direct"
            platformTotals[p, default: 0] += tx.amount
        }

        let platformColors: [String: (bg: Color, text: Color)] = [
            "Airbnb": (AppColors.tintedRed, Color(hex: "DC2626")),
            "Booking": (AppColors.tintedBlue, Color(hex: "1D4ED8")),
            "VRBO": (AppColors.tintedLightBlue, Color(hex: "3D67E5")),
            "Direct": (AppColors.tintedYellow, Color(hex: "D97706")),
            "Other": (AppColors.tintedGray, Color(hex: "64748B")),
        ]

        return platformTotals
            .sorted { $0.value > $1.value }
            .map { name, amount in
                let colors = platformColors[name] ?? (AppColors.surface, Color(hex: "10B981"))
                return MockSourceBreakdown(name: name, amount: amount, bgColor: colors.bg, textColor: colors.text)
            }
    }

    var incomeTransactions: [MockTransaction] {
        allTransactions
            .filter { $0.isIncome }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            .map { $0.toMockTransaction() }
    }

    // MARK: - Expense Data

    var expenseCategories: [MockExpenseCategory] {
        let expenseTxs = allTransactions.filter { !$0.isIncome }
        var categoryTotals: [String: Double] = [:]
        for tx in expenseTxs {
            let cat = ExpenseCategory(rawValue: tx.category ?? "")?.label ?? (tx.category?.capitalized ?? "Other")
            categoryTotals[cat, default: 0] += tx.amount
        }

        let catBgColors: [String: Color] = [
            "Cleaning": AppColors.tintedTeal,
            "Marketing": AppColors.tintedOrange,
            "Supplies": AppColors.tintedBlue,
            "Repairs": AppColors.tintedRed,
            "Utilities": AppColors.tintedYellow,
            "Other": AppColors.tintedGray,
        ]

        return categoryTotals
            .sorted { $0.value > $1.value }
            .map { name, amount in
                MockExpenseCategory(name: name, amount: amount, bgColor: catBgColors[name] ?? AppColors.surface)
            }
    }

    var expenseTransactions: [MockTransaction] {
        allTransactions
            .filter { !$0.isIncome }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
            .map { $0.toMockTransaction() }
    }

    // MARK: - Formatted Helpers

    var formattedRevenue: String { "\(AppSettings.shared.currencySymbol)\(Int(revenue).formatted())" }
    var formattedExpenses: String { "\(AppSettings.shared.currencySymbol)\(Int(expenses).formatted())" }
    var formattedNetProfit: String { "\(AppSettings.shared.currencySymbol)\(Int(netProfit).formatted())" }
    var formattedTotalIncome: String { "\(AppSettings.shared.currencySymbol)\(Int(revenue).formatted())" }
    var formattedTotalExpenses: String { "\(AppSettings.shared.currencySymbol)\(Int(expenses).formatted())" }

    var hasIncome: Bool { allTransactions.contains { $0.isIncome } }
    var hasExpenses: Bool { allTransactions.contains { !$0.isIncome } }

    // MARK: - Init

    init(property: PropertyEntity) {
        self.property = property
        self.context = property.managedObjectContext!
        fetchTransactions()
        seedIfNeeded()
    }

    // MARK: - Core Data

    func fetchTransactions() {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "property == %@", property)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
        do {
            allTransactions = try context.fetch(request)
        } catch {
            print("Failed to fetch transactions: \(error)")
            allTransactions = []
        }
    }

    private func seedIfNeeded() {
        guard allTransactions.isEmpty else { return }
        guard !UserDefaults.standard.bool(forKey: "hasSeededSampleData") else { return }
        UserDefaults.standard.set(true, forKey: "hasSeededSampleData")

        let cal = Calendar.current
        let now = Date()

        // Seed income transactions
        let incomeData: [(name: String, platform: String, daysAgo: Int, nights: Int, amount: Double)] = [
            ("Sarah Mitchell", "Airbnb", -2, 4, 740),
            ("John Davis", "Booking", 4, 3, 555),
            ("Emma Wilson", "Airbnb", 11, 6, 1110),
            ("Alex Brown", "Direct", 16, 2, 370),
            ("Lisa Park", "Airbnb", 21, 3, 555),
        ]

        for data in incomeData {
            let tx = TransactionEntity(context: context)
            tx.id = UUID()
            tx.isIncome = true
            tx.name = data.name
            tx.platform = data.platform
            tx.amount = data.amount
            tx.date = cal.date(byAdding: .day, value: -data.daysAgo, to: now)
            tx.endDate = cal.date(byAdding: .day, value: -data.daysAgo + data.nights, to: now)
            tx.detail = ""
            tx.isRecurring = false
            tx.createdAt = now
            tx.property = property
        }

        // Seed expense transactions
        let expenseData: [(name: String, category: String, daysAgo: Int, amount: Double, detail: String)] = [
            ("Cleaning Service", "cleaning", 1, 85, "Turnover clean"),
            ("Airbnb Service Fee", "marketing", 4, 150, "Platform fee"),
            ("Guest Supplies", "supplies", 8, 95, "Toiletries & linens"),
            ("Cleaning Service", "cleaning", 11, 85, "Turnover clean"),
            ("AC Repair", "repairs", 16, 70, "Maintenance"),
            ("Electric Bill", "utilities", 21, 120, "Monthly utility"),
            ("Insurance", "other", 36, 85, "Monthly premium"),
        ]

        for data in expenseData {
            let tx = TransactionEntity(context: context)
            tx.id = UUID()
            tx.isIncome = false
            tx.name = data.name
            tx.category = data.category
            tx.amount = data.amount
            tx.date = cal.date(byAdding: .day, value: -data.daysAgo, to: now)
            tx.detail = data.detail
            tx.isRecurring = false
            tx.createdAt = now
            tx.property = property
        }

        saveContext()
        fetchTransactions()
    }

    // MARK: - Actions

    func addIncome(guestName: String, platform: IncomePlatform, checkIn: Date, checkOut: Date, nights: Int, amount: Double, notes: String) {
        let tx = TransactionEntity(context: context)
        tx.id = UUID()
        tx.isIncome = true
        tx.name = guestName.isEmpty ? String(localized: "Guest") : guestName
        tx.platform = platform.rawValue
        tx.amount = amount
        tx.date = checkIn
        tx.endDate = checkOut
        tx.detail = notes
        tx.isRecurring = false
        tx.createdAt = Date()
        tx.property = property

        saveContext()
        fetchTransactions()
    }

    func addExpense(category: ExpenseCategory, amount: Double, date: Date, detail: String, isRecurring: Bool = false) {
        let tx = TransactionEntity(context: context)
        tx.id = UUID()
        tx.isIncome = false
        tx.name = category.label
        tx.category = category.rawValue
        tx.amount = amount
        tx.date = date
        tx.detail = detail
        tx.isRecurring = isRecurring
        tx.createdAt = Date()
        tx.property = property

        saveContext()
        fetchTransactions()
    }

    func updateTransaction(_ entity: TransactionEntity, name: String, amount: Double, date: Date, endDate: Date?, category: String?, platform: String?, detail: String, isRecurring: Bool) {
        entity.name = name
        entity.amount = amount
        entity.date = date
        entity.endDate = endDate
        entity.category = category
        entity.platform = platform
        entity.detail = detail
        entity.isRecurring = isRecurring

        saveContext()
        fetchTransactions()
    }

    func deleteTransaction(_ entity: TransactionEntity) {
        context.delete(entity)
        saveContext()
        fetchTransactions()
    }

    // MARK: - Blocked & Booked Dates

    var blockedDateRanges: [(start: Date, end: Date)] {
        let blockedDates = property.blockedDates?.allObjects as? [BlockedDateEntity] ?? []
        return blockedDates.compactMap { blocked in
            guard let start = blocked.startDate, let end = blocked.endDate else { return nil }
            return (start: start, end: end)
        }
    }

    var bookedDateRanges: [(start: Date, end: Date, platform: String?)] {
        let incomeTransactions = allTransactions.filter { $0.isIncome }
        return incomeTransactions.compactMap { tx in
            guard let start = tx.date else { return nil }
            let end = tx.endDate ?? start
            return (start: start, end: end, platform: tx.platform)
        }
    }

    func addBlockedDates(start: Date, end: Date, reason: BlockReason, notes: String) {
        let blocked = BlockedDateEntity(context: context)
        blocked.id = UUID()
        blocked.startDate = start
        blocked.endDate = end
        blocked.reason = reason.rawValue
        blocked.notes = notes.isEmpty ? nil : notes
        blocked.createdAt = Date()
        blocked.property = property

        saveContext()
    }

    // MARK: - Entity Arrays

    var incomeEntities: [TransactionEntity] {
        var results = allTransactions.filter { $0.isIncome }
        if let source = selectedIncomeSource {
            results = results.filter { ($0.platform ?? "Direct") == source }
        }
        return results.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    var expenseEntities: [TransactionEntity] {
        var results = allTransactions.filter { !$0.isIncome }
        if let category = selectedExpenseCategory {
            let catRaw = category.lowercased()
            results = results.filter { ($0.category ?? "") == catRaw || ($0.category ?? "").capitalized == category }
        }
        return results.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    func toggleIncomeFilter(_ source: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedIncomeSource = selectedIncomeSource == source ? nil : source
        }
    }

    func toggleExpenseFilter(_ category: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedExpenseCategory = selectedExpenseCategory == category ? nil : category
        }
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
