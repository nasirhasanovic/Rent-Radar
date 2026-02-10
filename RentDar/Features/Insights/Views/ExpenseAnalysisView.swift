import SwiftUI
import CoreData

struct ExpenseAnalysisView: View {
    let viewModel: InsightsViewModel
    let property: PropertyEntity
    var onDismiss: () -> Void

    @State private var aiEnabled: Bool = true
    private let settings = AppSettings.shared

    // Fetch expenses for this property
    private var expenses: [TransactionEntity] {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "property == %@ AND isIncome == NO", property)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
        do {
            return try property.managedObjectContext?.fetch(request) ?? []
        } catch {
            return []
        }
    }

    // Current month expenses
    private var currentMonthExpenses: [TransactionEntity] {
        let cal = Calendar.current
        let now = Date()
        return expenses.filter { expense in
            guard let date = expense.date else { return false }
            return cal.isDate(date, equalTo: now, toGranularity: .month)
        }
    }

    // Last month expenses
    private var lastMonthExpenses: [TransactionEntity] {
        let cal = Calendar.current
        let now = Date()
        guard let lastMonth = cal.date(byAdding: .month, value: -1, to: now) else { return [] }
        return expenses.filter { expense in
            guard let date = expense.date else { return false }
            return cal.isDate(date, equalTo: lastMonth, toGranularity: .month)
        }
    }

    private var totalCurrentMonth: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var totalLastMonth: Double {
        lastMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    private var percentChange: Int {
        guard totalLastMonth > 0 else { return 0 }
        return Int(((totalCurrentMonth - totalLastMonth) / totalLastMonth) * 100)
    }

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }

    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    // Category breakdown
    private var categoryBreakdown: [(name: String, amount: Double, color: Color, percent: Double)] {
        var totals: [String: Double] = [:]
        for expense in currentMonthExpenses {
            let cat = expense.category?.capitalized ?? "Other"
            totals[cat, default: 0] += expense.amount
        }

        let total = totalCurrentMonth
        let colors: [String: Color] = [
            "Cleaning": AppColors.error,
            "Marketing": AppColors.warning,
            "Supplies": AppColors.info,
            "Repairs": Color(hex: "8B5CF6"),
            "Utilities": Color(hex: "F59E0B"),
            "Other": AppColors.textTertiary
        ]

        return totals
            .sorted { $0.value > $1.value }
            .map { name, amount in
                let percent = total > 0 ? (amount / total) * 100 : 0
                let color = colors[name] ?? AppColors.textTertiary
                return (name, amount, color, percent)
            }
    }

    // Biggest expense category
    private var biggestCategory: (name: String, amount: Double, percent: Int)? {
        guard let first = categoryBreakdown.first else { return nil }
        return (first.name, first.amount, Int(first.percent))
    }

    private var hasExpenseData: Bool {
        !expenses.isEmpty
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header section
                headerSection

                // Content
                if hasExpenseData {
                    VStack(spacing: 16) {
                        if aiEnabled {
                            VStack(spacing: 16) {
                                aiAnalysisCard
                                savingsSection
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                        } else {
                            VStack(spacing: 16) {
                                categoryDetailsSection
                                monthlyTrendSection
                                enableAIBanner
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                } else {
                    expenseEmptyState
                        .padding(.horizontal, 16)
                        .padding(.top, 32)
                        .padding(.bottom, 100)
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .preferredColorScheme(settings.colorScheme)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Expense Analysis")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(property.displayName) · \(currentMonthYear)")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // AI toggle button
                AIToggleButton(isEnabled: $aiEnabled)
            }
            .padding(.horizontal, 16)
            .padding(.top, 54)
            .padding(.bottom, 12)

            // Expense summary card
            expenseSummaryCard
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Expense Summary Card

    private var expenseSummaryCard: some View {
        VStack(spacing: 14) {
            // Total
            VStack(spacing: 4) {
                Text("Total Expenses (\(currentMonthName.prefix(3)))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                if hasExpenseData {
                    Text("\(settings.currencySymbol)\(Int(totalCurrentMonth))")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(AppColors.error)

                    HStack(spacing: 4) {
                        if percentChange != 0 {
                            Text(percentChange > 0 ? "↑ \(percentChange)%" : "↓ \(abs(percentChange))%")
                                .foregroundStyle(percentChange > 0 ? AppColors.error : Color(hex: "10B981"))
                            Text("vs last month")
                                .foregroundStyle(.white.opacity(0.7))
                            Text("·")
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Text("\(settings.currencySymbol)\(Int(totalLastMonth)) last month")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .font(.system(size: 12))
                } else {
                    Text("—")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("No expenses recorded yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Segmented bar
            if !categoryBreakdown.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(categoryBreakdown.enumerated()), id: \.offset) { index, item in
                        RoundedRectangle(cornerRadius: index == 0 ? 5 : (index == categoryBreakdown.count - 1 ? 5 : 0))
                            .fill(item.color)
                            .frame(width: max(10, CGFloat(item.percent) / 100 * (UIScreen.main.bounds.width - 64)))
                    }
                }
                .frame(height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 5))

                // Legend
                FlowLayout(spacing: 12) {
                    ForEach(Array(categoryBreakdown.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text("\(item.name) \(settings.currencySymbol)\(Int(item.amount))")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
            } else {
                // Empty bar
                RoundedRectangle(cornerRadius: 5)
                    .fill(.white.opacity(0.1))
                    .frame(height: 10)
            }
        }
        .padding(16)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - AI Analysis Card

    private var aiAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                LinearGradient(
                    colors: [Color(hex: "FEF3C7"), Color(hex: "FBBF24")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    Text("✨")
                        .font(.system(size: 18))
                )

                Text("AI Expense Analysis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            // Analysis text
            VStack(alignment: .leading, spacing: 0) {
                let changeAmount = Int(abs(totalCurrentMonth - totalLastMonth))
                let biggest = biggestCategory

                Text(buildAnalysisText(changeAmount: changeAmount, biggest: biggest))
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(4)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.teal600)
                    .frame(width: 3)
            }
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func buildAnalysisText(changeAmount: Int, biggest: (name: String, amount: Double, percent: Int)?) -> AttributedString {
        var text = AttributedString()

        if percentChange > 0 {
            text += AttributedString(String(localized: "Expenses are up "))
            var amount = AttributedString("\(settings.currencySymbol)\(changeAmount) " + String(localized: "vs last month"))
            amount.foregroundColor = UIColor(AppColors.error)
            amount.font = .systemFont(ofSize: 13, weight: .bold)
            text += amount
            text += AttributedString(". ")
        } else if percentChange < 0 {
            text += AttributedString(String(localized: "Expenses are down "))
            var amount = AttributedString("\(settings.currencySymbol)\(changeAmount) " + String(localized: "vs last month"))
            amount.foregroundColor = UIColor(Color(hex: "10B981"))
            amount.font = .systemFont(ofSize: 13, weight: .bold)
            text += amount
            text += AttributedString(". ")
        }

        if let biggest = biggest {
            text += AttributedString(String(localized: "\(biggest.name) is the biggest driver (\(biggest.percent)%). "))
        }

        let potentialSavings = Int(totalCurrentMonth * 0.15)
        text += AttributedString(String(localized: "Optimizing could save "))
        var savings = AttributedString("\(settings.currencySymbol)\(potentialSavings)/" + String(localized: "month"))
        savings.foregroundColor = UIColor(Color(hex: "10B981"))
        savings.font = .systemFont(ofSize: 13, weight: .bold)
        text += savings
        text += AttributedString(".")

        return text
    }

    // MARK: - Savings Section

    private var savingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Savings Opportunities")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            if let biggest = biggestCategory {
                SavingsOpportunityCard(
                    icon: iconFor(category: biggest.name),
                    title: "\(biggest.name) Costs",
                    subtitle: "\(settings.currencySymbol)\(Int(biggest.amount))/mo · \(biggest.percent)% of expenses",
                    yourCost: Int(biggest.amount / 2), // Estimate per-unit cost
                    marketCost: Int(biggest.amount / 2 * 0.75), // Market is ~25% cheaper
                    suggestion: suggestionFor(category: biggest.name),
                    potentialSavings: Int(biggest.amount * 0.25)
                )
            }

            // Show second biggest if exists
            if categoryBreakdown.count > 1 {
                let second = categoryBreakdown[1]
                SavingsOpportunityCard(
                    icon: iconFor(category: second.name),
                    title: "\(second.name) Costs",
                    subtitle: "\(settings.currencySymbol)\(Int(second.amount))/mo · \(Int(second.percent))% of expenses",
                    yourCost: nil,
                    marketCost: nil,
                    suggestion: suggestionFor(category: second.name),
                    potentialSavings: Int(second.amount * 0.2)
                )
            }
        }
    }

    private func iconFor(category: String) -> String {
        switch category.lowercased() {
        case "cleaning": return "🧹"
        case "marketing": return "📢"
        case "supplies": return "🧴"
        case "repairs": return "🔧"
        case "utilities": return "💡"
        default: return "📋"
        }
    }

    private func suggestionFor(category: String) -> String {
        switch category.lowercased() {
        case "cleaning": return String(localized: "Switch to bi-weekly deep cleans + turnover-only cleans between guests.")
        case "marketing": return String(localized: "Focus on direct bookings to reduce platform fees.")
        case "supplies": return String(localized: "Buy in bulk from wholesale suppliers for better rates.")
        case "repairs": return String(localized: "Schedule preventive maintenance to avoid costly repairs.")
        case "utilities": return String(localized: "Install smart thermostats to optimize energy usage.")
        default: return String(localized: "Review and optimize spending in this category.")
        }
    }

    // MARK: - Category Details Section (AI Off)

    private var categoryDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Details")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            ForEach(Array(categoryBreakdown.enumerated()), id: \.offset) { _, item in
                CategoryDetailCard(
                    name: item.name,
                    amount: item.amount,
                    description: descriptionFor(category: item.name, expenses: currentMonthExpenses)
                )
            }

            // Placeholders if no data
            if categoryBreakdown.isEmpty {
                CategoryDetailCard(name: "Cleaning", amount: 0, description: "No expenses recorded")
                CategoryDetailCard(name: "Marketing", amount: 0, description: "No expenses recorded")
                CategoryDetailCard(name: "Supplies", amount: 0, description: "No expenses recorded")
                CategoryDetailCard(name: "Repairs", amount: 0, description: "No expenses recorded")
            }
        }
    }

    private func descriptionFor(category: String, expenses: [TransactionEntity]) -> String {
        let categoryExpenses = expenses.filter { ($0.category?.capitalized ?? "Other") == category }
        let count = categoryExpenses.count

        switch category.lowercased() {
        case "cleaning":
            let avg = count > 0 ? Int(categoryExpenses.reduce(0) { $0 + $1.amount } / Double(count)) : 0
            return String(localized: "\(count) turnovers · \(settings.currencySymbol)\(avg) avg per turnover")
        case "marketing":
            return String(localized: "Listing ads, photos")
        case "supplies":
            return String(localized: "Toiletries, linens")
        case "repairs":
            return String(localized: "Maintenance & repairs")
        case "utilities":
            return String(localized: "Electricity, water, internet")
        default:
            return String(localized: "\(count) transactions")
        }
    }

    // MARK: - Monthly Trend Section (AI Off)

    private var monthlyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Trend")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            HStack(alignment: .bottom, spacing: 16) {
                ForEach(monthlyTrendData, id: \.month) { data in
                    MonthlyTrendBar(
                        month: data.month,
                        amount: data.amount,
                        maxAmount: monthlyTrendData.map(\.amount).max() ?? 1
                    )
                }
            }
            .frame(height: 180)
            .padding(16)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    private var monthlyTrendData: [(month: String, amount: Double)] {
        let cal = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var data: [(month: String, amount: Double)] = []

        for i in (0..<3).reversed() {
            guard let date = cal.date(byAdding: .month, value: -i, to: now) else { continue }
            let monthName = formatter.string(from: date)

            let monthExpenses = expenses.filter { expense in
                guard let expDate = expense.date else { return false }
                return cal.isDate(expDate, equalTo: date, toGranularity: .month)
            }

            let total = monthExpenses.reduce(0) { $0 + $1.amount }
            data.append((monthName, total))
        }

        return data
    }

    // MARK: - Enable AI Banner

    private var enableAIBanner: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                aiEnabled = true
            }
        } label: {
            HStack {
                Text("✨ Enable AI for savings opportunities and expense analysis")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("→")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.teal600)
            }
            .padding(12)
            .padding(.horizontal, 4)
            .background(AppColors.tintedGreen)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.teal600)
                    .frame(width: 3)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expense Empty State

    private var expenseEmptyState: some View {
        VStack(spacing: 24) {
            // Icon and title
            VStack(spacing: 12) {
                Text("📋")
                    .font(.system(size: 48))

                Text("Track Your Expenses")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Log your property expenses to get AI-powered savings recommendations and spending analysis.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 280)
            }

            // Add First Expense button
            Button {} label: {
                Text("Add First Expense")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 280)
                    .padding(.vertical, 14)
                    .background(AppColors.teal600)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Placeholder category cards
            VStack(spacing: 8) {
                ExpensePlaceholderCard(icon: "🧹", title: String(localized: "Cleaning"))
                ExpensePlaceholderCard(icon: "🔧", title: String(localized: "Maintenance"))
                ExpensePlaceholderCard(icon: "📦", title: String(localized: "Supplies"))
            }
            .frame(width: 280)
        }
    }
}

// MARK: - Savings Opportunity Card

private struct SavingsOpportunityCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let yourCost: Int?
    let marketCost: Int?
    let suggestion: String
    let potentialSavings: Int

    private let settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 10) {
                    Text(icon)
                        .font(.system(size: 18))
                        .frame(width: 36, height: 36)
                        .background(AppColors.tintedYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                        Text(subtitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.error)
                    }
                }

                // Comparison table (if available)
                if let yourCost = yourCost, let marketCost = marketCost {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Your avg cost")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.textTertiary)
                            Spacer()
                            Text("\(settings.currencySymbol)\(yourCost)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        HStack {
                            Text("Market avg")
                                .font(.system(size: 13))
                                .foregroundStyle(AppColors.textTertiary)
                            Spacer()
                            Text("\(settings.currencySymbol)\(marketCost)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: "10B981"))
                        }
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .top) {
                        Rectangle().fill(AppColors.border).frame(height: 1)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(AppColors.border).frame(height: 1)
                    }
                }

                // Suggestion
                Text(suggestion)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)
                    .lineSpacing(2)

                Text("Could save \(settings.currencySymbol)\(potentialSavings)/month")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "10B981"))

                // Action buttons
                HStack(spacing: 10) {
                    Button {} label: {
                        Text("Optimize")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.teal600)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {} label: {
                        Text("Dismiss")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textTertiary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(14)
        }
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Expense Placeholder Card

private struct ExpensePlaceholderCard: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Text(icon)
                .font(.system(size: 16))
                .opacity(0.4)
                .frame(width: 32, height: 32)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.border)

            Spacer()
        }
        .padding(12)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundStyle(AppColors.border)
        )
    }
}

// MARK: - AI Toggle Button

private struct AIToggleButton: View {
    @Binding var isEnabled: Bool
    @State private var isPressed = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isEnabled.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text("✨")
                    .font(.system(size: 12))
                    .rotationEffect(.degrees(isEnabled ? 0 : -15))
                Text(isEnabled ? "AI On" : "AI Off")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(isEnabled ? .white : .white.opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isEnabled ? .white.opacity(0.2) : .white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEnabled ? .white.opacity(0.3) : .white.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Category Detail Card (AI Off)

private struct CategoryDetailCard: View {
    let name: String
    let amount: Double
    let description: String

    private let settings = AppSettings.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            Text("\(settings.currencySymbol)\(Int(amount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Monthly Trend Bar (AI Off)

private struct MonthlyTrendBar: View {
    let month: String
    let amount: Double
    let maxAmount: Double

    private let settings = AppSettings.shared

    private var barHeight: CGFloat {
        guard maxAmount > 0 else { return 20 }
        return max(20, CGFloat(amount / maxAmount) * 100)
    }

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0D9488"), Color(hex: "0D7C6E")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 40, height: barHeight)

            Text(month)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.textTertiary)

            Text("\(settings.currencySymbol)\(Int(amount))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Flow Layout for Legend

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangement(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangement(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangement(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let vm = InsightsViewModel(context: context)
    let property = PropertyEntity(context: context)
    property.id = UUID()
    property.name = "Beach Studio"

    return ExpenseAnalysisView(viewModel: vm, property: property) {}
}
