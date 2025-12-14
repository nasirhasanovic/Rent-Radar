import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .fill(iconColor.opacity(0.3))
                        .frame(width: 24, height: 24)
                )

            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)

            Text(value)
                .font(AppTypography.heading2)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    HStack(spacing: 12) {
        StatCard(title: "Income", value: "$3,145", iconColor: AppColors.income)
        StatCard(title: "Expenses", value: "$485", iconColor: AppColors.expense)
        StatCard(title: "Occupancy", value: "86%", iconColor: AppColors.expense)
    }
    .padding()
    .background(AppColors.background)
}
