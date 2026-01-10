import SwiftUI

struct CalendarBookingCard: View {
    let booking: TransactionEntity
    let propertyName: String
    let platformColor: Color
    let platformTintedBg: Color

    private var platform: String { booking.platform ?? "Direct" }
    private var guestName: String { booking.name ?? "Guest" }
    private var amount: Double { booking.amount }
    private var checkInDate: Date { booking.date ?? Date() }
    private var nightCount: Int { booking.nights }
    private var city: String { booking.property?.shortAddress ?? "" }

    var body: some View {
        HStack(spacing: 0) {
            // Left platform stripe
            platformColor
                .frame(width: 4)

            HStack(spacing: 12) {
                // Date badge
                dateBadge

                // Info section
                VStack(alignment: .leading, spacing: 3) {
                    Text(propertyName)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)

                    Text(guestName)
                        .font(AppTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)

                    HStack(spacing: 6) {
                        if nightCount > 0 {
                            Text("\(nightCount) nights")
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                        if !city.isEmpty {
                            Text(city)
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }

                Spacer()

                // Right: amount + platform badge
                VStack(alignment: .trailing, spacing: 6) {
                    Text("+\(AppSettings.shared.currencySymbol)\(Int(amount).formatted())")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "10B981"))

                    Text(platform)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(platformColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(platformTintedBg)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Date Badge

    private var dateBadge: some View {
        VStack(spacing: 0) {
            Text("\(Calendar.current.component(.day, from: checkInDate))")
                .font(AppTypography.heading3)
                .fontWeight(.bold)
                .foregroundStyle(platformColor)

            Text(monthAbbrev)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(platformColor.opacity(0.7))
        }
        .frame(width: 44, height: 44)
        .background(platformTintedBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: checkInDate).uppercased()
    }
}
