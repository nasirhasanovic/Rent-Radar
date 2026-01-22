import SwiftUI

struct PlatformSelectionView: View {
    @Environment(\.managedObjectContext) private var context
    let property: PropertyEntity
    let onSelect: (PlatformType) -> Void
    let onDismiss: () -> Void

    @State private var animatedPlatforms: Set<PlatformType> = []
    @State private var platformToConnect: PlatformType?

    private let platforms: [PlatformType] = [.airbnb, .booking, .vrbo]
    private let settings = AppSettings.shared

    private func isPlatformConnected(_ platform: PlatformType) -> Bool {
        let key = "platform_\(property.id?.uuidString ?? "")_\(platform.rawValue)"
        guard let url = UserDefaults.standard.string(forKey: key) else { return false }
        return !url.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connect a Platform")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text("Import bookings and sync your calendar automatically")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                    // Platform cards
                    ForEach(platforms) { platform in
                        PlatformCard(
                            platform: platform,
                            isConnected: isPlatformConnected(platform),
                            isAnimated: animatedPlatforms.contains(platform)
                        ) {
                            platformToConnect = platform
                        }
                        .onAppear {
                            let delay = Double(platforms.firstIndex(of: platform) ?? 0) * 0.1
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                                _ = animatedPlatforms.insert(platform)
                            }
                        }
                    }

                    // Manual entry option
                    manualEntryCard

                    // Info banner
                    infoBanner
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .fullScreenCover(item: $platformToConnect) { platform in
            ConnectPlatformView(
                property: property,
                platform: platform,
                onDismiss: {
                    platformToConnect = nil
                    onDismiss()
                }
            )
            .environment(\.managedObjectContext, context)
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Connect Platform")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text(property.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Manual Entry Card

    private var manualEntryCard: some View {
        Button {
            // For now, just close - manual bookings are added via Log Booking
            onDismiss()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppColors.tintedTeal)
                        .frame(width: 52, height: 52)

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.teal500)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Manual Entry")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Add bookings directly without syncing")
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding(16)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                    .foregroundStyle(AppColors.border)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.teal500)

            VStack(alignment: .leading, spacing: 2) {
                Text("Your data stays on device")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("We only read your calendar. No passwords or account access required.")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textTertiary)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .background(AppColors.tintedTeal)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Platform Card

private struct PlatformCard: View {
    let platform: PlatformType
    let isConnected: Bool
    let isAnimated: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Platform icon
                platformIcon

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(platform.rawValue)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)

                        if isConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.success)
                        }
                    }

                    Text(platformDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                // Connect/Reconnect button
                Text(isConnected ? "Reconnect" : "Connect")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isConnected ? platform.color : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isConnected ? platform.color.opacity(0.15) : platform.color)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(16)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .scaleEffect(isAnimated ? 1 : 0.95)
            .opacity(isAnimated ? 1 : 0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
        }
    }

    @ViewBuilder
    private var platformIcon: some View {
        switch platform {
        case .airbnb:
            Image("airbnb_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        case .booking:
            Image("booking_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        case .vrbo:
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(platform.tintedBackground)
                    .frame(width: 52, height: 52)
                Text("V")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(platform.color)
            }
        case .direct:
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(platform.tintedBackground)
                    .frame(width: 52, height: 52)
                Image(systemName: "house.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(platform.color)
            }
        }
    }

    private var platformDescription: String {
        switch platform {
        case .airbnb: return "Sync your Airbnb bookings & blocked dates"
        case .booking: return "Import reservations from Booking.com"
        case .vrbo: return "Connect your VRBO/Vrbo calendar"
        case .direct: return "Add direct bookings manually"
        }
    }
}

// MARK: - Press Events Modifier

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}
