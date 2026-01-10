import SwiftUI

struct CalendarGridView: View {
    let viewModel: CalendarViewModel
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 8) {
            weekdayHeaders
            dayGrid
            legend
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(AppTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
            }
        }
    }

    // MARK: - Day Grid

    private var dayGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            // Empty cells for offset
            ForEach(0..<viewModel.firstWeekdayOffset, id: \.self) { _ in
                Color.clear.frame(height: 44)
            }

            // Day cells
            ForEach(1...viewModel.daysInMonth, id: \.self) { day in
                let dots = viewModel.platformDots(for: day)
                let isToday = viewModel.todayDay == day
                let isSelected = viewModel.selectedDay == day
                let hasBooking = !dots.isEmpty
                let isBlocked = viewModel.isBlocked(day: day)

                Button {
                    if isBlocked, let blocked = viewModel.blockedInfo(for: day) {
                        // Tap on blocked date - open edit/delete
                        viewModel.selectedBlockedDate = blocked
                        viewModel.showEditBlockedDate = true
                    } else {
                        viewModel.selectDay(day)
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text("\(day)")
                            .font(.system(size: 14, weight: (isToday || isSelected || isBlocked) ? .bold : .regular))
                            .foregroundStyle(
                                isBlocked ? Color(hex: "6B7280") :
                                isSelected ? .white :
                                isToday ? AppColors.teal600 :
                                AppColors.textPrimary
                            )

                        if isBlocked {
                            // Show blocked indicator
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: "9CA3AF"))
                                .frame(width: 12, height: 3)
                                .frame(height: 6)
                        } else if dots.isEmpty {
                            Color.clear.frame(height: 6)
                        } else {
                            HStack(spacing: 2) {
                                ForEach(Array(dots.prefix(3).enumerated()), id: \.offset) { _, platform in
                                    Circle()
                                        .fill(isSelected ? .white.opacity(0.8) : CalendarViewModel.platformColor(for: platform))
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        isBlocked ? Color(hex: "E5E7EB") :
                        isSelected ? AppColors.teal500 :
                        hasBooking ? AppColors.tintedTeal :
                        Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        isToday && !isSelected && !isBlocked
                            ? RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.teal500, lineWidth: 2)
                            : nil
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 12) {
            ForEach(["Airbnb", "Booking", "Direct", "VRBO"], id: \.self) { platform in
                HStack(spacing: 4) {
                    Circle()
                        .fill(CalendarViewModel.platformColor(for: platform))
                        .frame(width: 6, height: 6)
                    Text(platform)
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            // Blocked legend item
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(hex: "9CA3AF"))
                    .frame(width: 10, height: 4)
                Text("Blocked")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.top, 8)
    }
}
