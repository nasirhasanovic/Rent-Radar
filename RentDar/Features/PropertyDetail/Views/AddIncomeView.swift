import SwiftUI

struct AddIncomeView: View {
    let viewModel: PropertyDetailViewModel
    var onDismiss: () -> Void

    @State private var selectedPlatform: IncomePlatform = .airbnb
    @State private var guestName: String = ""
    @State private var checkInDate: Date? = nil
    @State private var checkOutDate: Date? = nil
    @State private var displayedMonth: Date = Date()
    @State private var amount: String = ""
    @State private var notes: String = ""
    @FocusState private var focusedField: Field?

    private let green = Color(hex: "10B981")
    private let teal = Color(hex: "0D9488")

    private enum Field {
        case guestName, amount, notes
    }

    // Compute booked/blocked days from property data
    private var bookedDays: Set<Int> {
        daysInMonthFor(ranges: viewModel.bookedDateRanges.map { ($0.start, $0.end) })
    }

    private var blockedDays: Set<Int> {
        daysInMonthFor(ranges: viewModel.blockedDateRanges.map { ($0.start, $0.end) })
    }

    private func daysInMonthFor(ranges: [(Date, Date)]) -> Set<Int> {
        let cal = Calendar.current
        var days = Set<Int>()
        let monthStart = cal.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = cal.date(from: monthStart),
              let daysInMonth = cal.range(of: .day, in: .month, for: displayedMonth)?.count else {
            return days
        }

        for range in ranges {
            let rangeStart = cal.startOfDay(for: range.0)
            let rangeEnd = cal.startOfDay(for: range.1)

            for day in 1...daysInMonth {
                var comps = monthStart
                comps.day = day
                guard let date = cal.date(from: comps) else { continue }
                let dayStart = cal.startOfDay(for: date)

                if dayStart >= rangeStart && dayStart <= rangeEnd {
                    days.insert(day)
                }
            }
        }
        return days
    }

    private var nights: Int {
        guard let start = checkInDate, let end = checkOutDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                headerRow
                platformSection
                guestNameSection
                calendarSection
                dateSummary
                amountSection
                notesSection
                submitButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(AppColors.elevated)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("\u{1F4B0} Add Income")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.background)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Platform Selector

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PLATFORM")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
                .tracking(0.5)

            FlowLayout(spacing: 8) {
                ForEach(IncomePlatform.allCases, id: \.rawValue) { platform in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPlatform = platform
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(platform.emoji)
                                .font(.system(size: 12))
                            Text(platform.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .foregroundStyle(
                            selectedPlatform == platform
                                ? platform.selectedText
                                : AppColors.textTertiary
                        )
                        .background(
                            selectedPlatform == platform
                                ? platform.selectedBg
                                : AppColors.elevated
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    selectedPlatform == platform
                                        ? platform.selectedBorder
                                        : AppColors.border,
                                    lineWidth: 2
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Guest Name

    private var guestNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GUEST NAME")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
                .tracking(0.5)

            TextField("Enter guest name", text: $guestName)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textPrimary)
                .focused($focusedField, equals: .guestName)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            focusedField == .guestName ? teal : AppColors.border,
                            lineWidth: 2
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SELECT DATES")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
                .tracking(0.5)

            MiniCalendarView(
                displayedMonth: $displayedMonth,
                startDate: $checkInDate,
                endDate: $checkOutDate,
                bookedDays: bookedDays,
                blockedDays: blockedDays
            )
        }
    }

    // MARK: - Date Summary

    @ViewBuilder
    private var dateSummary: some View {
        if checkInDate != nil || checkOutDate != nil {
            HStack(spacing: 10) {
                DateSummaryBox(
                    label: "Check-in",
                    value: checkInDate.map { formatShort($0) } ?? "—"
                )
                DateSummaryBox(
                    label: "Check-out",
                    value: checkOutDate.map { formatShort($0) } ?? "—"
                )
                if nights > 0 {
                    HStack(spacing: 4) {
                        Text("\u{1F319}")
                            .font(.system(size: 12))
                        Text("\(nights) nights")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                }
            }
        }
    }

    // MARK: - Amount

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AMOUNT RECEIVED")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
                .tracking(0.5)

            HStack(spacing: 4) {
                Text(AppSettings.shared.currencySymbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(green)

                TextField("0.00", text: $amount)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(green)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        focusedField == .amount ? teal : AppColors.border,
                        lineWidth: 2
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES (OPTIONAL)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
                .tracking(0.5)

            TextField("Add notes...", text: $notes)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textPrimary)
                .focused($focusedField, equals: .notes)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            focusedField == .notes ? teal : AppColors.border,
                            lineWidth: 2
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            guard let parsedAmount = Double(amount), parsedAmount > 0,
                  let start = checkInDate, let end = checkOutDate else {
                onDismiss()
                return
            }
            viewModel.addIncome(
                guestName: guestName,
                platform: selectedPlatform,
                checkIn: start,
                checkOut: end,
                nights: nights,
                amount: parsedAmount,
                notes: notes
            )
            onDismiss()
        } label: {
            Text("Add Income")
                .font(.system(size: 16, weight: .semibold))
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
        }
        .padding(.top, 8)
    }

    private func formatShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Date Summary Box

private struct DateSummaryBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textTertiary)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "0D9488"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.tintedTeal)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.teal300, lineWidth: 2)
        )
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
