import SwiftUI

struct PlatformSyncingView: View {
    @Bindable var viewModel: ConnectPlatformViewModel
    @State private var outerRingRotation: Double = 0
    @State private var middleRingScale: Double = 1.0
    @State private var iconPulse: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            StepIndicator(currentStep: viewModel.currentStep)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)

            // Sync animation
            syncAnimation
                .padding(.bottom, 32)

            // Status text
            Text(viewModel.isSyncing ? "Importing bookings..." : "Finalizing...")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.bottom, 6)

            Text("Fetching your \(viewModel.selectedPlatform.rawValue) calendar data")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textTertiary)
                .padding(.bottom, 24)

            // Progress bar
            progressBar
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            Text("Importing up to 2 years of data...")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
                .padding(.bottom, 32)

            // Live updates
            liveUpdates
                .padding(.horizontal, 20)

            Spacer()
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Sync Animation

    private var syncAnimation: some View {
        ZStack {
            // Outer dashed ring
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                .foregroundStyle(AppColors.border)
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(outerRingRotation))

            // Middle ring
            Circle()
                .stroke(AppColors.teal300, lineWidth: 3)
                .frame(width: 160, height: 160)
                .scaleEffect(middleRingScale)

            // Inner gradient circle with icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppColors.teal500, Color(hex: "2DD4A8")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(outerRingRotation * 2))
                )
                .scaleEffect(iconPulse ? 1.05 : 1.0)

            // Platform icon (top right)
            platformBadge(viewModel.selectedPlatform)
                .offset(x: 70, y: -70)

            // RentDar icon (bottom left)
            rentDarBadge
                .offset(x: -70, y: 70)
        }
        .frame(width: 220, height: 220)
    }

    private func platformBadge(_ platform: PlatformType) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(platform.tintedBackground)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            switch platform {
            case .airbnb:
                Image("airbnb_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            case .booking:
                Image("booking_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            case .vrbo:
                Text("V")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(platform.color)
            case .direct:
                Image(systemName: "house.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(platform.color)
            }
        }
    }

    private var rentDarBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.tintedTeal)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            Image(systemName: "house")
                .font(.system(size: 16))
                .foregroundStyle(AppColors.teal500)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.border)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.teal500, Color(hex: "2DD4A8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.syncProgress, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.syncProgress)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Live Updates

    private var liveUpdates: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.syncStatus) { status in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.success)

                    Text(status.message)
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Text(status.time)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.vertical, 10)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }

            if viewModel.isSyncing {
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(AppColors.teal500)

                    Text("Importing events...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.teal500)

                    Spacer()

                    Text("\(Int(viewModel.syncProgress * 100))%")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.vertical, 10)
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

    // MARK: - Animations

    private func startAnimations() {
        // Outer ring rotation
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            outerRingRotation = 360
        }

        // Middle ring pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            middleRingScale = 1.08
        }

        // Icon pulse
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            iconPulse = true
        }
    }
}
