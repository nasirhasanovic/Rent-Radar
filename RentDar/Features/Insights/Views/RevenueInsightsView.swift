import SwiftUI
import CoreData

struct RevenueInsightsView: View {
    let viewModel: InsightsViewModel
    let property: PropertyEntity
    var onDismiss: () -> Void

    @State private var aiEnabled: Bool = true
    private let settings = AppSettings.shared

    // Fetch income for this property
    private var incomeTransactions: [TransactionEntity] {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "property == %@ AND isIncome == YES", property)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
        do {
            return try property.managedObjectContext?.fetch(request) ?? []
        } catch {
            return []
        }
    }

    // Current month income
    private var currentMonthIncome: [TransactionEntity] {
        let cal = Calendar.current
        let now = Date()
        return incomeTransactions.filter { tx in
            guard let date = tx.date else { return false }
            return cal.isDate(date, equalTo: now, toGranularity: .month)
        }
    }

    // Last month income
    private var lastMonthIncome: [TransactionEntity] {
        let cal = Calendar.current
        let now = Date()
        guard let lastMonth = cal.date(byAdding: .month, value: -1, to: now) else { return [] }
        return incomeTransactions.filter { tx in
            guard let date = tx.date else { return false }
            return cal.isDate(date, equalTo: lastMonth, toGranularity: .month)
        }
    }

    private var totalCurrentMonth: Double {
        currentMonthIncome.reduce(0) { $0 + $1.amount }
    }

    private var totalLastMonth: Double {
        lastMonthIncome.reduce(0) { $0 + $1.amount }
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

    // Platform breakdown
    private var platformBreakdown: [(name: String, amount: Double, color: Color, percent: Double)] {
        var totals: [String: Double] = [:]
        for tx in currentMonthIncome {
            let platform = tx.platform?.capitalized ?? "Direct"
            totals[platform, default: 0] += tx.amount
        }

        let total = totalCurrentMonth
        let colors: [String: Color] = [
            "Airbnb": AppColors.error,
            "Booking": AppColors.info,
            "Booking.com": AppColors.info,
            "Direct": AppColors.warning,
            "Vrbo": Color(hex: "8B5CF6"),
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

    // Dominant platform
    private var dominantPlatform: (name: String, percent: Int)? {
        guard let first = platformBreakdown.first else { return nil }
        return (first.name, Int(first.percent))
    }

    private var hasRevenueData: Bool {
        !incomeTransactions.isEmpty
    }

    // Estimated platform fees
    private func estimatedFees(for platform: String, amount: Double) -> Double {
        switch platform.lowercased() {
        case "airbnb": return amount * 0.15 // ~15% host fee
        case "booking", "booking.com": return amount * 0.15
        case "vrbo": return amount * 0.08
        case "direct": return 0
        default: return amount * 0.10
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header section
                headerSection

                // Content
                if hasRevenueData {
                    VStack(spacing: 16) {
                        if aiEnabled {
                            VStack(spacing: 16) {
                                aiAnalysisCard
                                pricingSuggestions
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                        } else {
                            VStack(spacing: 16) {
                                platformBreakdownSection
                                rateHistorySection
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
                    revenueEmptyState
                        .padding(.horizontal, 16)
                        .padding(.top, 40)
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
                    Text("Revenue Insights")
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

            // Revenue summary card
            revenueSummaryCard
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

    // MARK: - Revenue Summary Card

    private var revenueSummaryCard: some View {
        VStack(spacing: 14) {
            // Total
            VStack(spacing: 4) {
                Text("Total Revenue (\(currentMonthName.prefix(3)))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                if hasRevenueData {
                    Text("\(settings.currencySymbol)\(Int(totalCurrentMonth).formatted())")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(Color(hex: "10B981"))

                    HStack(spacing: 4) {
                        if percentChange != 0 {
                            Text(percentChange > 0 ? "↑ \(percentChange)%" : "↓ \(abs(percentChange))%")
                                .foregroundStyle(percentChange > 0 ? Color(hex: "10B981") : AppColors.error)
                            Text("vs last month")
                                .foregroundStyle(.white.opacity(0.7))
                            Text("·")
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Text("\(settings.currencySymbol)\(Int(totalLastMonth).formatted()) last month")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .font(.system(size: 12))
                } else {
                    Text("—")
                        .font(.system(size: 36, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("No revenue recorded yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }

            // Segmented bar
            if !platformBreakdown.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(platformBreakdown.enumerated()), id: \.offset) { index, item in
                        RoundedRectangle(cornerRadius: index == 0 ? 5 : (index == platformBreakdown.count - 1 ? 5 : 0))
                            .fill(item.color)
                            .frame(width: max(10, CGFloat(item.percent) / 100 * (UIScreen.main.bounds.width - 64)))
                    }
                }
                .frame(height: 10)
                .clipShape(RoundedRectangle(cornerRadius: 5))

                // Legend
                HStack(spacing: 16) {
                    ForEach(Array(platformBreakdown.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text("\(item.name) \(settings.currencySymbol)\(Int(item.amount).formatted())")
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

                Text("AI Revenue Analysis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            // Analysis text
            VStack(alignment: .leading, spacing: 0) {
                Text(buildAnalysisText())
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

    private func buildAnalysisText() -> AttributedString {
        var text = AttributedString()

        if percentChange > 0 {
            text += AttributedString("Your revenue is trending upward. ")
        } else if percentChange < 0 {
            text += AttributedString("Your revenue is down this month. ")
        }

        if let dominant = dominantPlatform {
            text += AttributedString("\(dominant.name) dominates at \(dominant.percent)%, but your ")
            var highlight = AttributedString("cost per booking is highest there")
            highlight.font = .systemFont(ofSize: 13, weight: .bold)
            text += highlight
            text += AttributedString(". ")
        }

        // Calculate potential savings from direct bookings
        let directAmount = platformBreakdown.first { $0.name == "Direct" }?.amount ?? 0
        let totalFees = platformBreakdown.reduce(0.0) { $0 + estimatedFees(for: $1.name, amount: $1.amount) }
        let potentialSavings = Int(totalFees)

        text += AttributedString("Direct bookings have ")
        var zeroFees = AttributedString("zero platform fees")
        zeroFees.foregroundColor = UIColor(Color(hex: "10B981"))
        zeroFees.font = .systemFont(ofSize: 13, weight: .bold)
        text += zeroFees

        if potentialSavings > 0 {
            text += AttributedString(" — growing this channel could save \(settings.currencySymbol)\(potentialSavings)+/month.")
        } else {
            text += AttributedString(".")
        }

        return text
    }

    // MARK: - Pricing Suggestions

    private var pricingSuggestions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pricing Suggestions")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            // Weekend Rate Card
            PricingSuggestionCard(
                title: String(localized: "Weekend Rate"),
                subtitle: String(localized: "Fri–Sun nights"),
                currentPrice: Int(property.nightlyRate),
                suggestedPrice: Int(property.nightlyRate * 1.15),
                estimatedImpact: Int(property.nightlyRate * 0.15 * 8), // ~8 weekend nights
                confidence: 3
            )

            // Gap Pricing Card
            GapPricingCard(
                title: String(localized: "Gap Pricing"),
                dateRange: gapDateRange,
                subtitle: String(localized: "Empty nights between bookings"),
                currentPrice: Int(property.nightlyRate),
                suggestedPrice: Int(property.nightlyRate * 0.85)
            )
        }
    }

    private var gapDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let now = Date()
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: 5, to: now) ?? now
        let end = cal.date(byAdding: .day, value: 7, to: now) ?? now
        return "\(formatter.string(from: start))–\(formatter.string(from: end))"
    }

    // MARK: - Platform Breakdown Section (AI Off)

    private var platformBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Platform Breakdown")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            ForEach(Array(platformBreakdown.enumerated()), id: \.offset) { _, item in
                PlatformBreakdownCard(
                    name: item.name,
                    amount: item.amount,
                    bookings: currentMonthIncome.filter { ($0.platform?.capitalized ?? "Direct") == item.name }.count,
                    color: item.color
                )
            }

            // Show placeholder if no data
            if platformBreakdown.isEmpty {
                PlatformBreakdownCard(name: "Airbnb", amount: 0, bookings: 0, color: AppColors.error)
                PlatformBreakdownCard(name: "Booking.com", amount: 0, bookings: 0, color: AppColors.info)
                PlatformBreakdownCard(name: "Direct", amount: 0, bookings: 0, color: AppColors.warning)
            }
        }
    }

    // MARK: - Rate History Section (AI Off)

    private var rateHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rate History")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: 0) {
                RateHistoryRow(label: "Current weeknight", value: "\(settings.currencySymbol)\(Int(property.nightlyRate))")
                RateHistoryRow(label: "Current weekend", value: "\(settings.currencySymbol)\(Int(property.nightlyRate))")
                RateHistoryRow(label: "Last month weeknight", value: "\(settings.currencySymbol)\(Int(property.nightlyRate * 0.95))")
                RateHistoryRow(label: "Last month weekend", value: "\(settings.currencySymbol)\(Int(property.nightlyRate * 0.95))", isLast: true)
            }
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Enable AI Banner

    private var enableAIBanner: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                aiEnabled = true
            }
        } label: {
            HStack {
                Text("✨ Enable AI for pricing suggestions and revenue analysis")
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

    // MARK: - Revenue Empty State

    private var revenueEmptyState: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("💰")
                    .font(.system(size: 48))

                Text("No Revenue Data Yet")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Record your first booking or connect a platform to start seeing revenue insights and AI pricing suggestions.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 280)
            }

            Button {} label: {
                Text("Record a Booking")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 280)
                    .padding(.vertical, 14)
                    .background(AppColors.teal600)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {} label: {
                Text("Connect Airbnb, Booking.com →")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppColors.teal600)
            }
        }
    }
}

// MARK: - Pricing Suggestion Card

private struct PricingSuggestionCard: View {
    let title: String
    let subtitle: String
    let currentPrice: Int
    let suggestedPrice: Int
    let estimatedImpact: Int
    let confidence: Int // 1-4

    private let settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(settings.currencySymbol)\(currentPrice)/night")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                        .strikethrough()
                    Text("\(settings.currencySymbol)\(suggestedPrice)/night")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "10B981"))
                }
            }

            // Impact & Confidence
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Estimated Impact")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                    Text("+\(settings.currencySymbol)\(estimatedImpact)/month")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "10B981"))
                }

                Spacer()

                HStack(spacing: 6) {
                    Text("Confidence")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                    HStack(spacing: 3) {
                        ForEach(0..<4) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(i < confidence ? AppColors.info : AppColors.border)
                                .frame(width: 16, height: 6)
                        }
                    }
                }
            }
            .padding(10)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(14)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Gap Pricing Card

private struct GapPricingCard: View {
    let title: String
    let dateRange: String
    let subtitle: String
    let currentPrice: Int
    let suggestedPrice: Int

    private let settings = AppSettings.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(title) (\(dateRange))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(settings.currencySymbol)\(currentPrice)/night")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)
                    .strikethrough()
                Text("\(settings.currencySymbol)\(suggestedPrice)/night")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "10B981"))
            }
        }
        .padding(14)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
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

// MARK: - Platform Breakdown Card (AI Off)

private struct PlatformBreakdownCard: View {
    let name: String
    let amount: Double
    let bookings: Int
    let color: Color

    private let settings = AppSettings.shared

    private var avgPerBooking: Int {
        bookings > 0 ? Int(amount / Double(bookings)) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text("\(settings.currencySymbol)\(Int(amount).formatted()) · \(bookings) bookings · Avg \(settings.currencySymbol)\(avgPerBooking)/booking")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Rate History Row (AI Off)

private struct RateHistoryRow: View {
    let label: String
    let value: String
    var isLast: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(16)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(AppColors.border.opacity(0.5))
                    .frame(height: 1)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let vm = InsightsViewModel(context: context)
    let property = PropertyEntity(context: context)
    property.id = UUID()
    property.name = "Beach Studio"
    property.nightlyRate = 185

    return RevenueInsightsView(viewModel: vm, property: property) {}
}
