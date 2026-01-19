import SwiftUI
import CoreData

// MARK: - Smart Action Model

struct SmartAction: Identifiable {
    let id = UUID()
    let priority: ActionPriority
    let title: String
    let description: String
    let impact: String
    let impactType: ImpactType
    let priceComparison: PriceComparison?
}

enum ActionPriority: String {
    case high = "HIGH"
    case medium = "MEDIUM"
    case growth = "GROWTH"

    var color: Color {
        switch self {
        case .high: return AppColors.error
        case .medium: return AppColors.warning
        case .growth: return AppColors.info
        }
    }

    var bgColor: Color {
        switch self {
        case .high: return AppColors.tintedRed
        case .medium: return AppColors.tintedYellow
        case .growth: return AppColors.tintedBlue
        }
    }

    var textColor: Color {
        switch self {
        case .high: return AppColors.error
        case .medium: return Color(hex: "92400E")
        case .growth: return Color(hex: "1E40AF")
        }
    }
}

enum ImpactType {
    case revenue, savings
}

struct PriceComparison {
    let current: Int
    let recommended: Int
    let peak: Int
}

enum ActionFilter: String, CaseIterable {
    case all = "All"
    case revenue = "Revenue"
    case savings = "Savings"
    case growth = "Growth"
}

// MARK: - Smart Actions View

struct SmartActionsView: View {
    let viewModel: InsightsViewModel
    let property: PropertyEntity
    var onDismiss: () -> Void

    @State private var selectedFilter: ActionFilter = .all
    @State private var aiEnabled: Bool = true
    private let settings = AppSettings.shared

    private var recommendations: [AIRecommendation] {
        viewModel.getRecommendations(for: property)
    }

    private var hasData: Bool {
        // Check if property has enough data for recommendations
        // For now, use recommendations.isEmpty as the condition
        !recommendations.isEmpty
    }

    private var allActions: [SmartAction] {
        // Convert AI recommendations to Smart Actions with additional context
        var actions: [SmartAction] = []

        for rec in recommendations {
            let priority: ActionPriority
            let impactType: ImpactType
            var priceComparison: PriceComparison? = nil

            // Determine priority based on category
            switch rec.category {
            case "Revenue":
                priority = .high
                impactType = .revenue
                // Add price comparison for revenue recommendations
                let currentRate = Int(property.nightlyRate)
                let suggestedRate = currentRate + 25
                let peakRate = currentRate + 40
                priceComparison = PriceComparison(current: currentRate, recommended: suggestedRate, peak: peakRate)
            case "Occupancy":
                priority = .medium
                impactType = .revenue
            case "Expenses":
                priority = .medium
                impactType = .savings
            case "Platform":
                priority = .growth
                impactType = .savings
            default:
                priority = .medium
                impactType = .revenue
            }

            actions.append(SmartAction(
                priority: priority,
                title: rec.title,
                description: rec.description,
                impact: rec.impact,
                impactType: impactType,
                priceComparison: priceComparison
            ))
        }

        // Add additional actionable recommendations
        actions.append(SmartAction(
            priority: .medium,
            title: "Update Listing Photos",
            description: "Properties with refreshed photos see 15% more views. Keep your listing fresh.",
            impact: "+\(settings.currencySymbol)320",
            impactType: .revenue,
            priceComparison: nil
        ))

        return actions
    }

    private var actions: [SmartAction] {
        switch selectedFilter {
        case .all: return allActions
        case .revenue: return allActions.filter { $0.impactType == .revenue }
        case .savings: return allActions.filter { $0.impactType == .savings }
        case .growth: return allActions.filter { $0.priority == .growth }
        }
    }

    // Calculate summary stats from actual recommendations
    private var totalPotential: Int {
        allActions.filter { $0.impactType == .revenue }
            .compactMap { extractAmount(from: $0.impact) }
            .reduce(0, +)
    }

    private var totalSavings: Int {
        allActions.filter { $0.impactType == .savings }
            .compactMap { extractAmount(from: $0.impact) }
            .reduce(0, +)
    }

    private var scorePoints: Int {
        // Estimate score improvement: +2 per recommendation implemented
        allActions.count * 2
    }

    private func extractAmount(from impact: String) -> Int? {
        // Extract numeric value from strings like "+$200/mo" or "Save $40/mo"
        let pattern = "[0-9]+"
        if let range = impact.range(of: pattern, options: .regularExpression) {
            return Int(impact[range])
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header gradient section
            headerSection

            if hasData && aiEnabled {
                // Filter tabs
                filterTabs

                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(actions) { action in
                            ActionCard(action: action)
                        }

                        // Privacy footer
                        privacyFooter
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
            } else {
                // Empty state
                emptyStateView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            }
        }
        .background(AppColors.background)
        .preferredColorScheme(settings.colorScheme)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top bar with back button
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("←")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Actions")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text(aiEnabled && hasData ? "\(actions.count) recommendations this week" : "AI-powered insights")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                // AI Toggle Button
                AIToggleButton(isEnabled: $aiEnabled)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Summary pills (only show when AI is enabled and has data)
            if aiEnabled && hasData {
                HStack(spacing: 10) {
                    SummaryPill(
                        value: "+\(settings.currencySymbol)\(totalPotential.formatted())",
                        label: "Potential",
                        valueColor: Color(hex: "10B981")
                    )
                    SummaryPill(
                        value: "-\(settings.currencySymbol)\(totalSavings)",
                        label: "Savings",
                        valueColor: AppColors.error
                    )
                    SummaryPill(
                        value: "+\(scorePoints)",
                        label: "Score Pts",
                        valueColor: AppColors.info
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
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

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ActionFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AppColors.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.black.opacity(0.06))
                .frame(height: 1)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                // Icon and title
                VStack(spacing: 12) {
                    Text("✨")
                        .font(.system(size: 48))

                    Text("No Recommendations Yet")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(aiEnabled
                         ? "We need more booking data to generate personalized recommendations for this property."
                         : "Enable AI to get personalized recommendations based on your property data.")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Placeholder cards
                VStack(spacing: 12) {
                    PlaceholderActionCard(
                        icon: "💰",
                        title: "Revenue suggestion",
                        description: "Pricing optimization tips"
                    )
                    PlaceholderActionCard(
                        icon: "📉",
                        title: "Expense saving",
                        description: "Cost reduction opportunities"
                    )
                    PlaceholderActionCard(
                        icon: "📈",
                        title: "Growth tip",
                        description: "Ways to improve performance"
                    )
                }
                .padding(.horizontal, 16)

                // Helper text
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Typically ready after 30 days of data")
                        .font(.system(size: 12))
                }
                .foregroundStyle(AppColors.textTertiary)

                // Privacy footer
                privacyFooter

                Spacer().frame(height: 100)
            }
        }
    }

    // MARK: - Privacy Footer

    private var privacyFooter: some View {
        HStack(spacing: 6) {
            Text("✓")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "10B981"))
            Text("All insights processed on-device")
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Summary Pill

private struct SummaryPill: View {
    let value: String
    let label: String
    let valueColor: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(valueColor)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Filter Pill

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? .white : AppColors.textTertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? AppColors.teal600 : AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : AppColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Action Card

private struct ActionCard: View {
    let action: SmartAction

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    // Priority badge + title
                    HStack(spacing: 6) {
                        Text(action.priority.rawValue)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(action.priority.textColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(action.priority.bgColor)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text(action.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }

                Spacer()

                // Impact badge
                Text(action.impact)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "10B981"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.tintedGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Description
            Text(action.description)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
                .lineSpacing(2)

            // Price comparison (if available)
            if let comparison = action.priceComparison {
                PriceComparisonRow(comparison: comparison)
            }
        }
        .padding(14)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(action.priority.color)
                .frame(width: 4)
        }
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Price Comparison Row

private struct PriceComparisonRow: View {
    let comparison: PriceComparison

    var body: some View {
        HStack(spacing: 10) {
            PriceBox(label: "Current", value: comparison.current)
            PriceBox(label: "Recommended", value: comparison.recommended)
            PriceBox(label: "Peak", value: comparison.peak)
        }
        .padding(.top, 4)
    }
}

private struct PriceBox: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textTertiary)
            Text("\(AppSettings.shared.currencySymbol)\(value)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
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

// MARK: - Placeholder Action Card (Empty State)

private struct PlaceholderActionCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle
            Text(icon)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(AppColors.surface)
                .clipShape(Circle())

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary.opacity(0.7))
            }

            Spacer()
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundStyle(AppColors.border)
        )
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let vm = InsightsViewModel(context: context)
    let property = PropertyEntity(context: context)
    property.id = UUID()
    property.name = "Beach Studio"
    property.nightlyRate = 185

    return SmartActionsView(
        viewModel: vm,
        property: property,
        onDismiss: {}
    )
}
