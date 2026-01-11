import SwiftUI

struct MiniCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var startDate: Date?
    @Binding var endDate: Date?
    let bookedDays: Set<Int>
    let blockedDays: Set<Int>

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private let cal = Calendar.current

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    private var firstWeekdayOffset: Int {
        let comps = cal.dateComponents([.year, .month], from: displayedMonth)
        let firstDay = cal.date(from: comps)!
        return cal.component(.weekday, from: firstDay) - 1 // Sunday = 0
    }

    private var todayDay: Int? {
        let now = Date()
        if cal.isDate(now, equalTo: displayedMonth, toGranularity: .month) {
            return cal.component(.day, from: now)
        }
        return nil
    }

    private var totalCells: [Int?] {
        var cells: [Int?] = Array(repeating: nil, count: firstWeekdayOffset)
        for d in 1...daysInMonth { cells.append(d) }
        return cells
    }

    var body: some View {
        VStack(spacing: 14) {
            // Month nav
            HStack {
                Text(monthTitle)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                HStack(spacing: 6) {
                    Button {
                        withAnimation { shiftMonth(-1) }
                    } label: {
                        Text("\u{2039}")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: 28, height: 28)
                            .background(AppColors.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Button {
                        withAnimation { shiftMonth(1) }
                    } label: {
                        Text("\u{203A}")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(AppColors.textTertiary)
                            .frame(width: 28, height: 28)
                            .background(AppColors.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Weekday headers
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays.indices, id: \.self) { i in
                    Text(weekdays[i])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                }
            }

            // Day grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(totalCells.indices, id: \.self) { index in
                    if let day = totalCells[index] {
                        dayCell(day: day)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }

            // Legend
            HStack(spacing: 14) {
                legendItem(color: AppColors.elevated, borderColor: AppColors.border, text: "Available")
                legendItem(color: Color(hex: "0D9488"), borderColor: nil, text: "Selected")
                legendItem(color: AppColors.tintedRed, borderColor: nil, text: "Booked")
                legendItem(color: Color(hex: "E5E7EB"), borderColor: nil, text: "Blocked")
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1)
            }
        }
        .padding(16)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func dayCell(day: Int) -> some View {
        let dateForDay = makeDate(day: day)
        let isBooked = bookedDays.contains(day)
        let isBlocked = blockedDays.contains(day)
        let isPast = dateForDay < cal.startOfDay(for: Date())
        let isStart = startDate.map { cal.isDate($0, inSameDayAs: dateForDay) } ?? false
        let isEnd = endDate.map { cal.isDate($0, inSameDayAs: dateForDay) } ?? false
        let isSelected = isStart || isEnd
        let isInRange = inSelectedRange(day: day)
        let isToday = todayDay == day

        return Button {
            guard !isBooked, !isBlocked, !isPast else { return }
            handleDayTap(dateForDay)
        } label: {
            Text("\(day)")
                .font(.system(size: 13, weight: isToday || isSelected ? .bold : .medium))
                .strikethrough(isBooked, color: Color(hex: "DC2626"))
                .foregroundStyle(foregroundFor(selected: isSelected, inRange: isInRange, booked: isBooked, blocked: isBlocked, past: isPast))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(backgroundFor(selected: isSelected, inRange: isInRange, booked: isBooked, blocked: isBlocked, today: isToday))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(isBooked || isBlocked || isPast)
    }

    private func foregroundFor(selected: Bool, inRange: Bool, booked: Bool, blocked: Bool, past: Bool) -> Color {
        if selected { return .white }
        if inRange { return Color(hex: "0F766E") }
        if booked { return Color(hex: "DC2626") }
        if blocked || past { return AppColors.textTertiary }
        return AppColors.textPrimary
    }

    private func backgroundFor(selected: Bool, inRange: Bool, booked: Bool, blocked: Bool, today: Bool) -> Color {
        if selected { return Color(hex: "0D9488") }
        if inRange { return AppColors.tintedTeal }
        if booked { return AppColors.tintedRed }
        if blocked { return Color(hex: "E5E7EB") }
        if today { return AppColors.background }
        return .clear
    }

    private func inSelectedRange(day: Int) -> Bool {
        guard let start = startDate, let end = endDate else { return false }
        let date = makeDate(day: day)
        return date > start && date < end
    }

    private func handleDayTap(_ date: Date) {
        if startDate == nil {
            startDate = date
            endDate = nil
        } else if endDate == nil {
            if let start = startDate, date > start {
                endDate = date
            } else {
                startDate = date
                endDate = nil
            }
        } else {
            startDate = date
            endDate = nil
        }
    }

    private func makeDate(day: Int) -> Date {
        var components = cal.dateComponents([.year, .month], from: displayedMonth)
        components.day = day
        return cal.date(from: components) ?? displayedMonth
    }

    private func shiftMonth(_ delta: Int) {
        if let newMonth = cal.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func legendItem(color: Color, borderColor: Color?, text: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
                .overlay(
                    borderColor.map {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke($0, lineWidth: 1)
                    }
                )
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textTertiary)
        }
    }
}
