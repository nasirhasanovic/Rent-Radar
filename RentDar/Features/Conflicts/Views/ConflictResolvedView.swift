import SwiftUI

struct ConflictResolvedView: View {
    let propertyName: String
    let keptBooking: ConflictBooking
    let cancelledBooking: ConflictBooking
    let onDone: () -> Void

    @State private var showCheckmark = false
    @State private var checkmarkScale: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Success icon
                    successIcon
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    // Title
                    Text("Conflict Resolved!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .opacity(showCheckmark ? 1 : 0)
                        .offset(y: showCheckmark ? 0 : 10)

                    Text("You chose to keep the \(keptBooking.platform) booking")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textTertiary)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                        .opacity(showCheckmark ? 1 : 0)

                    // Kept booking card
                    keptBookingCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

                    // Cancelled booking card
                    cancelledBookingCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // Action required banner
                    actionRequiredBanner
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: onDone) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Conflict Resolved")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                    Text(propertyName)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Success Icon

    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "10B981"), Color(hex: "059669")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 88)
                .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 16, y: 8)
                .scaleEffect(checkmarkScale)

            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(checkmarkScale)
        }
    }

    // MARK: - Kept Booking Card

    private var keptBookingCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                platformIcon(keptBooking.platform)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(keptBooking.platform) \u{2022} \(keptBooking.guestName)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(keptBooking.dateRangeString) \u{2022} \(keptBooking.nights) nights")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "10B981"))
                    Text("Kept")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "10B981"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "F0FDF4"))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Success banner
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "10B981"))

                Text("Calendar updated \u{2022} Dates secured")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "065F46"))
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "F0FDF4"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "10B981"), lineWidth: 2)
        )
    }

    // MARK: - Cancelled Booking Card

    private var cancelledBookingCard: some View {
        HStack(spacing: 10) {
            platformIcon(cancelledBooking.platform)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(cancelledBooking.platform) \u{2022} \(cancelledBooking.guestName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .strikethrough()
                Text("\(cancelledBooking.dateRangeString) \u{2022} \(cancelledBooking.nights) nights")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.border)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "EF4444"))
                Text("Cancel")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "EF4444"))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(hex: "FEF2F2"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .opacity(0.7)
    }

    // MARK: - Action Required Banner

    private var actionRequiredBanner: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "F59E0B"))
                        .frame(width: 32, height: 32)

                    Image(systemName: "exclamationmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Action Required")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "92400E"))
                    Text("Cancel the \(cancelledBooking.platform) reservation manually")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "B45309"))
                }
            }

            // Steps
            VStack(spacing: 8) {
                stepRow(number: "1", text: "Open \(cancelledBooking.platform) Extranet", isComplete: false)
                stepRow(number: "2", text: "Find \(cancelledBooking.guestName)'s reservation (\(cancelledBooking.dateRangeString))", isComplete: false)
                stepRow(number: "3", text: "Cancel or relocate the guest", isComplete: false)
                stepRow(number: nil, text: "Come back and mark as done", isComplete: true)
            }
            .padding(12)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(14)
        .background(Color(hex: "FFF7ED"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "FDE68A"), lineWidth: 1)
        )
    }

    private func stepRow(number: String?, text: String, isComplete: Bool) -> some View {
        HStack(spacing: 8) {
            if let num = number {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(platformTintColor(cancelledBooking.platform))
                        .frame(width: 20, height: 20)

                    Text(num)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(platformColor(cancelledBooking.platform))
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "F0FDF4"))
                        .frame(width: 20, height: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color(hex: "10B981"))
                }
            }

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onDone) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                    Text("I've Cancelled on \(cancelledBooking.platform)")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0D9488"), Color(hex: "0D7C6E")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "0D9488").opacity(0.3), radius: 12, y: 4)
            }

            Button(action: onDone) {
                Text("Remind Me Later")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppColors.border, lineWidth: 1.5)
                    )
            }
        }
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

    // MARK: - Animation

    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            checkmarkScale = 1.0
            showCheckmark = true
        }
    }
}
