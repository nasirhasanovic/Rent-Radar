import SwiftUI

struct BookedDateRange: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let platform: String?
    let guestName: String?
}

struct BlockedDateRange: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let reason: String?
}

struct DateRangePickerSheet: View {
    @Binding var checkInDate: Date
    @Binding var checkOutDate: Date
    let bookedRanges: [BookedDateRange]
    let blockedRanges: [BlockedDateRange]
    let onConfirm: () -> Void

    @State private var displayedMonth: Date
    @State private var selectingCheckOut: Bool = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    init(
        checkInDate: Binding<Date>,
        checkOutDate: Binding<Date>,
        bookedRanges: [BookedDateRange] = [],
        blockedRanges: [BlockedDateRange] = [],
        onConfirm: @escaping () -> Void
    ) {
        self._checkInDate = checkInDate
        self._checkOutDate = checkOutDate
        self.bookedRanges = bookedRanges
        self.blockedRanges = blockedRanges
        self.onConfirm = onConfirm
        self._displayedMonth = State(initialValue: checkInDate.wrappedValue)
    }

    private var nights: Int {
        let days = calendar.dateComponents([.day], from: checkInDate, to: checkOutDate).day ?? 0
        return max(0, days)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    private var firstWeekdayOffset: Int {
        let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = calendar.date(from: comps) else { return 0 }
        return (calendar.component(.weekday, from: firstDay) - 1)
    }

    private var todayDay: Int? {
        let now = Date()
        guard calendar.isDate(displayedMonth, equalTo: now, toGranularity: .month) else { return nil }
        return calendar.component(.day, from: now)
    }

    private var hasConflict: Bool {
        // Check if selected range overlaps with any booked or blocked dates
        for day in 0..<nights {
            guard let date = calendar.date(byAdding: .day, value: day, to: checkInDate) else { continue }
            if isDateBooked(date) || isDateBlocked(date) {
                return true
            }
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "E5E7EB"))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Month navigation
            monthNavigationRow
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            // Weekday headers
            weekdayHeadersRow
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            // Date grid
            dateGrid
                .padding(.horizontal, 16)

            // Legend
            legendRow
                .padding(.top, 14)
                .padding(.horizontal, 24)

            // Confirm button
            confirmButton
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
        }
        .background(AppColors.elevated)
    }

    // MARK: - Month Navigation

    private var monthNavigationRow: some View {
        HStack {
            Button {
                shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()

            Text(monthTitle)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button {
                shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeadersRow: some View {
        LazyVGrid(columns: columns, spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(height: 28)
            }
        }
    }

    // MARK: - Date Grid

    private var dateGrid: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            // Empty cells for offset
            ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                Color.clear.frame(height: 44)
            }

            // Day cells
            ForEach(1...daysInMonth, id: \.self) { day in
                dayCell(day: day)
            }
        }
    }

    private func dayCell(day: Int) -> some View {
        let date = dateForDay(day)
        let isCheckIn = calendar.isDate(date, inSameDayAs: checkInDate)
        let isCheckOut = calendar.isDate(date, inSameDayAs: checkOutDate)
        let isInRange = date > checkInDate && date < checkOutDate
        let isToday = todayDay == day
        let isPast = date < calendar.startOfDay(for: Date())
        let isBooked = isDateBooked(date)
        let isBlocked = isDateBlocked(date)
        let isUnavailable = isBooked || isBlocked || isPast

        return Button {
            if !isUnavailable {
                selectDate(day)
            }
        } label: {
            ZStack {
                // Range background for selection
                if isInRange && !isBooked && !isBlocked {
                    Rectangle()
                        .fill(AppColors.tintedTeal)
                }

                // Booked range background
                if isBooked {
                    Rectangle()
                        .fill(AppColors.tintedRed)
                }

                // Blocked range background
                if isBlocked {
                    Rectangle()
                        .fill(Color(hex: "E5E7EB"))
                }

                // Check-in circle (only if not conflicting)
                if isCheckIn && !isBooked && !isBlocked {
                    Circle()
                        .fill(AppColors.teal600)
                        .frame(width: 38, height: 38)
                }

                // Check-out circle (only if not conflicting)
                if isCheckOut && !isBooked && !isBlocked {
                    Circle()
                        .fill(Color(hex: "2DD4A8"))
                        .frame(width: 38, height: 38)
                }

                // Booked indicator circle
                if isBooked {
                    Circle()
                        .fill(AppColors.error)
                        .frame(width: 38, height: 38)
                }

                // Blocked indicator circle
                if isBlocked {
                    Circle()
                        .fill(Color(hex: "6B7280"))
                        .frame(width: 38, height: 38)
                }

                // Day number and indicators
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.system(size: 14, weight: (isCheckIn || isCheckOut || isBooked || isBlocked) ? .bold : (isInRange ? .semibold : .medium)))
                        .foregroundStyle(dayTextColor(isCheckIn: isCheckIn, isCheckOut: isCheckOut, isInRange: isInRange, isPast: isPast, isBooked: isBooked, isBlocked: isBlocked))

                    // Today indicator
                    if isToday && !isCheckIn && !isCheckOut && !isBooked && !isBlocked {
                        Circle()
                            .fill(AppColors.teal600)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .disabled(isUnavailable)
    }

    private func dayTextColor(isCheckIn: Bool, isCheckOut: Bool, isInRange: Bool, isPast: Bool, isBooked: Bool, isBlocked: Bool) -> Color {
        if isBooked || isBlocked || isCheckIn || isCheckOut {
            return .white
        } else if isInRange {
            return AppColors.teal600
        } else if isPast {
            return AppColors.textTertiary
        } else {
            return AppColors.textPrimary
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 12) {
            legendItem(color: AppColors.teal600, text: "Check-in")
            legendItem(color: Color(hex: "2DD4A8"), text: "Check-out")
            legendItem(color: AppColors.error, text: "Booked")
            legendItem(color: Color(hex: "6B7280"), text: "Blocked")
        }
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button(action: onConfirm) {
            HStack(spacing: 8) {
                Text("Confirm")
                    .font(.system(size: 15, weight: .bold))
                Text("·")
                Text("\(formatDateShort(checkInDate)) – \(formatDateShort(checkOutDate))")
                    .font(.system(size: 15, weight: .semibold))
                Text("·")
                Text("\(nights) nights")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: hasConflict ? [Color(hex: "9CA3AF"), Color(hex: "6B7280")] : [AppColors.teal600, Color(hex: "0D7C6E")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: hasConflict ? .clear : AppColors.teal600.opacity(0.3), radius: 12, y: 4)
        }
        .disabled(hasConflict || nights == 0)
    }

    // MARK: - Helpers

    private func shiftMonth(_ delta: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonth = newMonth
        }
    }

    private func dateForDay(_ day: Int) -> Date {
        var comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        comps.day = day
        return calendar.date(from: comps) ?? displayedMonth
    }

    private func selectDate(_ day: Int) {
        let date = dateForDay(day)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if !selectingCheckOut || date < checkInDate {
                // First selection or reset: set check-in
                checkInDate = date
                // Find next available date for checkout
                var nextDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
                while isDateBooked(nextDate) || isDateBlocked(nextDate) {
                    guard let next = calendar.date(byAdding: .day, value: 1, to: nextDate) else { break }
                    nextDate = next
                }
                checkOutDate = nextDate
                selectingCheckOut = true
            } else {
                // Second selection: set check-out
                checkOutDate = date
                selectingCheckOut = false
            }
        }
    }

    private func isDateBooked(_ date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        for range in bookedRanges {
            let rangeStart = calendar.startOfDay(for: range.start)
            let rangeEnd = calendar.startOfDay(for: range.end)
            if dayStart >= rangeStart && dayStart < rangeEnd {
                return true
            }
        }
        return false
    }

    private func isDateBlocked(_ date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        for range in blockedRanges {
            let rangeStart = calendar.startOfDay(for: range.start)
            let rangeEnd = calendar.startOfDay(for: range.end)
            if dayStart >= rangeStart && dayStart <= rangeEnd {
                return true
            }
        }
        return false
    }

    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
