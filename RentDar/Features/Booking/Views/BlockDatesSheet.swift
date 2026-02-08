import SwiftUI

enum BlockReason: String, CaseIterable {
    case personal = "Personal use"
    case maintenance = "Maintenance"
    case renovation = "Renovation"
    case other = "Other"

    var displayName: String {
        switch self {
        case .personal: return String(localized: "Personal use")
        case .maintenance: return String(localized: "Maintenance")
        case .renovation: return String(localized: "Renovation")
        case .other: return String(localized: "Other")
        }
    }

    var emoji: String {
        switch self {
        case .personal: return "🏠"
        case .maintenance: return "🔧"
        case .renovation: return "🏗️"
        case .other: return "📝"
        }
    }
}

struct BlockDatesSheet: View {
    let property: PropertyEntity?
    let existingBlockedRanges: [(start: Date, end: Date)]
    let existingBookedRanges: [(start: Date, end: Date, platform: String?)]
    let onBlock: (Date, Date, BlockReason, String) -> Void
    let onDismiss: () -> Void

    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil
    @State private var displayedMonth: Date = Date()
    @State private var selectedReason: BlockReason = .personal
    @State private var notes: String = ""

    private let calendar = Calendar.current

    init(
        property: PropertyEntity?,
        existingBlockedRanges: [(start: Date, end: Date)],
        existingBookedRanges: [(start: Date, end: Date, platform: String?)] = [],
        onBlock: @escaping (Date, Date, BlockReason, String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.property = property
        self.existingBlockedRanges = existingBlockedRanges
        self.existingBookedRanges = existingBookedRanges
        self.onBlock = onBlock
        self.onDismiss = onDismiss
    }

    private var nights: Int {
        guard let start = startDate, let end = endDate else { return 0 }
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(0, days)
    }

    // Convert date ranges to day sets for the current displayed month
    private var blockedDays: Set<Int> {
        daysInMonthFor(ranges: existingBlockedRanges.map { ($0.start, $0.end) })
    }

    private var bookedDays: Set<Int> {
        daysInMonthFor(ranges: existingBookedRanges.map { ($0.start, $0.end) })
    }

    private func daysInMonthFor(ranges: [(Date, Date)]) -> Set<Int> {
        var days = Set<Int>()
        let monthStart = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: monthStart),
              let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count else {
            return days
        }

        for range in ranges {
            let rangeStart = calendar.startOfDay(for: range.0)
            let rangeEnd = calendar.startOfDay(for: range.1)

            for day in 1...daysInMonth {
                var comps = monthStart
                comps.day = day
                guard let date = calendar.date(from: comps) else { continue }
                let dayStart = calendar.startOfDay(for: date)

                if dayStart >= rangeStart && dayStart <= rangeEnd {
                    days.insert(day)
                }
            }
        }
        return days
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "D1D5DB"))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 6)

            // Header
            headerRow
                .padding(.horizontal, 24)
                .padding(.bottom, 18)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Calendar using shared component
                    MiniCalendarView(
                        displayedMonth: $displayedMonth,
                        startDate: $startDate,
                        endDate: $endDate,
                        bookedDays: bookedDays,
                        blockedDays: blockedDays
                    )
                    .padding(.horizontal, 20)

                    // Date summary
                    if startDate != nil || endDate != nil {
                        dateSummaryRow
                            .padding(.horizontal, 24)
                    }

                    // Reason section
                    reasonSection
                        .padding(.horizontal, 24)

                    // Notes
                    notesSection
                        .padding(.horizontal, 24)

                    // Block button
                    blockButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
            }
        }
        .background(AppColors.elevated)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            HStack(spacing: 10) {
                Text("🚫")
                    .font(.system(size: 22))
                Text("Block Dates")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .frame(width: 36, height: 36)
                    .background(AppColors.surface)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Date Summary Row

    private var dateSummaryRow: some View {
        HStack(spacing: 10) {
            // Start
            VStack(spacing: 2) {
                Text("Start")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textTertiary)
                Text(startDate.map { formatDateShort($0) } ?? "—")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.teal600)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AppColors.tintedTeal)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "99F6E4"), lineWidth: 1.5)
            )

            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textTertiary)

            // End
            VStack(spacing: 2) {
                Text("End")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.textTertiary)
                Text(endDate.map { formatDateShort($0) } ?? "—")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "0F766E"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(AppColors.tintedTeal)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "99F6E4"), lineWidth: 1.5)
            )

            // Nights badge
            VStack(spacing: 0) {
                Text("\(nights)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text("nights")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Reason Section

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reason")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    reasonChip(.personal)
                    reasonChip(.maintenance)
                }
                HStack(spacing: 8) {
                    reasonChip(.renovation)
                    reasonChip(.other)
                }
            }
        }
    }

    private func reasonChip(_ reason: BlockReason) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedReason = reason
            }
        } label: {
            HStack(spacing: 6) {
                Text(reason.emoji)
                    .font(.system(size: 14))
                Text(reason.displayName)
                    .font(.system(size: 13, weight: selectedReason == reason ? .semibold : .medium))
                    .foregroundStyle(selectedReason == reason ? .white : AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selectedReason == reason ? Color(hex: "0F766E") : AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                selectedReason == reason
                    ? nil
                    : RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (optional)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            TextField("Add notes...", text: $notes, axis: .vertical)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2...4)
                .padding(14)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.border, lineWidth: 1.5)
                )
        }
    }

    // MARK: - Block Button

    private var blockButton: some View {
        Button {
            guard let start = startDate, let end = endDate else { return }
            onBlock(start, end, selectedReason, notes)
        } label: {
            HStack(spacing: 8) {
                Text("🚫")
                    .font(.system(size: 18))
                Text("Block These Dates")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [AppColors.teal600, Color(hex: "0F766E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: AppColors.teal600.opacity(0.3), radius: 12, y: 4)
        }
        .disabled(nights == 0)
        .opacity(nights > 0 ? 1 : 0.6)
    }

    // MARK: - Helpers

    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
