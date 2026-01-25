import SwiftUI
import CoreData

struct ConnectedPlatformsView: View {
    let property: PropertyEntity
    let onDismiss: () -> Void
    let onConnectNew: () -> Void

    private let settings = AppSettings.shared

    // Mock connected platforms - in real app, fetch from Core Data
    @State private var connections: [PlatformConnection] = []
    @State private var platformToConnect: PlatformType?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Sync health banner
                    syncHealthBanner

                    // Connected platforms
                    ForEach(connections) { connection in
                        ConnectedPlatformCard(connection: connection)
                    }

                    // Unconnected platforms
                    ForEach(unconnectedPlatforms) { platform in
                        UnconnectedPlatformCard(platform: platform) {
                            platformToConnect = platform
                        }
                    }

                    // Direct bookings
                    directBookingsCard

                    // Summary bar
                    summaryBar
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            loadConnections()
        }
        .fullScreenCover(item: $platformToConnect) { platform in
            ConnectPlatformView(
                property: property,
                platform: platform,
                onDismiss: {
                    platformToConnect = nil
                    loadConnections()
                }
            )
            .environment(\.managedObjectContext, property.managedObjectContext!)
            .preferredColorScheme(settings.colorScheme)
            .environment(\.locale, settings.locale)
        }
    }

    private var unconnectedPlatforms: [PlatformType] {
        let connectedTypes = Set(connections.map { $0.platform })
        return [.airbnb, .booking, .vrbo].filter { !connectedTypes.contains($0) }
    }

    private func loadConnections() {
        // Load from UserDefaults (mock implementation)
        var loaded: [PlatformConnection] = []

        for platform in [PlatformType.airbnb, .booking, .vrbo] {
            let key = "platform_\(property.id?.uuidString ?? "")_\(platform.rawValue)"
            if let url = UserDefaults.standard.string(forKey: key) {
                let lastSync = UserDefaults.standard.object(forKey: "\(key)_lastSync") as? Date ?? Date()
                loaded.append(PlatformConnection(
                    platform: platform,
                    calendarURL: url,
                    lastSyncDate: lastSync,
                    bookingsCount: Int.random(in: 5...15),
                    blockedCount: Int.random(in: 1...4),
                    syncFrequency: 180
                ))
            }
        }

        connections = loaded
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
                Text("Connected Platforms")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text(property.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button(action: onConnectNew) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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

    // MARK: - Sync Health Banner

    private var syncHealthBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.success)
                    .frame(width: 40, height: 40)

                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("All calendars in sync")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "065F46"))

                Text("No conflicts detected · 0 double-bookings")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [AppColors.tintedTeal, Color(hex: "ECFDF5")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "A7F3D0"), lineWidth: 1)
        )
    }

    // MARK: - Direct Bookings Card

    private var directBookingsCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.tintedTeal)
                    .frame(width: 44, height: 44)

                Image(systemName: "house")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.teal500)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Direct Bookings")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Circle()
                        .fill(AppColors.teal500)
                        .frame(width: 8, height: 8)
                }

                Text("5 manual bookings logged")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            Text("Manual")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.teal500)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.tintedTeal)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: 0) {
            SummaryItem(value: "\(totalBookings)", label: "Total Bookings", color: AppColors.teal500)
            Divider().frame(height: 32)
            SummaryItem(value: "\(totalBlocked)", label: "Blocked Dates", color: Color(hex: "F59E0B"))
            Divider().frame(height: 32)
            SummaryItem(value: "0", label: "Conflicts", color: AppColors.success)
            Divider().frame(height: 32)
            SummaryItem(value: "\(connections.count + 1)", label: "Platforms", color: AppColors.textPrimary)
        }
        .padding(.vertical, 14)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private var totalBookings: Int {
        connections.reduce(0) { $0 + $1.bookingsCount } + 5 // +5 for direct
    }

    private var totalBlocked: Int {
        connections.reduce(0) { $0 + $1.blockedCount }
    }
}

// MARK: - Platform Connection Model

struct PlatformConnection: Identifiable {
    let id = UUID()
    let platform: PlatformType
    let calendarURL: String
    let lastSyncDate: Date
    let bookingsCount: Int
    let blockedCount: Int
    let syncFrequency: Int // minutes

    var lastSyncText: String {
        let interval = Date().timeIntervalSince(lastSyncDate)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60)) min ago"
        } else {
            return "\(Int(interval / 3600))h \(Int((interval.truncatingRemainder(dividingBy: 3600)) / 60))m ago"
        }
    }

    var syncFrequencyText: String {
        if syncFrequency < 60 {
            return "\(syncFrequency)m"
        } else {
            return "\(syncFrequency / 60)h"
        }
    }
}

// MARK: - Connected Platform Card

private struct ConnectedPlatformCard: View {
    let connection: PlatformConnection
    @State private var isRefreshing = false

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 12) {
                platformIcon

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(connection.platform.rawValue)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)

                        Circle()
                            .fill(AppColors.success)
                            .frame(width: 8, height: 8)
                    }

                    Text("Last sync: \(connection.lastSyncText)")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                Text("Active")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.teal500)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppColors.tintedTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.teal300, lineWidth: 1)
                    )
            }

            // Stats row
            HStack(spacing: 8) {
                StatBox(value: "\(connection.bookingsCount)", label: "Bookings")
                StatBox(value: "\(connection.blockedCount)", label: "Blocked")
                StatBox(value: connection.syncFrequencyText, label: "Refresh")

                // Refresh button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isRefreshing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation {
                            isRefreshing = false
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 14))
                            .foregroundStyle(connection.platform.color)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(.linear(duration: 1).repeatWhile(isRefreshing), value: isRefreshing)

                        Text("Refresh")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(connection.platform.color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
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

    @ViewBuilder
    private var platformIcon: some View {
        switch connection.platform {
        case .airbnb:
            Image("airbnb_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        case .booking:
            Image("booking_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        case .vrbo:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(connection.platform.tintedBackground)
                    .frame(width: 44, height: 44)
                Text("V")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(connection.platform.color)
            }
        case .direct:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(connection.platform.tintedBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: "house.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(connection.platform.color)
            }
        }
    }
}

// MARK: - Unconnected Platform Card

private struct UnconnectedPlatformCard: View {
    let platform: PlatformType
    let onConnect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            platformIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(platform.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)

                Text("Not connected")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "D1D5DB"))
            }

            Spacer()

            Button(action: onConnect) {
                Text("Connect")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.teal500)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                .foregroundStyle(Color(hex: "D1D5DB"))
        )
    }

    @ViewBuilder
    private var platformIcon: some View {
        switch platform {
        case .airbnb:
            Image("airbnb_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .saturation(0)
                .opacity(0.4)
        case .booking:
            Image("booking_icon")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .saturation(0)
                .opacity(0.4)
        case .vrbo:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "F3F4F6"))
                    .frame(width: 44, height: 44)
                Text("V")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Color(hex: "D1D5DB"))
            }
        case .direct:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "F3F4F6"))
                    .frame(width: 44, height: 44)
                Image(systemName: "house.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "D1D5DB"))
            }
        }
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Summary Item

private struct SummaryItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(color)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Animation Extension

extension Animation {
    func repeatWhile(_ condition: Bool) -> Animation {
        condition ? self.repeatForever(autoreverses: false) : self
    }
}
