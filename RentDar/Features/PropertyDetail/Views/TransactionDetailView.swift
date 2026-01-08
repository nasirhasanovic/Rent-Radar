import SwiftUI

struct TransactionDetailView: View {
    let transaction: TransactionEntity
    let viewModel: PropertyDetailViewModel
    var onDismiss: () -> Void

    @State private var isEditing = false

    // Edit state
    @State private var editName: String = ""
    @State private var editAmount: String = ""
    @State private var editDate: Date = Date()
    @State private var editEndDate: Date = Date()
    @State private var editDetail: String = ""
    @State private var editIsRecurring: Bool = false
    @State private var editCategory: ExpenseCategory = .cleaning
    @State private var editPlatform: IncomePlatform = .airbnb
    @State private var showDeleteConfirmation = false

    private let green = Color(hex: "10B981")

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerRow
                if isEditing {
                    editContent
                } else {
                    viewContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(AppColors.elevated)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { loadEditState() }
        .alert("Delete Transaction", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteTransaction(transaction)
                onDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This transaction will be permanently removed.")
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(transaction.isIncome ? "\u{1F4B0} Income Details" : "\u{1F4E4} Expense Details")
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

    // MARK: - View Content

    private var viewContent: some View {
        VStack(spacing: 16) {
            // Icon + Name + Badge
            VStack(spacing: 12) {
                Text(transaction.displayIcon)
                    .font(.system(size: 36))
                    .frame(width: 72, height: 72)
                    .background(transaction.displayIconBg)
                    .clipShape(Circle())

                Text(transaction.name ?? "")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(transaction.isIncome ? "Income" : "Expense")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(transaction.isIncome ? green : AppColors.expense)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)

            // Amount
            Text(transaction.formattedDisplayAmount)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(transaction.isIncome ? green : AppColors.expense)
                .frame(maxWidth: .infinity)

            // Info rows
            VStack(spacing: 0) {
                if transaction.isIncome {
                    infoRow(label: "Date Range", value: transaction.displayDateRange)
                    divider
                    if transaction.nights > 0 {
                        infoRow(label: "Nights", value: "\(transaction.nights)")
                        divider
                    }
                    infoRow(label: "Platform", value: transaction.platform ?? "Direct")
                } else {
                    infoRow(label: "Date", value: transaction.displayDateRange)
                    divider
                    let catLabel = ExpenseCategory(rawValue: transaction.category ?? "")?.label ?? (transaction.category ?? "Other")
                    infoRow(label: "Category", value: catLabel)
                    if transaction.isRecurring {
                        divider
                        infoRow(label: "Recurring", value: "Monthly")
                    }
                }
                if let detail = transaction.detail, !detail.isEmpty {
                    divider
                    infoRow(label: "Notes", value: detail)
                }
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Action buttons
            VStack(spacing: 10) {
                Button {
                    loadEditState()
                    withAnimation(.easeInOut(duration: 0.2)) { isEditing = true }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                        Text("Edit Transaction")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.teal600)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("Delete")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(AppColors.expense)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.expense.opacity(0.3), lineWidth: 1.5)
                    )
                }
            }
            .padding(.top, 8)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(AppColors.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var divider: some View {
        Divider().padding(.leading, 16)
    }

    // MARK: - Edit Content

    private var editContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if transaction.isIncome {
                incomeEditFields
            } else {
                expenseEditFields
            }

            // Save / Cancel
            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { isEditing = false }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.border, lineWidth: 1.5)
                        )
                }

                Button {
                    saveEdits()
                } label: {
                    Text("Save Changes")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.teal600)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Income Edit Fields

    private var incomeEditFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            editSectionLabel("PLATFORM")
            HStack(spacing: 8) {
                ForEach(IncomePlatform.allCases, id: \.rawValue) { platform in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { editPlatform = platform }
                    } label: {
                        HStack(spacing: 4) {
                            Text(platform.emoji)
                                .font(.system(size: 11))
                            Text(platform.rawValue)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundStyle(editPlatform == platform ? platform.selectedText : AppColors.textTertiary)
                        .background(editPlatform == platform ? platform.selectedBg : AppColors.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(editPlatform == platform ? platform.selectedBorder : AppColors.border, lineWidth: 1.5)
                        )
                    }
                }
            }

            editSectionLabel("GUEST NAME")
            editTextField(text: $editName, placeholder: "Guest name")

            editSectionLabel("CHECK-IN")
            DatePicker("", selection: $editDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1.5))

            editSectionLabel("CHECK-OUT")
            DatePicker("", selection: $editEndDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1.5))

            editSectionLabel("AMOUNT")
            editAmountField(color: green)

            editSectionLabel("NOTES")
            editTextField(text: $editDetail, placeholder: "Add notes...")
        }
    }

    // MARK: - Expense Edit Fields

    private var expenseEditFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            editSectionLabel("CATEGORY")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(ExpenseCategory.allCases, id: \.rawValue) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { editCategory = category }
                    } label: {
                        VStack(spacing: 6) {
                            Text(category.emoji)
                                .font(.system(size: 20))
                            Text(category.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(editCategory == category ? Color(hex: "DC2626") : AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(editCategory == category ? Color(hex: "FEF2F2") : AppColors.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(editCategory == category ? AppColors.expense : AppColors.border, lineWidth: 1.5)
                        )
                    }
                }
            }

            editSectionLabel("AMOUNT")
            editAmountField(color: AppColors.expense)

            editSectionLabel("DATE")
            DatePicker("", selection: $editDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.border, lineWidth: 1.5))

            editSectionLabel("DESCRIPTION")
            editTextField(text: $editDetail, placeholder: "What was this expense for?")

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
                Toggle("", isOn: $editIsRecurring)
                    .labelsHidden()
                    .tint(AppColors.expense)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Edit Helpers

    private func editSectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppColors.textTertiary)
            .tracking(0.5)
    }

    private func editTextField(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 15))
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 1.5)
            )
    }

    private func editAmountField(color: Color) -> some View {
        HStack(spacing: 4) {
            Text(AppSettings.shared.currencySymbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
            TextField("0.00", text: $editAmount)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
                .keyboardType(.decimalPad)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1.5)
        )
    }

    // MARK: - State Management

    private func loadEditState() {
        editName = transaction.name ?? ""
        editAmount = String(format: "%.0f", transaction.amount)
        editDate = transaction.date ?? Date()
        editEndDate = transaction.endDate ?? Date()
        editDetail = transaction.detail ?? ""
        editIsRecurring = transaction.isRecurring
        editCategory = ExpenseCategory(rawValue: transaction.category ?? "") ?? .cleaning
        editPlatform = IncomePlatform(rawValue: transaction.platform ?? "") ?? .airbnb
    }

    private func saveEdits() {
        guard let parsedAmount = Double(editAmount), parsedAmount > 0 else { return }

        if transaction.isIncome {
            viewModel.updateTransaction(
                transaction,
                name: editName.isEmpty ? "Guest" : editName,
                amount: parsedAmount,
                date: editDate,
                endDate: editEndDate,
                category: nil,
                platform: editPlatform.rawValue,
                detail: editDetail,
                isRecurring: false
            )
        } else {
            viewModel.updateTransaction(
                transaction,
                name: editCategory.label,
                amount: parsedAmount,
                date: editDate,
                endDate: nil,
                category: editCategory.rawValue,
                platform: nil,
                detail: editDetail,
                isRecurring: editIsRecurring
            )
        }

        withAnimation(.easeInOut(duration: 0.2)) { isEditing = false }
    }
}
