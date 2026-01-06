import SwiftUI

struct PropertyIncomeTab: View {
    let viewModel: PropertyDetailViewModel

    var body: some View {
        Group {
            if viewModel.hasIncome {
                VStack(alignment: .leading, spacing: 20) {
                    totalIncomeHeader
                    sourceBreakdownRow
                    transactionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            } else {
                incomeEmptyState
            }
        }
        .sheet(isPresented: Bindable(viewModel).showAddIncome) {
            AddIncomeView(viewModel: viewModel, onDismiss: { viewModel.showAddIncome = false })
        }
        .sheet(item: Bindable(viewModel).selectedTransaction) { entity in
            TransactionDetailView(
                transaction: entity,
                viewModel: viewModel,
                onDismiss: { viewModel.selectedTransaction = nil }
            )
        }
    }

    // MARK: - Empty State

    private var incomeEmptyState: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "D1FAE5"), Color(hex: "A7F3D0")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Text("\u{1F4B0}")
                        .font(.system(size: 52))
                )

            Spacer().frame(height: 24)

            Text("No income recorded")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Spacer().frame(height: 12)

            Text("Track your rental earnings by adding\nincome from Airbnb, Booking.com,\nand direct bookings.")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: 28)

            Button { viewModel.showAddIncome = true } label: {
                HStack(spacing: 8) {
                    Text("\u{1F4B0}")
                        .font(.system(size: 14))
                    Text("Add Income")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "10B981"), Color(hex: "059669")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 12, x: 0, y: 4)
            }

            Spacer().frame(height: 24)

            // Tips box
            VStack(alignment: .leading, spacing: 12) {
                Text("QUICK TIPS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.textTertiary)
                    .kerning(0.5)

                tipRow(icon: "\u{1F517}", iconBg: AppColors.tintedBlue, text: "Connect Airbnb to auto-sync income")
                Divider()
                tipRow(icon: "\u{1F4F1}", iconBg: AppColors.tintedGreen, text: "Add income manually after each booking")
            }
            .padding(16)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func tipRow(icon: String, iconBg: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 16))
                .frame(width: 32, height: 32)
                .background(iconBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    // MARK: - Total Income

    private var totalIncomeHeader: some View {
        VStack(spacing: 6) {
            Text("Total Income (\(viewModel.currentMonthName))")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.textTertiary)

            Text(viewModel.formattedTotalIncome)
                .font(AppTypography.display)
                .fontWeight(.bold)
                .foregroundStyle(Color(hex: "10B981"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Source Breakdown

    private var sourceBreakdownRow: some View {
        HStack(spacing: 10) {
            ForEach(viewModel.incomeSourceBreakdown) { source in
                let isSelected = viewModel.selectedIncomeSource == source.name
                Button {
                    viewModel.toggleIncomeFilter(source.name)
                } label: {
                    VStack(spacing: 6) {
                        Text(source.name)
                            .font(AppTypography.caption)
                            .foregroundStyle(source.textColor.opacity(0.7))
                        Text(source.formattedAmount)
                            .font(AppTypography.heading3)
                            .fontWeight(.bold)
                            .foregroundStyle(source.textColor)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(source.bgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? source.textColor : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Transactions")
                    .font(AppTypography.heading3)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button { viewModel.showAddIncome = true } label: {
                    Text("+ Add")
                        .font(AppTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppColors.teal500)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(viewModel.incomeEntities.enumerated()), id: \.element.objectID) { index, entity in
                    Button {
                        viewModel.selectedTransaction = entity
                    } label: {
                        TransactionRow(transaction: entity.toMockTransaction())
                    }
                    .buttonStyle(.plain)

                    if index < viewModel.incomeEntities.count - 1 {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, 4)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}
