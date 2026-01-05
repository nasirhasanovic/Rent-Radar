import SwiftUI

struct PropertyOverviewTab: View {
    let viewModel: PropertyDetailViewModel
    private let green = Color(hex: "10B981")

    var body: some View {
        Group {
            if viewModel.allTransactions.isEmpty {
                overviewEmptyState
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    statCardsRow
                        .padding(.horizontal, 16)
                    occupancySection
                        .padding(.horizontal, 16)
                    quickActionsRow
                        .padding(.horizontal, 16)

                    // Show connected platforms or connect card
                    if viewModel.hasConnectedPlatforms {
                        connectedPlatformsCard
                            .padding(.horizontal, 16)
                    } else {
                        connectPlatformCard
                            .padding(.horizontal, 16)
                    }

                    nextCheckInSection
                    quickInsightsRow
                        .padding(.horizontal, 16)
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: Bindable(viewModel).showAddExpense) {
            AddExpenseView(viewModel: viewModel, onDismiss: { viewModel.showAddExpense = false })
        }
        .sheet(isPresented: Bindable(viewModel).showAddIncome) {
            AddIncomeView(viewModel: viewModel, onDismiss: { viewModel.showAddIncome = false })
        }
        .sheet(isPresented: Bindable(viewModel).showBlockDates) {
            BlockDatesSheet(
                property: viewModel.property,
                existingBlockedRanges: viewModel.blockedDateRanges,
                existingBookedRanges: viewModel.bookedDateRanges,
                onBlock: { start, end, reason, notes in
                    viewModel.addBlockedDates(start: start, end: end, reason: reason, notes: notes)
                    viewModel.showBlockDates = false
                },
                onDismiss: { viewModel.showBlockDates = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Empty State

    private var overviewEmptyState: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F0FDFA"), Color(hex: "CCFBF1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text("\u{1F4CA}")
                            .font(.system(size: 52))
                    )
            }

            Spacer().frame(height: 24)

            Text("No activity yet")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Spacer().frame(height: 12)

            Text("Add bookings and transactions to see\nyour property stats, occupancy rate,\nand performance.")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: 28)

            // Quick action buttons row
            HStack(spacing: 12) {
                Button { viewModel.showAddIncome = true } label: {
                    HStack(spacing: 6) {
                        Text("+")
                            .font(.system(size: 14, weight: .bold))
                        Text("Add Booking")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button { viewModel.showConnectPlatform = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Connect")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(AppColors.teal600)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.teal300, lineWidth: 1.5)
                    )
                }
            }

            Spacer().frame(height: 24)

            // Connect platform card
            connectPlatformCard
                .padding(.horizontal, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stat Cards

    private var statCardsRow: some View {
        HStack(spacing: 8) {
            CompactStatCard(value: viewModel.formattedRevenue, label: "Revenue", valueColor: AppColors.textPrimary)
            CompactStatCard(value: viewModel.formattedExpenses, label: "Expenses", valueColor: AppColors.expense)
            CompactStatCard(value: viewModel.formattedNetProfit, label: "Net Profit", valueColor: Color(hex: "10B981"))
        }
    }

    // MARK: - Occupancy

    private var occupancySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This Month Occupancy")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)

                Spacer()

                Text("\(Int(viewModel.occupancyPercent))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.teal600)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.border)
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0D9488"), Color(hex: "2DD4BF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.occupancyPercent / 100, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 8) {
            QuickActionButton(
                emoji: "\u{1F4C5}", label: "Calendar",
                isPrimary: true,
                action: { viewModel.showCalendar = true }
            )
            QuickActionButton(
                emoji: "\u{1F4B0}", label: "Income",
                isPrimary: false,
                action: { viewModel.showAddIncome = true }
            )
            QuickActionButton(
                emoji: "\u{1F4E4}", label: "Expense",
                isPrimary: false,
                action: { viewModel.showAddExpense = true }
            )
            QuickActionButton(
                emoji: "\u{1F6AB}", label: "Block",
                isPrimary: false,
                action: { viewModel.showBlockDates = true }
            )
        }
    }

    // MARK: - Connect Platform Card

    private var connectPlatformCard: some View {
        Button {
            viewModel.showConnectPlatform = true
        } label: {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.teal500.opacity(0.15), AppColors.teal300.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect Platform")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Sync Airbnb, Booking.com & more")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(14)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .foregroundStyle(AppColors.teal300)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Connected Platforms Card

    private var connectedPlatformsCard: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                    Text("Connected Platforms")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                }

                Spacer()

                Button {
                    viewModel.showPlatformsOverview = true
                } label: {
                    Text("Manage")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                }
            }
            .padding(.bottom, 12)

            // Platform icons row
            HStack(spacing: 10) {
                ForEach(viewModel.connectedPlatforms) { platform in
                    PlatformStatusTile(
                        platform: platform,
                        onTap: {
                            if !platform.isConnected {
                                viewModel.showConnectPlatform = true
                            }
                        }
                    )
                }
            }

            // Sync status footer
            if viewModel.connectedPlatformCount > 0 {
                Divider()
                    .padding(.top, 12)

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: 6, height: 6)
                    Text("All synced · \(viewModel.totalPlatformBookings) bookings across \(viewModel.connectedPlatformCount) platforms")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Next Check-in

    private var nextCheckInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Next Check-in")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button { } label: {
                    Text("View all \u{2192}")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                }
            }
            .padding(.horizontal, 16)

            GuestCheckInCard(booking: viewModel.nextBooking)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Quick Insights

    private var quickInsightsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Insights")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: 10) {
                InsightCard(
                    iconView: AnyView(
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.teal600)
                    ),
                    iconBg: AppColors.tintedTeal,
                    value: "\(AppSettings.shared.currencySymbol)185",
                    label: "Avg. Nightly Rate",
                    changeText: "\u{2191} 8%",
                    isPositive: true
                )
                InsightCard(
                    iconView: AnyView(
                        Image("star_rating")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    ),
                    iconBg: AppColors.tintedYellow,
                    value: "4.92",
                    label: "Guest Rating",
                    changeText: "\u{2191} 0.1",
                    isPositive: true
                )
            }
        }
    }
}

// MARK: - Compact Stat Card

private struct CompactStatCard: View {
    let value: String
    let label: String
    var valueColor: Color = AppColors.textPrimary

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(valueColor)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let emoji: String
    let label: String
    let isPrimary: Bool
    var action: () -> Void = {}

    var body: some View {
        Button { action() } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 14))
                    .frame(width: 32, height: 32)
                    .background(isPrimary ? .white.opacity(0.2) : AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isPrimary ? .white : AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(
                isPrimary
                    ? AnyShapeStyle(LinearGradient(
                        colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    : AnyShapeStyle(AppColors.surface)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                isPrimary
                    ? nil
                    : RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border, lineWidth: 1)
            )
        }
    }
}

// MARK: - Guest Check-in Card

private struct GuestCheckInCard: View {
    let booking: MockBooking

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    // Avatar
                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(booking.guestInitials)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: "F59E0B"))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(booking.guestName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "92400E"))

                        Text("via \(booking.source.rawValue) \u{2022} \(booking.nights) nights")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "B45309"))
                    }
                }

                HStack(spacing: 12) {
                    Text("\u{1F4C5} \(booking.dateRangeString)")
                        .font(.system(size: 11))
                    Text("\u{1F465} \(booking.guests) guests")
                        .font(.system(size: 11))
                    Text("\u{1F4B5} \(AppSettings.shared.currencySymbol)\(Int(booking.amount))")
                        .font(.system(size: 11))
                }
                .foregroundStyle(Color(hex: "92400E"))
            }
            .padding(14)

            // Badge
            Text(booking.badgeText)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color(hex: "F59E0B"))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "FEF3C7"), Color(hex: "FDE68A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Insight Card

private struct InsightCard: View {
    let iconView: AnyView
    let iconBg: Color
    let value: String
    let label: String
    let changeText: String
    let isPositive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            iconView
                .frame(width: 28, height: 28)
                .background(iconBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textTertiary)

            Text(changeText)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isPositive ? Color(hex: "10B981") : AppColors.expense)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isPositive ? AppColors.tintedGreen : AppColors.tintedRed)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Platform Status Tile

private struct PlatformStatusTile: View {
    let platform: PropertyDetailViewModel.ConnectedPlatform
    let onTap: () -> Void

    private var iconBgColor: Color {
        switch platform.name.lowercased() {
        case "airbnb": return Color(hex: "FFF1F0")
        case "booking": return Color(hex: "E8F0FE")
        case "vrbo": return Color(hex: "EDE9FE")
        case "direct": return Color(hex: "F0FDFA")
        default: return Color(hex: "F3F4F6")
        }
    }

    private var iconColor: Color {
        switch platform.name.lowercased() {
        case "airbnb": return Color(hex: "FF5A5F")
        case "booking": return Color(hex: "003580")
        case "vrbo": return Color(hex: "8B5CF6")
        case "direct": return AppColors.teal600
        default: return Color(hex: "9CA3AF")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Icon with status indicator
                ZStack(alignment: .bottomTrailing) {
                    platformIcon

                    if platform.isConnected {
                        Circle()
                            .fill(Color(hex: "10B981"))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 1.5)
                            )
                            .offset(x: 2, y: 2)
                    }
                }

                // Platform name
                Text(platform.name)
                    .font(.system(size: 9, weight: platform.isConnected ? .semibold : .medium))
                    .foregroundStyle(platform.isConnected ? AppColors.textPrimary : AppColors.textTertiary)

                // Status text
                if platform.isConnected {
                    if platform.bookingCount > 0 {
                        Text("\(platform.bookingCount) bookings")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(AppColors.teal600)
                    } else {
                        Text(platform.lastSyncText)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(Color(hex: "10B981"))
                    }
                } else {
                    Text("Connect")
                        .font(.system(size: 8))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(platform.isConnected ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var platformIcon: some View {
        switch platform.name.lowercased() {
        case "airbnb":
            Image("airbnb_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .saturation(platform.isConnected ? 1 : 0)
                .opacity(platform.isConnected ? 1 : 0.4)
        case "booking":
            Image("booking_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .saturation(platform.isConnected ? 1 : 0)
                .opacity(platform.isConnected ? 1 : 0.4)
        case "vrbo":
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(platform.isConnected ? iconBgColor : Color(hex: "F3F4F6"))
                    .frame(width: 28, height: 28)
                Text("V")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(platform.isConnected ? iconColor : Color(hex: "D1D5DB"))
            }
        case "direct":
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(platform.isConnected ? iconBgColor : Color(hex: "F3F4F6"))
                    .frame(width: 28, height: 28)
                Image(systemName: "house.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(platform.isConnected ? iconColor : Color(hex: "D1D5DB"))
            }
        default:
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "F3F4F6"))
                    .frame(width: 28, height: 28)
                Image(systemName: "link")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "D1D5DB"))
            }
        }
    }
}
