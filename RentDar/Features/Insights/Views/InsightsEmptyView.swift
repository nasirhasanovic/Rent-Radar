import SwiftUI

struct InsightsEmptyView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading) {
                Text("Insights")
                    .font(AppTypography.heading1)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .background(AppColors.elevated)
            .overlay(alignment: .bottom) { Divider() }

            // Empty state
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "EDE9FE"), Color(hex: "DDD6FE")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Text("\u{1F4CA}")
                            .font(.system(size: 64))
                    )

                // Floating "+24%" badge
                HStack(spacing: 4) {
                    Text("\u{1F4C8}")
                        .font(.system(size: 12))
                    Text("+24%")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "10B981"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .offset(x: 80, y: -55)

                // Floating "Revenue" badge
                HStack(spacing: 6) {
                    Text("\u{1F4B0}")
                        .font(.system(size: 12))
                    Text("Revenue")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(AppColors.textTertiary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .offset(x: -75, y: 60)
            }
            .frame(width: 220, height: 200)

            Spacer().frame(height: 24)

            Text("No insights available")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Spacer().frame(height: 12)

            Text("Add properties and bookings to start\nseeing performance insights, revenue\ntrends, and occupancy reports.")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: 32)

            Button {} label: {
                HStack(spacing: 8) {
                    Text("\u{1F3E0}")
                        .font(.system(size: 14))
                    Text("Add Property")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "0D9488").opacity(0.3), radius: 12, x: 0, y: 4)
            }

            Spacer()
        }
        .background(AppColors.background)
    }
}
