import SwiftUI
import CoreData

struct PropertyInsightsView: View {
    let viewModel: InsightsViewModel
    let property: PropertyEntity
    var onDismiss: () -> Void

    @State private var showSmartActions = false
    @State private var showSmartScore = false
    private let settings = AppSettings.shared

    private var insight: PropertyInsight? {
        viewModel.propertyInsights.first { $0.property.id == property.id }
    }

    private var recommendations: [AIRecommendation] {
        viewModel.getRecommendations(for: property)
    }

    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    // Check if property has enough data for insights
    private var hasEnoughData: Bool {
        guard let insight = insight else { return false }
        // Consider having enough data if there's revenue or occupancy data
        return insight.revenue > 0 || insight.occupancy > 0
    }

    // Calculate data collection progress (0-100)
    private var dataCollectionProgress: Int {
        var progress = 0
        // Property added = +33%
        progress += 33
        // Has any income = +33%
        if let insight = insight, insight.revenue > 0 {
            progress += 33
        }
        // Has enough history (mock check) = +34%
        if let insight = insight, insight.healthScore > 0 {
            progress += 34
        }
        return min(100, progress)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Teal gradient header
                    headerSection

                    // Main content
                    if hasEnoughData {
                        VStack(spacing: 24) {
                            quickStatsSection
                            recommendationsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    } else {
                        dashboardEmptyState
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                    }
                }
            }

            // Footer
            onDeviceBadge
        }
        .background(AppColors.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .fullScreenCover(isPresented: $showSmartActions) {
            SmartActionsView(viewModel: viewModel, property: property) {
                showSmartActions = false
            }
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
        .fullScreenCover(isPresented: $showSmartScore) {
            SmartScoreView(viewModel: viewModel, property: property) {
                showSmartScore = false
            }
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row with back button
            HStack(alignment: .top) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Insights")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(property.displayName) \u{2022} \(currentMonthYear)")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.bottom, 20)

            // Property Health Score card (tappable)
            Button { showSmartScore = true } label: {
                healthScoreCard
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var healthScoreCard: some View {
        let score = insight?.healthScore ?? 0

        return HStack(spacing: 16) {
            // Circular score
            ZStack {
                if hasEnoughData {
                    Circle()
                        .stroke(.white.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100)
                        .stroke(Color(hex: "10B981"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                        Text("SCORE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColors.textTertiary)
                            .tracking(0.5)
                    }
                } else {
                    // Dashed circle for empty state
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 6, dash: [8, 6]))
                        .foregroundStyle(.white.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Text("?")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 100, height: 100)
            .background(
                Circle()
                    .fill(hasEnoughData ? .white : .white.opacity(0.1))
            )

            // Info
            VStack(alignment: .leading, spacing: 6) {
                if hasEnoughData {
                    HStack {
                        Text("Property Health Score")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Text("Strong performance! Revenue is up 12% this month. 2 actions could boost your score to \(min(100, score + 6)).")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(2)

                    HStack(spacing: 4) {
                        Text("↑")
                            .font(.system(size: 10))
                        Text("+5 pts this week")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "10B981"))
                } else {
                    Text("Calculating...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "2DD4A8"))

                    Text("We need about 30 days of data to calculate your property's health score.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineSpacing(2)
                }
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

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        let netProfit = insight?.netProfit ?? 0
        let occupancy = insight?.occupancy ?? 0
        let rating = insight?.rating ?? 4.8

        return HStack(spacing: 12) {
            QuickStatCard(
                icon: "💰",
                value: "\(AppSettings.shared.currencySymbol)\(Int(netProfit).formatted())",
                label: "Net Profit",
                trend: 18
            )
            QuickStatCard(
                icon: "📅",
                value: "\(occupancy)%",
                label: "Occupancy",
                trend: 5
            )
            QuickStatCard(
                icon: "⭐",
                value: String(format: "%.2f", rating),
                label: "Rating",
                trendValue: "+0.1"
            )
        }
        .padding(.top, -12)
    }

    // MARK: - Recommendations Section

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Recommendations")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Button { showSmartActions = true } label: {
                    Text("See all →")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                }
            }

            ForEach(recommendations) { rec in
                RecommendationCard(recommendation: rec)
            }
        }
    }

    // MARK: - Quick Stats Empty

    private var quickStatsEmptySection: some View {
        HStack(spacing: 8) {
            EmptyStatCard(label: "Occupancy")
            EmptyStatCard(label: "Revenue")
            EmptyStatCard(label: "Expenses")
        }
        .padding(.top, -12)
    }

    // MARK: - Dashboard Empty State

    private var dashboardEmptyState: some View {
        VStack(spacing: 16) {
            // Empty quick stats
            quickStatsEmptySection

            // Empty state content
            VStack(spacing: 20) {
                Text("📊")
                    .font(.system(size: 48))

                Text("Your Insights Are Brewing")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("We're collecting data from your bookings, expenses, and guest reviews. First insights in about 2–4 weeks.")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: 280)

                // Progress bar
                VStack(spacing: 6) {
                    HStack {
                        Text("Data Collection")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("\(dataCollectionProgress)%")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.teal600)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppColors.border)
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppColors.teal600)
                                .frame(width: geo.size.width * CGFloat(dataCollectionProgress) / 100, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .frame(width: 280)

                // Checklist
                VStack(alignment: .leading, spacing: 12) {
                    DataChecklistItem(title: String(localized: "Property added"), isCompleted: true)
                    DataChecklistItem(title: String(localized: "First booking recorded"), isCompleted: (insight?.revenue ?? 0) > 0)
                    DataChecklistItem(title: "30 days of data", isCompleted: false)
                }
                .frame(width: 280)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Footer

    private var onDeviceBadge: some View {
        HStack(spacing: 6) {
            Text("✓")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "10B981"))
            Text("All insights processed on-device \u{2022} Your data never leaves your phone")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Quick Stat Card

private struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    var trend: Int? = nil
    var trendValue: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)

            HStack(spacing: 3) {
                Text("↑")
                    .font(.system(size: 10))
                if let trend = trend {
                    Text("\(trend)%")
                        .font(.system(size: 12, weight: .semibold))
                } else if let trendValue = trendValue {
                    Text(trendValue)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundStyle(Color(hex: "10B981"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Recommendation Card

private struct RecommendationCard: View {
    let recommendation: AIRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Icon
                Text(recommendation.icon)
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(recommendation.color.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Title & description
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(recommendation.description)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                        .lineSpacing(2)
                }
            }
            .padding(.bottom, 12)

            // Footer
            HStack {
                HStack(spacing: 8) {
                    // Impact badge
                    Text(recommendation.impact)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(recommendation.color.main)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(recommendation.color.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    // Category tag
                    Text(recommendation.category)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Spacer()

                // Action button
                Button {} label: {
                    Text(recommendation.actionLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                }
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.black.opacity(0.05))
                    .frame(height: 1)
            }
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(recommendation.color.main)
                .frame(width: 3)
                .padding(.vertical, 8)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Empty Stat Card

private struct EmptyStatCard: View {
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("—")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.border)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Data Checklist Item

private struct DataChecklistItem: View {
    let title: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 10) {
            if isCompleted {
                ZStack {
                    Circle()
                        .fill(AppColors.tintedGreen)
                        .frame(width: 22, height: 22)
                    Text("✓")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "10B981"))
                }
            } else {
                Circle()
                    .stroke(AppColors.border, lineWidth: 1.5)
                    .frame(width: 22, height: 22)
            }

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isCompleted ? AppColors.textPrimary : AppColors.textTertiary)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let vm = InsightsViewModel(context: context)
    let property = PropertyEntity(context: context)
    property.id = UUID()
    property.name = "Beach Studio"

    return PropertyInsightsView(viewModel: vm, property: property) {}
}
