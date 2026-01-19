import SwiftUI
import CoreData

// MARK: - Score Category Model

struct ScoreCategory: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let score: Int
    let maxScore: Int
    let isWarning: Bool
    let tip: String?

    var progress: Double {
        Double(score) / Double(maxScore)
    }

    var color: Color {
        isWarning ? AppColors.warning : Color(hex: "10B981")
    }

    var borderColor: Color {
        isWarning ? AppColors.warning : Color(hex: "10B981")
    }
}

struct ScoreImprovement: Identifiable {
    let id = UUID()
    let title: String
    let impact: Int
}

// MARK: - Smart Score View

struct SmartScoreView: View {
    let viewModel: InsightsViewModel
    let property: PropertyEntity
    var onDismiss: () -> Void

    private let settings = AppSettings.shared

    @State private var animatedScore: Double = 0
    @State private var showExpenseAnalysis = false
    @State private var showRevenueInsights = false
    @State private var showCalendar = false

    private var insight: PropertyInsight? {
        viewModel.propertyInsights.first { $0.property.id == property.id }
    }

    private var score: Int {
        // Calculate score as sum of all category scores
        scoreCategories.reduce(0) { $0 + $1.score }
    }

    private var scoreCategories: [ScoreCategory] {
        let occupancy = insight?.occupancy ?? 0
        let revenue = insight?.revenue ?? 0
        let expenses = insight?.expenses ?? 0
        let expenseRatio = revenue > 0 ? (expenses / revenue) * 100 : 0

        // Calculate individual scores out of 25 each
        let occupancyScore = min(25, Int(Double(occupancy) / 100 * 25))
        let revenueScore = revenue > 0 ? min(25, 20 + Int(min(5, revenue / 500))) : 0

        let expenseScore: Int
        let expenseWarning: Bool
        let expenseTip: String?
        if expenseRatio < 10 {
            expenseScore = 25
            expenseWarning = false
            expenseTip = nil
        } else if expenseRatio < 20 {
            expenseScore = 20
            expenseWarning = false
            expenseTip = nil
        } else if expenseRatio < 30 {
            expenseScore = 18
            expenseWarning = true
            expenseTip = "Reduce cleaning costs to hit 24/25"
        } else {
            expenseScore = 15
            expenseWarning = true
            expenseTip = "Review expense categories to improve score"
        }

        let rating = insight?.rating ?? 4.5
        let satisfactionScore = min(25, Int(rating / 5 * 25))

        return [
            ScoreCategory(
                icon: "🗓",
                title: "Occupancy Rate",
                subtitle: "\(occupancy)% this month",
                score: occupancyScore,
                maxScore: 25,
                isWarning: occupancy < 60,
                tip: occupancy < 60 ? "Lower minimum stay to fill gaps" : nil
            ),
            ScoreCategory(
                icon: "💰",
                title: "Revenue Growth",
                subtitle: revenue > 0 ? "+12% month-over-month" : "No revenue yet",
                score: revenueScore,
                maxScore: 25,
                isWarning: revenue == 0,
                tip: nil
            ),
            ScoreCategory(
                icon: "📋",
                title: "Expense Efficiency",
                subtitle: String(format: "%.1f%% expense ratio", expenseRatio),
                score: expenseScore,
                maxScore: 25,
                isWarning: expenseWarning,
                tip: expenseTip
            ),
            ScoreCategory(
                icon: "⭐",
                title: "Guest Satisfaction",
                subtitle: String(format: "%.2f avg rating", rating),
                score: satisfactionScore,
                maxScore: 25,
                isWarning: rating < 4.5,
                tip: nil
            )
        ]
    }

    private var improvements: [ScoreImprovement] {
        var items: [ScoreImprovement] = []

        let expenseRatio = (insight?.expenses ?? 0) / max(1, insight?.revenue ?? 1)
        if expenseRatio > 0.15 {
            items.append(ScoreImprovement(
                title: "Reduce cleaning costs by \(settings.currencySymbol)20/visit",
                impact: 3
            ))
        }

        if (insight?.occupancy ?? 0) > 70 {
            let suggestedRate = Int(property.nightlyRate) + 25
            items.append(ScoreImprovement(
                title: "Raise weekend rates to \(settings.currencySymbol)\(suggestedRate)",
                impact: 3
            ))
        }

        if items.isEmpty {
            items.append(ScoreImprovement(
                title: "Maintain current performance",
                impact: 0
            ))
        }

        return items
    }

    private var targetScore: Int {
        min(100, score + improvements.reduce(0) { $0 + $1.impact })
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header and Score Hero on gradient
                headerAndHeroSection

                // Content
                VStack(alignment: .leading, spacing: 16) {
                    // Score Breakdown
                    Text("Score Breakdown")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    ForEach(scoreCategories) { category in
                        if category.title == "Expense Efficiency" {
                            Button { showExpenseAnalysis = true } label: {
                                ScoreCategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
                        } else if category.title == "Revenue Growth" {
                            Button { showRevenueInsights = true } label: {
                                ScoreCategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
                        } else if category.title == "Occupancy Rate" {
                            Button { showCalendar = true } label: {
                                ScoreCategoryCard(category: category)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ScoreCategoryCard(category: category)
                        }
                    }

                    // Reach Score section
                    if !improvements.isEmpty && targetScore > score {
                        reachScoreSection
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .preferredColorScheme(settings.colorScheme)
        .fullScreenCover(isPresented: $showExpenseAnalysis) {
            ExpenseAnalysisView(
                viewModel: viewModel,
                property: property,
                onDismiss: { showExpenseAnalysis = false }
            )
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: $showRevenueInsights) {
            RevenueInsightsView(
                viewModel: viewModel,
                property: property,
                onDismiss: { showRevenueInsights = false }
            )
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: $showCalendar) {
            CalendarView(
                preselectedProperty: property,
                onDismiss: { showCalendar = false }
            )
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
    }

    // MARK: - Header and Hero

    private var headerAndHeroSection: some View {
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                VStack(spacing: 1) {
                    Text("Smart Score")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(property.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Color.clear.frame(width: 28)
            }
            .padding(.horizontal, 16)
            .padding(.top, 54) // Status bar + notch
            .padding(.bottom, 8)

            // Score Hero - compact
            VStack(spacing: 6) {
                // Score ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.15), lineWidth: 6)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: animatedScore / 100)
                        .stroke(
                            Color(hex: "2DD4A8"),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(animatedScore))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("out of 100")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                // Score info
                VStack(spacing: 1) {
                    HStack(spacing: 3) {
                        Text("↑")
                            .font(.system(size: 9))
                        Text("5 points this week")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "2DD4A8"))

                    Text("Top 15% of \(property.city ?? "local") properties")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 14)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                    animatedScore = Double(score)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Reach Score Section

    private var reachScoreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reach Score \(targetScore)")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            ForEach(Array(improvements.enumerated()), id: \.element.id) { index, improvement in
                ImprovementCard(index: index + 1, improvement: improvement)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Score Category Card

private struct ScoreCategoryCard: View {
    let category: ScoreCategory

    var body: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: 4) {
                HStack {
                    HStack(spacing: 8) {
                        Text(category.icon)
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)
                            Text(category.subtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(category.score)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(category.isWarning ? AppColors.warning : AppColors.teal600)
                        Text("/\(category.maxScore)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.border)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(category.color)
                            .frame(width: geo.size.width * category.progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(14)

            // Tip banner (if present)
            if let tip = category.tip {
                HStack(spacing: 6) {
                    Text("💡")
                        .font(.system(size: 14))
                    Text(tip)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "065F46"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.tintedGreen)
            }
        }
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(category.borderColor)
                .frame(width: 4)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Improvement Card

private struct ImprovementCard: View {
    let index: Int
    let improvement: ScoreImprovement

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Number badge
            Text("\(index)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "10B981"))
                .frame(width: 24, height: 24)
                .background(AppColors.tintedGreen)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(improvement.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text("Impact: +\(improvement.impact) points")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()
        }
        .padding(12)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let vm = InsightsViewModel(context: context)
    let property = PropertyEntity(context: context)
    property.id = UUID()
    property.name = "Beach Studio"
    property.city = "Miami Beach"
    property.nightlyRate = 185

    return SmartScoreView(viewModel: vm, property: property) {}
}
