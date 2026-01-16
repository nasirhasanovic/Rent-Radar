import SwiftUI
import CoreData

// MARK: - Property Insight Model

struct PropertyInsight: Identifiable {
    let id: UUID
    let property: PropertyEntity
    let healthScore: Int
    let revenue: Double
    let expenses: Double
    let occupancy: Int
    let rating: Double
    let recommendation: String

    var netProfit: Double { revenue - expenses }

    var badge: InsightBadge {
        if healthScore >= 85 { return .best }
        if healthScore >= 70 { return .good }
        return .attention
    }

    var formattedRevenue: String {
        "\(AppSettings.shared.currencySymbol)\(Int(revenue).formatted())"
    }

    var formattedNetProfit: String {
        "\(AppSettings.shared.currencySymbol)\(Int(netProfit).formatted())"
    }
}

enum InsightBadge: String {
    case best = "Best"
    case good = "Good"
    case attention = "Attention"

    var color: Color {
        switch self {
        case .best: return Color(hex: "10B981")
        case .good: return AppColors.info
        case .attention: return AppColors.warning
        }
    }

    var bgColor: Color {
        switch self {
        case .best: return AppColors.tintedGreen
        case .good: return AppColors.tintedBlue
        case .attention: return AppColors.tintedYellow
        }
    }
}

// MARK: - AI Recommendation Model

struct AIRecommendation: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let impact: String
    let category: String
    let actionLabel: String
    let color: RecommendationColor
}

enum RecommendationColor: String {
    case green, blue, amber, purple

    var main: Color {
        switch self {
        case .green: return Color(hex: "10B981")
        case .blue: return AppColors.info
        case .amber: return AppColors.warning
        case .purple: return Color(hex: "8B5CF6")
        }
    }

    var bg: Color {
        switch self {
        case .green: return AppColors.tintedGreen
        case .blue: return AppColors.tintedBlue
        case .amber: return AppColors.tintedYellow
        case .purple: return AppColors.tintedPurple
        }
    }
}

// MARK: - ViewModel

@Observable
final class InsightsViewModel {
    private let context: NSManagedObjectContext

    var properties: [PropertyEntity] = []
    var propertyInsights: [PropertyInsight] = []
    var selectedProperty: PropertyEntity?

    // Portfolio aggregates
    var portfolioHealthScore: Int = 0
    var totalRevenue: Double = 0
    var totalExpenses: Double = 0
    var avgOccupancy: Int = 0

    // Trend percentages (mock for now)
    var revenueTrend: Int = 9
    var expensesTrend: Int = 12
    var occupancyTrend: Int = 3
    var scoreTrend: Int = 5

    var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    var formattedTotalRevenue: String {
        "\(AppSettings.shared.currencySymbol)\(Int(totalRevenue).formatted())"
    }

    var formattedTotalExpenses: String {
        "\(AppSettings.shared.currencySymbol)\(Int(totalExpenses).formatted())"
    }

    var hasProperties: Bool { !properties.isEmpty }

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchData()
    }

    func fetchData() {
        fetchProperties()
        calculatePortfolioMetrics()
    }

    private func fetchProperties() {
        let request = PropertyEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PropertyEntity.createdAt, ascending: false)]
        do {
            properties = try context.fetch(request)
            buildPropertyInsights()
        } catch {
            print("Failed to fetch properties: \(error)")
            properties = []
        }
    }

    private func buildPropertyInsights() {
        propertyInsights = properties.map { property in
            let transactions = fetchTransactions(for: property)
            let revenue = transactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
            let expenses = transactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }

            // Calculate occupancy from bookings (simplified)
            let occupancy = calculateOccupancy(from: transactions)

            // Mock rating (would come from reviews in real app)
            let rating = 4.8 + Double.random(in: -0.3...0.12)

            // Calculate health score based on metrics (sum of 4 categories)
            let score = calculateHealthScore(revenue: revenue, expenses: expenses, occupancy: occupancy, rating: rating)

            // Generate recommendation based on data
            let recommendation = generateRecommendation(revenue: revenue, expenses: expenses, occupancy: occupancy)

            return PropertyInsight(
                id: property.id ?? UUID(),
                property: property,
                healthScore: score,
                revenue: revenue,
                expenses: expenses,
                occupancy: occupancy,
                rating: rating,
                recommendation: recommendation
            )
        }
    }

    private func fetchTransactions(for property: PropertyEntity) -> [TransactionEntity] {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "property == %@", property)
        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    private func calculateOccupancy(from transactions: [TransactionEntity]) -> Int {
        let bookings = transactions.filter { $0.isIncome }
        guard !bookings.isEmpty else { return 0 }

        let cal = Calendar.current
        let now = Date()
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let daysInMonth = cal.range(of: .day, in: .month, for: now)!.count

        var bookedDays = 0
        for booking in bookings {
            guard let start = booking.date, let end = booking.endDate else { continue }
            // Count days that fall within current month
            var day = start
            while day < end {
                if cal.isDate(day, equalTo: now, toGranularity: .month) {
                    bookedDays += 1
                }
                day = cal.date(byAdding: .day, value: 1, to: day) ?? day
            }
        }

        return min(100, Int((Double(bookedDays) / Double(daysInMonth)) * 100))
    }

    private func calculateHealthScore(revenue: Double, expenses: Double, occupancy: Int, rating: Double) -> Int {
        // Score is sum of 4 categories, each worth max 25 points (total 100)

        // 1. Occupancy Score (0-25)
        let occupancyScore = min(25, Int(Double(occupancy) / 100 * 25))

        // 2. Revenue Score (0-25)
        let revenueScore = revenue > 0 ? min(25, 20 + Int(min(5, revenue / 500))) : 0

        // 3. Expense Efficiency Score (0-25)
        let expenseRatio = revenue > 0 ? (expenses / revenue) * 100 : 0
        let expenseScore: Int
        if expenseRatio < 10 {
            expenseScore = 25
        } else if expenseRatio < 20 {
            expenseScore = 20
        } else if expenseRatio < 30 {
            expenseScore = 18
        } else {
            expenseScore = 15
        }

        // 4. Guest Satisfaction Score (0-25)
        let satisfactionScore = min(25, Int(rating / 5 * 25))

        return occupancyScore + revenueScore + expenseScore + satisfactionScore
    }

    private func generateRecommendation(revenue: Double, expenses: Double, occupancy: Int) -> String {
        if occupancy < 50 {
            return "Lower minimum stay to fill gaps"
        }
        if expenses > revenue * 0.5 {
            return "Review expense categories"
        }
        if occupancy > 85 {
            return "Consider raising rates"
        }
        return "Performance on track"
    }

    private func calculatePortfolioMetrics() {
        guard !propertyInsights.isEmpty else {
            portfolioHealthScore = 0
            totalRevenue = 0
            totalExpenses = 0
            avgOccupancy = 0
            return
        }

        totalRevenue = propertyInsights.reduce(0) { $0 + $1.revenue }
        totalExpenses = propertyInsights.reduce(0) { $0 + $1.expenses }
        avgOccupancy = propertyInsights.reduce(0) { $0 + $1.occupancy } / propertyInsights.count
        portfolioHealthScore = propertyInsights.reduce(0) { $0 + $1.healthScore } / propertyInsights.count
    }

    // MARK: - Property Detail Recommendations

    func getRecommendations(for property: PropertyEntity) -> [AIRecommendation] {
        let transactions = fetchTransactions(for: property)
        guard let insight = propertyInsights.first(where: { $0.property.id == property.id }) else {
            return defaultRecommendations
        }

        let symbol = AppSettings.shared.currencySymbol
        var recommendations: [AIRecommendation] = []

        // 1. REVENUE OPTIMIZATION - Dynamic pricing based on occupancy
        let revenueRec = calculateRevenueOptimization(property: property, insight: insight, transactions: transactions)
        if let rec = revenueRec {
            recommendations.append(rec)
        }

        // 2. OCCUPANCY GAP FILLER - Find gaps in bookings
        let gapRec = calculateOccupancyGaps(property: property, transactions: transactions)
        if let rec = gapRec {
            recommendations.append(rec)
        }

        // 3. EXPENSE ANOMALY DETECTION - Compare current vs historical
        let expenseRec = calculateExpenseAnomaly(transactions: transactions)
        if let rec = expenseRec {
            recommendations.append(rec)
        }

        // 4. PLATFORM MIX OPTIMIZER - Analyze platform distribution
        let platformRec = calculatePlatformMix(transactions: transactions)
        if let rec = platformRec {
            recommendations.append(rec)
        }

        // Ensure at least one recommendation
        if recommendations.isEmpty {
            recommendations.append(AIRecommendation(
                icon: "✅",
                title: "Performance on track",
                description: "Your property is performing well. Keep monitoring for opportunities.",
                impact: "+\(symbol)0",
                category: "Status",
                actionLabel: "Details",
                color: .green
            ))
        }

        return recommendations
    }

    // MARK: - Revenue Optimization

    private func calculateRevenueOptimization(property: PropertyEntity, insight: PropertyInsight, transactions: [TransactionEntity]) -> AIRecommendation? {
        let symbol = AppSettings.shared.currencySymbol
        let bookings = transactions.filter { $0.isIncome }
        guard !bookings.isEmpty else { return nil }

        // Calculate average nightly rate
        var totalNights = 0
        var totalRevenue: Double = 0
        for booking in bookings {
            let nights = booking.nights
            if nights > 0 {
                totalNights += nights
                totalRevenue += booking.amount
            }
        }

        let avgNightlyRate = totalNights > 0 ? totalRevenue / Double(totalNights) : property.nightlyRate
        let suggestedIncrease = max(15, Int(avgNightlyRate * 0.15)) // 15% increase or at least $15

        // Only recommend if occupancy is high enough to support price increase
        if insight.occupancy >= 75 {
            let monthlyImpact = suggestedIncrease * (insight.occupancy / 100) * 30 / 7 * 2 // Weekend nights estimate

            return AIRecommendation(
                icon: "📈",
                title: "Raise weekend rate by \(symbol)\(suggestedIncrease)",
                description: "Your occupancy is \(insight.occupancy)% — demand supports higher pricing",
                impact: "+\(symbol)\(monthlyImpact)/mo",
                category: "Revenue",
                actionLabel: "Apply",
                color: .green
            )
        }

        return nil
    }

    // MARK: - Occupancy Gap Filler

    private func calculateOccupancyGaps(property: PropertyEntity, transactions: [TransactionEntity]) -> AIRecommendation? {
        let symbol = AppSettings.shared.currencySymbol
        let cal = Calendar.current
        let now = Date()

        // Get booked date ranges for the next 30 days
        let bookings = transactions.filter { $0.isIncome }
            .filter { booking in
                guard let date = booking.date else { return false }
                return date >= now && date <= cal.date(byAdding: .day, value: 30, to: now)!
            }
            .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }

        // Find gaps between bookings
        var gaps: [(start: Date, end: Date, nights: Int)] = []
        var lastEnd = now

        for booking in bookings {
            guard let start = booking.date, let end = booking.endDate else { continue }
            if start > lastEnd {
                let gapNights = cal.dateComponents([.day], from: lastEnd, to: start).day ?? 0
                if gapNights >= 2 && gapNights <= 7 { // Fillable gaps
                    gaps.append((lastEnd, start, gapNights))
                }
            }
            if end > lastEnd {
                lastEnd = end
            }
        }

        if let largestGap = gaps.max(by: { $0.nights < $1.nights }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: largestGap.start)
            let endStr = formatter.string(from: largestGap.end)
            let potentialRevenue = Int(property.nightlyRate) * largestGap.nights

            return AIRecommendation(
                icon: "📆",
                title: "Fill \(largestGap.nights)-day gap (\(startStr)–\(endStr))",
                description: "Lower minimum stay to 2 nights to attract bookings",
                impact: "+\(symbol)\(potentialRevenue)",
                category: "Occupancy",
                actionLabel: "View Gap",
                color: .blue
            )
        }

        return nil
    }

    // MARK: - Expense Anomaly Detection

    private func calculateExpenseAnomaly(transactions: [TransactionEntity]) -> AIRecommendation? {
        let symbol = AppSettings.shared.currencySymbol
        let cal = Calendar.current
        let now = Date()

        let expenses = transactions.filter { !$0.isIncome }

        // Current month expenses
        let currentMonthExpenses = expenses.filter { expense in
            guard let date = expense.date else { return false }
            return cal.isDate(date, equalTo: now, toGranularity: .month)
        }

        // Previous months expenses (last 3 months for average)
        let threeMonthsAgo = cal.date(byAdding: .month, value: -3, to: now)!
        let historicalExpenses = expenses.filter { expense in
            guard let date = expense.date else { return false }
            return date >= threeMonthsAgo && !cal.isDate(date, equalTo: now, toGranularity: .month)
        }

        let currentTotal = currentMonthExpenses.reduce(0) { $0 + $1.amount }
        let historicalTotal = historicalExpenses.reduce(0) { $0 + $1.amount }
        let monthsCount = max(1, Set(historicalExpenses.compactMap { expense -> String? in
            guard let date = expense.date else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            return formatter.string(from: date)
        }).count)

        let avgMonthly = historicalTotal / Double(monthsCount)

        // Check for anomaly (>20% increase)
        if currentTotal > avgMonthly * 1.2 && avgMonthly > 0 {
            let percentIncrease = Int(((currentTotal - avgMonthly) / avgMonthly) * 100)
            let potentialSavings = Int(currentTotal - avgMonthly)

            // Find the category with biggest increase
            var categoryTotals: [String: Double] = [:]
            for expense in currentMonthExpenses {
                let cat = expense.category?.capitalized ?? "Other"
                categoryTotals[cat, default: 0] += expense.amount
            }
            let topCategory = categoryTotals.max(by: { $0.value < $1.value })?.key ?? "Expenses"

            return AIRecommendation(
                icon: "⚠️",
                title: "\(topCategory) costs up \(percentIncrease)%",
                description: "\(symbol)\(Int(currentTotal)) this month vs \(symbol)\(Int(avgMonthly)) avg. Review your spending.",
                impact: "Save \(symbol)\(potentialSavings)/mo",
                category: "Expenses",
                actionLabel: "Review",
                color: .amber
            )
        }

        return nil
    }

    // MARK: - Platform Mix Optimizer

    private func calculatePlatformMix(transactions: [TransactionEntity]) -> AIRecommendation? {
        let symbol = AppSettings.shared.currencySymbol
        let incomes = transactions.filter { $0.isIncome }
        guard !incomes.isEmpty else { return nil }

        // Calculate platform distribution
        var platformRevenue: [String: Double] = [:]
        for income in incomes {
            let platform = income.platform ?? "Direct"
            platformRevenue[platform, default: 0] += income.amount
        }

        let totalRevenue = platformRevenue.values.reduce(0, +)
        let directRevenue = platformRevenue["Direct"] ?? 0
        let directPercent = totalRevenue > 0 ? Int((directRevenue / totalRevenue) * 100) : 0

        // Estimate platform fees (assume ~15% average for Airbnb/Booking)
        let platformRevenuePaid = totalRevenue - directRevenue
        let estimatedFees = Int(platformRevenuePaid * 0.15)

        // Recommend if direct bookings are low and fees are significant
        if directPercent < 25 && estimatedFees > 50 {
            return AIRecommendation(
                icon: "📊",
                title: "Boost direct bookings",
                description: "Only \(directPercent)% direct — you're paying ~\(symbol)\(estimatedFees)/mo in platform fees",
                impact: "Save \(symbol)\(estimatedFees)/mo",
                category: "Platform",
                actionLabel: "Learn How",
                color: .purple
            )
        }

        return nil
    }

    private var defaultRecommendations: [AIRecommendation] {
        let symbol = AppSettings.shared.currencySymbol
        return [
            AIRecommendation(
                icon: "📈",
                title: "Raise weekend rate by \(symbol)25",
                description: "Your weekends book at 95% — demand supports it",
                impact: "+\(symbol)200/mo",
                category: "Revenue",
                actionLabel: "Apply",
                color: .green
            ),
            AIRecommendation(
                icon: "📆",
                title: "Fill 3-day gap (Feb 15–17)",
                description: "Lower minimum stay to 2 nights to attract bookings",
                impact: "+\(symbol)370",
                category: "Occupancy",
                actionLabel: "View Gap",
                color: .blue
            ),
            AIRecommendation(
                icon: "⚠️",
                title: "Cleaning costs up 30%",
                description: "\(symbol)170 this month vs \(symbol)130 avg. Review your provider",
                impact: "Save \(symbol)40/mo",
                category: "Expenses",
                actionLabel: "Review",
                color: .amber
            ),
            AIRecommendation(
                icon: "📊",
                title: "Boost direct bookings",
                description: "Only 12% direct — you're paying \(symbol)180/mo in platform fees",
                impact: "Save \(symbol)180/mo",
                category: "Platform",
                actionLabel: "Learn How",
                color: .purple
            )
        ]
    }
}
