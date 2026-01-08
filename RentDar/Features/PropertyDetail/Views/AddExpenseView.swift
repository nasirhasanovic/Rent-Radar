import SwiftUI

struct AddExpenseView: View {
    let viewModel: PropertyDetailViewModel
    var onDismiss: () -> Void

    @State private var selectedCategory: ExpenseCategory = .cleaning
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var description: String = ""
    @State private var isRecurring: Bool = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case amount, description
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerRow
                categorySection
                amountSection
                dateSection
                descriptionSection
                recurringSection
                receiptSection
                submitButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(AppColors.elevated)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("\u{1F4E4} Add Expense")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.background)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Category Grid

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(ExpenseCategory.allCases, id: \.rawValue) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(category.emoji)
                                .font(.system(size: 24))
                            Text(category.label)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(
                                    selectedCategory == category
                                        ? Color(hex: "DC2626")
                                        : AppColors.textTertiary
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 10)
                        .background(
                            selectedCategory == category
                                ? Color(hex: "FEF2F2")
                                : AppColors.elevated
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    selectedCategory == category
                                        ? AppColors.expense
                                        : AppColors.border,
                                    lineWidth: 2
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Amount

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Amount")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 4) {
                Text(AppSettings.shared.currencySymbol)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.expense)

                TextField("0.00", text: $amount)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(AppColors.expense)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        focusedField == .amount ? AppColors.expense : AppColors.border,
                        lineWidth: 2
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    // MARK: - Date

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            HStack {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 2)
            )
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            TextField("What was this expense for?", text: $description)
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textPrimary)
                .focused($focusedField, equals: .description)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            focusedField == .description ? AppColors.expense : AppColors.border,
                            lineWidth: 2
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    // MARK: - Recurring Toggle

    private var recurringSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Recurring Expense")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                Text("This expense repeats monthly")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isRecurring)
                .labelsHidden()
                .tint(AppColors.expense)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Divider().foregroundStyle(AppColors.background)
        }
    }

    // MARK: - Receipt Upload

    private var receiptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Receipt (optional)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            Button { } label: {
                VStack(spacing: 8) {
                    Text("\u{1F4F7}")
                        .font(.system(size: 32))
                    Text("Tap to upload receipt")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textTertiary)
                    Text("JPG, PNG or PDF up to 10MB")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            AppColors.border,
                            style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                        )
                )
            }
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            guard let parsedAmount = Double(amount), parsedAmount > 0 else {
                onDismiss()
                return
            }
            let detail = description.isEmpty ? selectedCategory.label : description
            viewModel.addExpense(
                category: selectedCategory,
                amount: parsedAmount,
                date: date,
                detail: detail,
                isRecurring: isRecurring
            )
            onDismiss()
        } label: {
            Text("Add Expense")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.expense)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.top, 8)
    }
}
