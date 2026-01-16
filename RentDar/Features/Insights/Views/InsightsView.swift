import SwiftUI

struct InsightsView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var viewModel: InsightsViewModel?
    @State private var selectedProperty: PropertyEntity?
    private let settings = AppSettings.shared

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.hasProperties {
                    InsightsContentView(viewModel: vm, selectedProperty: $selectedProperty)
                } else {
                    InsightsEmptyView()
                }
            } else {
                Color.clear.onAppear {
                    viewModel = InsightsViewModel(context: context)
                }
            }
        }
        .fullScreenCover(item: $selectedProperty) { property in
            if let vm = viewModel {
                PropertyInsightsView(viewModel: vm, property: property) {
                    selectedProperty = nil
                }
                .preferredColorScheme(settings.colorScheme)
                .environment(\.locale, settings.locale)
            }
        }
        .onAppear {
            viewModel?.fetchData()
        }
    }
}

// MARK: - Content View

private struct InsightsContentView: View {
    let viewModel: InsightsViewModel
    @Binding var selectedProperty: PropertyEntity?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Teal gradient header
                    headerSection

                    // Main content
                    VStack(spacing: 24) {
                        quickStatsSection
                        propertiesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }

            // Footer
            onDeviceBadge
        }
        .background(AppColors.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            // Gradient header
            VStack(alignment: .leading, spacing: 0) {
                // Top row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Insights")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("\(viewModel.properties.count) properties")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    aiBadge
                }
                .padding(.bottom, 20)

                // Portfolio Health Score card
                portfolioScoreCard
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
    }

    private var aiBadge: some View {
        HStack(spacing: 6) {
            Text("✨")
                .font(.system(size: 12))
            Text("AI Powered")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var portfolioScoreCard: some View {
        HStack(spacing: 16) {
            // Circular score
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.portfolioHealthScore) / 100)
                    .stroke(Color(hex: "10B981"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(viewModel.portfolioHealthScore)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("AVG")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                        .tracking(0.5)
                }
            }
            .frame(width: 100, height: 100)
            .background(
                Circle()
                    .fill(.white)
            )

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text("Portfolio Health")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Average score across all properties. Higher is better!")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(2)

                HStack(spacing: 4) {
                    Text("↑")
                        .font(.system(size: 10))
                    Text("+\(viewModel.scoreTrend) pts this month")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "10B981"))
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
        HStack(spacing: 12) {
            InsightStatCard(
                icon: "💰",
                value: viewModel.formattedTotalRevenue,
                label: "Total Revenue",
                trend: viewModel.revenueTrend
            )
            InsightStatCard(
                icon: "📉",
                value: viewModel.formattedTotalExpenses,
                label: "Total Expenses",
                trend: viewModel.expensesTrend
            )
            InsightStatCard(
                icon: "📅",
                value: "\(viewModel.avgOccupancy)%",
                label: "Avg Occupancy",
                trend: viewModel.occupancyTrend
            )
        }
        .padding(.top, -12)
    }

    // MARK: - Properties Section

    private var propertiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Properties")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            ForEach(viewModel.propertyInsights) { insight in
                PropertyInsightCard(insight: insight) {
                    selectedProperty = insight.property
                }
            }

            // Ask AI button
            askAIButton
                .padding(.top, 8)
        }
    }

    private var askAIButton: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Text("✨")
                    .font(.system(size: 16))
                Text("Ask AI about your portfolio")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "0D9488").opacity(0.3), radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Footer

    private var onDeviceBadge: some View {
        HStack(spacing: 6) {
            Text("✓")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "10B981"))
            Text("All insights processed on-device")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Insight Stat Card

private struct InsightStatCard: View {
    let icon: String
    let value: String
    let label: String
    let trend: Int

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
                Text("\(trend)%")
                    .font(.system(size: 12, weight: .semibold))
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

// MARK: - Property Insight Card

private struct PropertyInsightCard: View {
    let insight: PropertyInsight
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(AppColors.border, lineWidth: 4)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: CGFloat(insight.healthScore) / 100)
                        .stroke(insight.badge.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    Text("\(insight.healthScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(insight.property.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text(insight.badge.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(insight.badge.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(insight.badge.bgColor)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    HStack(spacing: 12) {
                        Label(insight.formattedRevenue, systemImage: "dollarsign.circle")
                        Label("\(insight.occupancy)%", systemImage: "calendar")
                        Label(String(format: "%.1f", insight.rating), systemImage: "star.fill")
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)

                    // Recommendation chip
                    Text(insight.recommendation)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppColors.teal600)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.tintedTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.top, 4)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(16)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InsightsView()
}
