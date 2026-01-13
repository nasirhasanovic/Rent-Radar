import SwiftUI
import CoreData

struct LogBookingView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PropertyEntity.createdAt, ascending: false)],
        animation: .default
    )
    private var properties: FetchedResults<PropertyEntity>

    let onDismiss: () -> Void
    var preselectedProperty: PropertyEntity?

    @State private var viewModel = LogBookingViewModel()
    @State private var showPropertyDropdown = false
    @State private var showDatePicker = false
    private let settings = AppSettings.shared

    private var hasPropertySelected: Bool {
        viewModel.selectedProperty != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    propertySelector

                    formContent
                        .opacity(showPropertyDropdown ? 0.3 : (hasPropertySelected ? 1 : 0.4))
                        .allowsHitTesting(!showPropertyDropdown && hasPropertySelected)
                        .animation(.easeInOut(duration: 0.2), value: showPropertyDropdown)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(AppColors.background)
        .onAppear {
            if let property = preselectedProperty {
                viewModel.selectProperty(property)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheetView(
                displayedMonth: $viewModel.displayedMonth,
                checkInDate: $viewModel.checkInDate,
                checkOutDate: $viewModel.checkOutDate,
                bookedDays: viewModel.bookedDays,
                blockedDays: viewModel.blockedDays,
                onConfirm: { showDatePicker = false }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Form Content

    @ViewBuilder
    private var formContent: some View {
        Group {
            guestNameField
            dateRow
            platformSelector
            pricingSection
            guestCountSection
            notesSection

            if !hasPropertySelected {
                hintMessage
            }

            saveButton
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "F0F0F0"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("Log Booking")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            Text(hasPropertySelected ? "Draft" : "New")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Property Thumbnail Helper

    @ViewBuilder
    private func propertyThumbnail(for property: PropertyEntity, size: CGFloat = 46) -> some View {
        if let coverImage = property.coverImage {
            Image(uiImage: coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            ZStack {
                LinearGradient(
                    colors: property.illustrationGradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Image(systemName: property.source.icon)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Property Selector with Inline Dropdown

    private var propertySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Property")

            if showPropertyDropdown {
                // Expanded dropdown - unified container
                VStack(spacing: 0) {
                    ForEach(Array(properties.enumerated()), id: \.element.objectID) { index, property in
                        let isFirst = index == 0

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.selectProperty(property)
                                showPropertyDropdown = false
                            }
                        } label: {
                            HStack(spacing: 12) {
                                propertyThumbnail(for: property)
                                    .scaleEffect(showPropertyDropdown ? 1 : 0.8)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.04), value: showPropertyDropdown)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(property.displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppColors.textPrimary)
                                    Text("\(property.shortAddress) · \(property.type == .shortTerm ? "Short-term" : "Long-term")")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppColors.textTertiary)
                                }

                                Spacer()

                                propertyStatusBadge(for: property)

                                if isFirst {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppColors.textTertiary)
                                        .padding(.leading, 4)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(.white)
                            .opacity(showPropertyDropdown ? 1 : 0)
                            .offset(y: showPropertyDropdown ? 0 : -8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8).delay(Double(index) * 0.03), value: showPropertyDropdown)
                        }
                        .buttonStyle(.plain)

                        if index < properties.count - 1 {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.teal500, lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                ))
            } else {
                // Collapsed state - single button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPropertyDropdown = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        if let property = viewModel.selectedProperty {
                            propertyThumbnail(for: property)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(property.displayName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppColors.textPrimary)
                                Text("\(property.shortAddress) · \(property.type == .shortTerm ? "Short-term" : "Long-term")")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.textTertiary)
                            }

                            Spacer()

                            propertyStatusBadge(for: property)

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppColors.textTertiary)
                                .padding(.leading, 4)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: "F3F4F6"))
                                    .frame(width: 46, height: 46)

                                Image(systemName: "house")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppColors.textTertiary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Select a property")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Tap to choose from your listings")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "D1D5DB"))
                            }

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        hasPropertySelected
                            ? nil
                            : RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                .foregroundStyle(Color(hex: "D1D5DB"))
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Property Status Badge

    private func propertyStatusBadge(for property: PropertyEntity) -> some View {
        let isBooked = isPropertyBooked(property)
        let statusText = property.type == .shortTerm
            ? (isBooked ? "Booked" : "Available")
            : (isBooked ? "Occupied" : "Vacant")
        let statusColor = property.type == .shortTerm
            ? (isBooked ? Color(hex: "10B981") : Color(hex: "F59E0B"))
            : (isBooked ? AppColors.info : Color(hex: "F59E0B"))

        return HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(statusText)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(statusColor)
        }
    }

    private func isPropertyBooked(_ property: PropertyEntity) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let transactions = property.transactions?.allObjects as? [TransactionEntity] ?? []

        return transactions.contains { tx in
            guard tx.isIncome, let start = tx.date else { return false }
            let end = tx.endDate ?? start
            return today >= Calendar.current.startOfDay(for: start) && today <= Calendar.current.startOfDay(for: end)
        }
    }

    // MARK: - Guest Name

    private var guestNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Guest Name")

            HStack(spacing: 10) {
                Image(systemName: "person")
                    .font(.system(size: 16))
                    .foregroundStyle(hasPropertySelected ? AppColors.textTertiary : Color(hex: "D1D5DB"))

                if hasPropertySelected {
                    TextField("Enter guest name", text: $viewModel.guestName)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.textPrimary)
                } else {
                    Text("Enter guest name")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "D1D5DB"))
                }
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        }
    }

    // MARK: - Date Row

    private var dateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Dates")

            Button {
                if hasPropertySelected {
                    showDatePicker = true
                }
            } label: {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Check-in card
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CHECK-IN")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.5)
                                .foregroundStyle(hasPropertySelected ? Color(hex: "0D9488") : Color(hex: "D1D5DB"))

                            if hasPropertySelected, let checkIn = viewModel.checkInDate {
                                Text(formatDateShort(checkIn))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color(hex: "0D9488"))
                                Text(formatDayName(checkIn))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "0D9488").opacity(0.7))
                            } else {
                                Text("Select")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(hex: "D1D5DB"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(hasPropertySelected ? Color(hex: "F0FDFA") : Color(hex: "F9FAFB"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(hasPropertySelected ? Color(hex: "0D9488") : Color(hex: "E5E7EB"), lineWidth: 1.5)
                        )

                        // Arrow
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(hasPropertySelected ? Color(hex: "0D9488") : Color(hex: "D1D5DB"))

                        // Check-out card
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CHECK-OUT")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.5)
                                .foregroundStyle(hasPropertySelected ? Color(hex: "2DD4A8") : Color(hex: "D1D5DB"))

                            if hasPropertySelected, let checkOut = viewModel.checkOutDate {
                                Text(formatDateShort(checkOut))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color(hex: "2DD4A8"))
                                Text(formatDayName(checkOut))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "2DD4A8").opacity(0.7))
                            } else {
                                Text("Select")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color(hex: "D1D5DB"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(hasPropertySelected ? Color(hex: "F0FDFA") : Color(hex: "F9FAFB"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: hasPropertySelected ? [5, 3] : []))
                                .foregroundStyle(hasPropertySelected ? Color(hex: "2DD4A8") : Color(hex: "E5E7EB"))
                        )
                    }

                    // Nights badge
                    if viewModel.nights > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(viewModel.nights) nights")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "0D9488"), Color(hex: "10B981")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                    }
                }
                .padding(14)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Date Formatting Helpers

    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    // MARK: - Platform Selector

    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Platform")

            HStack(spacing: 8) {
                ForEach(viewModel.platforms, id: \.self) { platform in
                    Button {
                        if hasPropertySelected {
                            viewModel.selectedPlatform = platform
                        }
                    } label: {
                        Text(platform)
                            .font(.system(size: 12, weight: hasPropertySelected && viewModel.selectedPlatform == platform ? .bold : .semibold))
                            .foregroundStyle(
                                hasPropertySelected
                                    ? (viewModel.selectedPlatform == platform ? .white : Color(hex: "6B7280"))
                                    : Color(hex: "D1D5DB")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                hasPropertySelected && viewModel.selectedPlatform == platform
                                    ? Color(hex: "0D9488")
                                    : .white
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        hasPropertySelected && viewModel.selectedPlatform == platform
                                            ? Color(hex: "0D9488")
                                            : Color(hex: "E5E7EB"),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Pricing")

            VStack(spacing: 0) {
                // Nightly rate - editable
                nightlyRateRow
                Divider().padding(.horizontal, 16)

                // Cleaning fee - toggleable
                cleaningFeeRow
                Divider().padding(.horizontal, 16)

                // Platform fee - toggleable
                platformFeeRow

                // Total
                HStack {
                    Text("Total payout")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(hasPropertySelected ? Color(hex: "0D9488") : Color(hex: "D1D5DB"))
                    Spacer()
                    Text(hasPropertySelected ? viewModel.formattedTotal : "—")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(hasPropertySelected ? Color(hex: "0D9488") : Color(hex: "D1D5DB"))
                }
                .padding(14)
                .background(hasPropertySelected ? Color(hex: "F0FDF9") : Color(hex: "F9FAFB"))
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        }
    }

    private var nightlyRateRow: some View {
        HStack {
            Text("Nightly rate")
                .font(.system(size: 13))
                .foregroundStyle(hasPropertySelected ? Color(hex: "6B7280") : Color(hex: "D1D5DB"))
            Spacer()
            HStack(spacing: 2) {
                Text("$")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(hasPropertySelected ? AppColors.textPrimary : Color(hex: "D1D5DB"))
                if hasPropertySelected {
                    TextField("0", value: $viewModel.nightlyRate, format: .number)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                } else {
                    Text("0.00")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "D1D5DB"))
                }
            }
        }
        .padding(14)
    }

    private var cleaningFeeRow: some View {
        HStack {
            HStack(spacing: 8) {
                Text("Cleaning fee")
                    .font(.system(size: 13))
                    .foregroundStyle(hasPropertySelected ? Color(hex: "6B7280") : Color(hex: "D1D5DB"))

                if hasPropertySelected {
                    Button {
                        viewModel.toggleCleaningFee()
                    } label: {
                        Image(systemName: viewModel.includeCleaningFee ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(viewModel.includeCleaningFee ? Color(hex: "EF4444") : AppColors.teal500)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            if viewModel.includeCleaningFee && hasPropertySelected {
                HStack(spacing: 2) {
                    Text("$")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    TextField("0", value: $viewModel.cleaningFee, format: .number)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
            } else {
                Text(hasPropertySelected ? "—" : "$0.00")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "D1D5DB"))
            }
        }
        .padding(14)
        .animation(.easeInOut(duration: 0.2), value: viewModel.includeCleaningFee)
    }

    private var platformFeeRow: some View {
        HStack {
            HStack(spacing: 8) {
                if viewModel.includePlatformFee && hasPropertySelected {
                    HStack(spacing: 2) {
                        Text("Platform fee (")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6B7280"))
                        TextField("15", value: $viewModel.platformFeePercent, format: .number)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 28)
                        Text("%)")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6B7280"))
                    }
                } else {
                    Text("Platform fee")
                        .font(.system(size: 13))
                        .foregroundStyle(hasPropertySelected ? Color(hex: "6B7280") : Color(hex: "D1D5DB"))
                }

                if hasPropertySelected {
                    Button {
                        viewModel.togglePlatformFee()
                    } label: {
                        Image(systemName: viewModel.includePlatformFee ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(viewModel.includePlatformFee ? Color(hex: "EF4444") : AppColors.teal500)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            if viewModel.includePlatformFee && hasPropertySelected {
                Text(viewModel.formattedPlatformFee)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "EF4444"))
            } else {
                Text(hasPropertySelected ? "—" : "-$0.00")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "D1D5DB"))
            }
        }
        .padding(14)
        .animation(.easeInOut(duration: 0.2), value: viewModel.includePlatformFee)
    }

    // MARK: - Guest Count

    private var guestCountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Guests")

            HStack {
                Text("Number of guests")
                    .font(.system(size: 13))
                    .foregroundStyle(hasPropertySelected ? Color(hex: "6B7280") : Color(hex: "D1D5DB"))

                Spacer()

                HStack(spacing: 14) {
                    Button {
                        if hasPropertySelected {
                            viewModel.decrementGuests()
                        }
                    } label: {
                        Text("-")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(hasPropertySelected ? Color(hex: "6B7280") : Color(hex: "D1D5DB"))
                            .frame(width: 30, height: 30)
                            .background(Color(hex: "F3F4F6"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Text("\(viewModel.guestCount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(hasPropertySelected ? AppColors.textPrimary : Color(hex: "D1D5DB"))
                        .frame(minWidth: 20)

                    Button {
                        if hasPropertySelected {
                            viewModel.incrementGuests()
                        }
                    } label: {
                        Text("+")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(hasPropertySelected ? Color(hex: "0D9488") : Color(hex: "D1D5DB"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Notes (optional)")

            if hasPropertySelected {
                TextField("Add any notes about this booking...", text: $viewModel.notes, axis: .vertical)
                    .font(.system(size: 13))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(3...6)
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
            } else {
                Text("Add any notes about this booking...")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "D1D5DB"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
            }
        }
    }

    // MARK: - Hint Message

    private var hintMessage: some View {
        Text("Select a property above to start logging")
            .font(.system(size: 12))
            .foregroundStyle(AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            if viewModel.save(context: context) {
                onDismiss()
            }
        } label: {
            Text("Save Booking")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(hasPropertySelected ? .white : AppColors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    hasPropertySelected
                        ? AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "0D9488"), Color(hex: "10B981")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        : AnyShapeStyle(Color(hex: "E5E7EB"))
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(
                    color: hasPropertySelected ? Color(hex: "0D9488").opacity(0.3) : .clear,
                    radius: 12, y: 4
                )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(AppColors.textTertiary)
            .textCase(.uppercase)
            .tracking(0.8)
    }
}

#Preview {
    LogBookingView(onDismiss: {})
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
