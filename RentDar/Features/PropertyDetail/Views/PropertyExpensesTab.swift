import SwiftUI

struct PropertyExpensesTab: View {
    let viewModel: PropertyDetailViewModel

    var body: some View {
        Group {
            if viewModel.hasExpenses {
                VStack(alignment: .leading, spacing: 20) {
                    totalExpensesHeader
                    categoryBreakdownRow
                    transactionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            } else {
                expensesEmptyState
            }
        }
        .sheet(isPresented: Bindable(viewModel).showAddExpense) {
            AddExpenseView(viewModel: viewModel, onDismiss: { viewModel.showAddExpense = false })
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

    private var expensesEmptyState: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FEE2E2"), Color(hex: "FECACA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Text("\u{1F9FE}")
                        .font(.system(size: 52))
                )

            Spacer().frame(height: 24)

            Text("No expenses tracked")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Spacer().frame(height: 12)

            Text("Record cleaning, repairs, supplies,\nand other costs for accurate profit\ntracking and tax reports.")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: 28)

            Button { viewModel.showAddExpense = true } label: {
                HStack(spacing: 8) {
                    Text("\u{1F9FE}")
                        .font(.system(size: 14))
                    Text("Add Expense")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color(hex: "EF4444").opacity(0.3), radius: 12, x: 0, y: 4)
            }

            Spacer().frame(height: 24)

            // Common categories box
            VStack(alignment: .leading, spacing: 12) {
                Text("COMMON CATEGORIES")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.textTertiary)
                    .kerning(0.5)

                categoryRow(icon: "\u{1F9F9}", iconBg: AppColors.tintedBlue, text: "Cleaning & Maintenance")
                Divider()
                categoryRow(icon: "\u{1F527}", iconBg: AppColors.tintedGreen, text: "Repairs & Improvements")
                Divider()
                categoryRow(icon: "\u{1F4E6}", iconBg: AppColors.tintedOrange, text: "Supplies & Amenities")
            }
            .padding(16)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func categoryRow(icon: String, iconBg: Color, text: String) -> some View {
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

    // MARK: - Total Expenses

    private var totalExpensesHeader: some View {
        VStack(spacing: 6) {
            Text("Total Expenses (\(viewModel.currentMonthName))")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.textTertiary)

            Text(viewModel.formattedTotalExpenses)
                .font(AppTypography.display)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.expense)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.expenseCategories) { category in
                let isSelected = viewModel.selectedExpenseCategory == category.name
                Button {
                    viewModel.toggleExpenseFilter(category.name)
                } label: {
                    VStack(spacing: 4) {
                        Text(category.name)
                            .font(.system(size: 9))
                            .foregroundStyle(AppColors.textTertiary)
                        Text(category.formattedAmount)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(category.bgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? AppColors.expense : Color.clear, lineWidth: 2)
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

                Button { viewModel.showAddExpense = true } label: {
                    Text("+ Add")
                        .font(AppTypography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppColors.expense)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            VStack(spacing: 1) {
                ForEach(viewModel.expenseEntities, id: \.objectID) { entity in
                    Button {
                        viewModel.selectedTransaction = entity
                    } label: {
                        TransactionRow(transaction: entity.toMockTransaction())
                            .background(AppColors.elevated)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Shared Transaction Row

struct TransactionRow: View {
    let transaction: MockTransaction

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if transaction.isEmojiIcon {
                    Text(transaction.icon)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: transaction.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(transaction.isIncome ? AppColors.teal600 : AppColors.error)
                }
            }
            .frame(width: 40, height: 40)
            .background(transaction.iconBg)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text("\(transaction.dateRange) \u{2022} \(transaction.detail)")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(transaction.isIncome ? Color(hex: "10B981") : AppColors.expense)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
