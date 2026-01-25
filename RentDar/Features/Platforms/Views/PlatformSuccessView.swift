import SwiftUI

struct PlatformSuccessView: View {
    @Bindable var viewModel: ConnectPlatformViewModel
    let onDismiss: () -> Void

    @State private var showCheckmark = false
    @State private var showStats = false
    @State private var showBookings = false
    @State private var checkmarkScale: CGFloat = 0

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Step indicator (all complete)
                completeStepIndicator
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)

                // Success icon
                successIcon
                    .padding(.bottom, 20)

                // Title
                Text("\(viewModel.selectedPlatform.rawValue) Connected!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .opacity(showCheckmark ? 1 : 0)
                    .offset(y: showCheckmark ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: showCheckmark)

                Text("Your calendar is now syncing automatically")
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                    .opacity(showCheckmark ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: showCheckmark)

                // Stats cards
                statsRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    .opacity(showStats ? 1 : 0)
                    .offset(y: showStats ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showStats)

                // Upcoming bookings preview
                if !viewModel.upcomingBookings.isEmpty {
                    upcomingBookingsCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .opacity(showBookings ? 1 : 0)
                        .offset(y: showBookings ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showBookings)
                }

                // Sync info
                syncInfoBanner
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // Action buttons
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Complete Step Indicator

    private var completeStepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { step in
                ZStack {
                    Circle()
                        .fill(Color(hex: "2DD4A8"))
                        .frame(width: 28, height: 28)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }

                if step < 3 {
                    Rectangle()
                        .fill(Color(hex: "2DD4A8"))
                        .frame(height: 2)
                }
            }
        }
    }

    // MARK: - Success Icon

    private var successIcon: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(AppColors.teal500.opacity(0.15))
                .frame(width: 120, height: 120)
                .scaleEffect(showCheckmark ? 1.2 : 0.8)
                .opacity(showCheckmark ? 0 : 1)

            // Main circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.teal500, Color(hex: "2DD4A8")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)
                .shadow(color: AppColors.teal500.opacity(0.3), radius: 16, y: 8)
                .scaleEffect(checkmarkScale)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(checkmarkScale)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            SuccessStatCard(
                value: "\(viewModel.importedBookings)",
                label: "Bookings imported",
                color: AppColors.teal500
            )

            SuccessStatCard(
                value: "\(viewModel.importedBlocked)",
                label: "Blocked dates",
                color: Color(hex: "F59E0B")
            )

            SuccessStatCard(
                value: "\(viewModel.conflicts)",
                label: "Conflicts",
                color: AppColors.success
            )
        }
    }

    // MARK: - Upcoming Bookings Card

    private var upcomingBookingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming from \(viewModel.selectedPlatform.rawValue)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            ForEach(Array(viewModel.upcomingBookings.enumerated()), id: \.element.id) { index, booking in
                HStack(spacing: 10) {
                    // Platform color stripe
                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.selectedPlatform.color)
                        .frame(width: 4, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(booking.guestName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text("\(booking.dateRange) · \(booking.nights) nights")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textTertiary)
                    }

                    Spacer()

                    Text(viewModel.selectedPlatform.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(viewModel.selectedPlatform.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(viewModel.selectedPlatform.tintedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .padding(.bottom, index < viewModel.upcomingBookings.count - 1 ? 10 : 0)

                if index < viewModel.upcomingBookings.count - 1 {
                    Divider()
                        .background(AppColors.border)
                }
            }
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    // MARK: - Sync Info Banner

    private var syncInfoBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.teal500)

            Text("Auto-syncs every \(viewModel.syncFrequency) min · Last sync: Just now")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.teal500)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(AppColors.tintedTeal)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                onDismiss()
            } label: {
                Text("View Calendar")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [AppColors.teal600, Color(hex: "0D7C6E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: AppColors.teal600.opacity(0.3), radius: 12, y: 4)
            }

            Button {
                onDismiss()
            } label: {
                Text("Connect Another Platform")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppColors.border, lineWidth: 1.5)
                    )
            }
        }
    }

    // MARK: - Animations

    private func animateIn() {
        // Checkmark animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            checkmarkScale = 1.0
            showCheckmark = true
        }

        // Stats animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showStats = true
            }
        }

        // Bookings animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation {
                showBookings = true
            }
        }
    }
}

// MARK: - Stat Card

private struct SuccessStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(color)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}
