import SwiftUI

struct BookingConflict: Identifiable {
    let id = UUID()
    let propertyName: String
    let booking1: ConflictBooking
    let booking2: ConflictBooking
    let overlapStart: Date
    let overlapEnd: Date
    var overlapNights: Int {
        Calendar.current.dateComponents([.day], from: overlapStart, to: overlapEnd).day ?? 0
    }
}

struct ConflictBooking: Identifiable {
    let id = UUID()
    let platform: String
    let guestName: String
    let startDate: Date
    let endDate: Date
    let bookedDate: Date
    let isConfirmed: Bool

    var nights: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }

    var bookedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: bookedDate)
    }
}

struct ResolveConflictView: View {
    let conflict: BookingConflict
    let onDismiss: () -> Void
    let onResolved: (ConflictBooking) -> Void

    @State private var showResolved = false
    @State private var keptBooking: ConflictBooking?

    var body: some View {
        if showResolved, let kept = keptBooking {
            ConflictResolvedView(
                propertyName: conflict.propertyName,
                keptBooking: kept,
                cancelledBooking: kept.id == conflict.booking1.id ? conflict.booking2 : conflict.booking1,
                onDone: onDismiss
            )
        } else {
            mainContent
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Timeline visualization
                    conflictTimeline
                        .padding(.horizontal, 20)

                    // Booking A
                    bookingCard(conflict.booking1, isFirst: true)
                        .padding(.horizontal, 20)

                    // VS Divider
                    vsDivider

                    // Booking B
                    bookingCard(conflict.booking2, isFirst: false)
                        .padding(.horizontal, 20)

                    // Help text
                    helpBanner
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                }
                .padding(.vertical, 16)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Resolve Conflict")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(conflict.propertyName) \u{2022} Double-booking")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                Text("Urgent")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "7F1D1D"), Color(hex: "DC2626")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Conflict Timeline

    private var conflictTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overlapping Dates")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            // Visual timeline bars
            VStack(spacing: 8) {
                // Date labels
                HStack {
                    ForEach(dateLabels, id: \.self) { label in
                        Text(label)
                            .font(.system(size: 9))
                            .foregroundStyle(AppColors.textTertiary)
                        if label != dateLabels.last {
                            Spacer()
                        }
                    }
                }

                // Booking 1 bar
                GeometryReader { geo in
                    let width1 = barWidth(for: conflict.booking1, in: geo.size.width)
                    let offset1 = barOffset(for: conflict.booking1, in: geo.size.width)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(platformColor(conflict.booking1.platform))
                        .frame(width: width1, height: 16)
                        .offset(x: offset1)
                        .overlay(alignment: .leading) {
                            Text("\(conflict.booking1.platform) \u{2022} \(conflict.booking1.guestName)")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.leading, 6)
                                .offset(x: offset1)
                        }
                }
                .frame(height: 16)

                // Booking 2 bar
                GeometryReader { geo in
                    let width2 = barWidth(for: conflict.booking2, in: geo.size.width)
                    let offset2 = barOffset(for: conflict.booking2, in: geo.size.width)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(platformColor(conflict.booking2.platform))
                        .frame(width: width2, height: 16)
                        .offset(x: offset2)
                        .overlay(alignment: .leading) {
                            Text("\(conflict.booking2.platform) \u{2022} \(conflict.booking2.guestName)")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.leading, 6)
                                .offset(x: offset2)
                        }
                }
                .frame(height: 16)
            }

            // Overlap indicator
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "EF4444"))

                Text("\(conflict.overlapNights) nights overlap (\(overlapDateString))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "991B1B"))
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "FEF2F2"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "FECACA"), lineWidth: 1)
        )
    }

    private var dateLabels: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let allDates = [conflict.booking1.startDate, conflict.booking1.endDate,
                        conflict.booking2.startDate, conflict.booking2.endDate]
        let sorted = allDates.sorted()

        guard let first = sorted.first, let last = sorted.last else { return [] }

        var labels: [String] = []
        var current = first
        while current <= last {
            labels.append(formatter.string(from: current))
            current = Calendar.current.date(byAdding: .day, value: 1, to: current) ?? last
            if labels.count >= 6 { break }
        }
        return labels
    }

    private var overlapDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: conflict.overlapStart))–\(formatter.string(from: conflict.overlapEnd))"
    }

    private func barWidth(for booking: ConflictBooking, in totalWidth: CGFloat) -> CGFloat {
        let totalDays = max(1, daysBetween(earliestDate, latestDate))
        let bookingDays = max(1, daysBetween(booking.startDate, booking.endDate))
        return (CGFloat(bookingDays) / CGFloat(totalDays)) * totalWidth
    }

    private func barOffset(for booking: ConflictBooking, in totalWidth: CGFloat) -> CGFloat {
        let totalDays = max(1, daysBetween(earliestDate, latestDate))
        let offsetDays = daysBetween(earliestDate, booking.startDate)
        return (CGFloat(offsetDays) / CGFloat(totalDays)) * totalWidth
    }

    private var earliestDate: Date {
        min(conflict.booking1.startDate, conflict.booking2.startDate)
    }

    private var latestDate: Date {
        max(conflict.booking1.endDate, conflict.booking2.endDate)
    }

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
    }

    // MARK: - Booking Card

    private func bookingCard(_ booking: ConflictBooking, isFirst: Bool) -> some View {
        VStack(spacing: 12) {
            // Header row
            HStack(spacing: 10) {
                platformIcon(booking.platform)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(booking.platform) Booking")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Booked \(isFirst ? "first" : "second") \u{2022} \(booking.bookedDateString)")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                Text(isFirst ? "Arrived first" : "Conflicts")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isFirst ? platformColor(booking.platform) : Color(hex: "EF4444"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isFirst ? platformTintColor(booking.platform) : Color(hex: "FEF2F2"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Details grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                detailCell(label: "Guest", value: booking.guestName)
                detailCell(label: "Dates", value: booking.dateRangeString)
                detailCell(label: "Nights", value: "\(booking.nights) nights")
                detailCell(label: "Status", value: booking.isConfirmed ? "Confirmed" : "Pending", isGreen: booking.isConfirmed)
            }

            // Keep button
            Button {
                keptBooking = booking
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showResolved = true
                }
                onResolved(booking)
            } label: {
                Text("Keep \(booking.platform) Booking")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(platformColor(booking.platform))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(14)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(platformColor(booking.platform), lineWidth: 2)
        )
    }

    private func detailCell(label: String, value: String, isGreen: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9))
                .foregroundStyle(AppColors.textTertiary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isGreen ? Color(hex: "10B981") : AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - VS Divider

    private var vsDivider: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)

            ZStack {
                Circle()
                    .fill(Color(hex: "FEF2F2"))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "FECACA"), lineWidth: 2)
                    )

                Text("VS")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(Color(hex: "EF4444"))
            }

            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Help Banner

    private var helpBanner: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textTertiary)

            Text("Choose which booking to keep. You'll need to cancel the other one on its platform. RentDar will update your calendar automatically.")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
                .lineSpacing(2)
        }
        .padding(12)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func platformIcon(_ platform: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(platformTintColor(platform))

            switch platform.uppercased() {
            case "AIRBNB":
                Image("airbnb_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            case "BOOKING.COM", "BOOKING":
                Image("booking_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            case "VRBO":
                Text("V")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(platformColor(platform))
            default:
                Image(systemName: "house.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(platformColor(platform))
            }
        }
    }

    private func platformColor(_ platform: String) -> Color {
        switch platform.uppercased() {
        case "AIRBNB": return Color(hex: "FF5A5F")
        case "BOOKING.COM", "BOOKING": return Color(hex: "003580")
        case "VRBO": return Color(hex: "8B5CF6")
        default: return Color(hex: "10B981")
        }
    }

    private func platformTintColor(_ platform: String) -> Color {
        switch platform.uppercased() {
        case "AIRBNB": return Color(hex: "FFF1F0")
        case "BOOKING.COM", "BOOKING": return Color(hex: "E8F0FE")
        case "VRBO": return Color(hex: "EDE9FE")
        default: return Color(hex: "ECFDF5")
        }
    }
}
