import SwiftUI

struct DatePickerSheetView: View {
    @Binding var displayedMonth: Date
    @Binding var checkInDate: Date?
    @Binding var checkOutDate: Date?
    let bookedDays: Set<Int>
    let blockedDays: Set<Int>
    let onConfirm: () -> Void

    private let calendar = Calendar.current

    private var nights: Int {
        guard let start = checkInDate, let end = checkOutDate else { return 0 }
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(0, days)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "D1D5DB"))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Header
            HStack {
                Text("Select Dates")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            // Calendar
            MiniCalendarView(
                displayedMonth: $displayedMonth,
                startDate: $checkInDate,
                endDate: $checkOutDate,
                bookedDays: bookedDays,
                blockedDays: blockedDays
            )
            .padding(.horizontal, 20)

            Spacer()

            // Confirm button
            confirmButton
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(AppColors.elevated)
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button(action: onConfirm) {
            HStack(spacing: 8) {
                Text("Confirm")
                    .font(.system(size: 15, weight: .bold))
                if nights > 0 {
                    Text("·")
                    Text("\(nights) nights")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: nights > 0 ? [AppColors.teal600, Color(hex: "0D7C6E")] : [Color(hex: "9CA3AF"), Color(hex: "6B7280")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: nights > 0 ? AppColors.teal600.opacity(0.3) : .clear, radius: 12, y: 4)
        }
        .disabled(nights == 0)
    }
}
