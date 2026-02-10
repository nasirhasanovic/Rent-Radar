import SwiftUI
import CoreData
import QuickLook
import PDFKit

struct ExportDataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var onDismiss: () -> Void

    @State private var exportState: ExportState = .selection
    @State private var selectedDataTypes: Set<ExportDataType> = [.bookings, .income]
    @State private var selectedPeriod: TimePeriod = .thisMonth
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var selectedPropertyFilter: PropertyFilter = .all
    @State private var selectedProperties: Set<NSManagedObjectID> = []
    @State private var showPropertyPicker = false
    @State private var showCustomDatePicker = false
    @State private var customStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var customEndDate: Date = Date()
    @State private var generationProgress: Double = 0
    @State private var generatedPDFURL: URL?
    @State private var showPDFPreview = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PropertyEntity.createdAt, ascending: false)],
        animation: .default
    )
    private var properties: FetchedResults<PropertyEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)],
        animation: .default
    )
    private var transactions: FetchedResults<TransactionEntity>

    private enum ExportState {
        case selection
        case generating
        case success
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            switch exportState {
            case .selection:
                selectionContent
            case .generating:
                generatingContent
            case .success:
                successContent
            }
        }
        .background(AppColors.background)
        .quickLookPreview(previewURL)
    }

    private var previewURL: Binding<URL?> {
        Binding(
            get: { showPDFPreview ? generatedPDFURL : nil },
            set: { _ in showPDFPreview = false }
        )
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: handleBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Text("Export Data")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func handleBack() {
        switch exportState {
        case .selection:
            onDismiss()
        case .generating:
            withAnimation { exportState = .selection }
        case .success:
            onDismiss()
        }
    }

    // MARK: - Selection Content

    private var selectionContent: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    descriptionCard
                    whatToExportSection
                    timePeriodSection
                    propertiesSection
                    formatSection
                }
                .padding(.bottom, 120)
            }

            selectionBottomButton
        }
    }

    private var descriptionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.teal500)
                    .frame(width: 36, height: 36)
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Export your data")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "0A3D3D"))

                Text("Choose what to export and the time period. Your data will be generated as a PDF report.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .background(AppColors.tintedTeal)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private var whatToExportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT TO EXPORT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B7280"))
                .kerning(0.5)

            VStack(spacing: 8) {
                ForEach(ExportDataType.allCases, id: \.self) { dataType in
                    ExportOptionRow(
                        dataType: dataType,
                        isSelected: selectedDataTypes.contains(dataType),
                        onTap: { toggleDataType(dataType) }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var timePeriodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TIME PERIOD")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B7280"))
                .kerning(0.5)

            FlowLayout(spacing: 8) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    PeriodChip(
                        period: period,
                        isSelected: selectedPeriod == period,
                        onTap: {
                            selectedPeriod = period
                            if period == .custom {
                                showCustomDatePicker = true
                            }
                        }
                    )
                }
            }

            // Date range info
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "9CA3AF"))

                Text(currentDateRangeText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6B7280"))

                Spacer()

                if selectedPeriod == .custom {
                    Button {
                        showCustomDatePicker = true
                    } label: {
                        Text("Edit")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.teal500)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .fullScreenCover(isPresented: $showCustomDatePicker) {
            CustomDateRangeView(
                startDate: $customStartDate,
                endDate: $customEndDate,
                onDismiss: { showCustomDatePicker = false }
            )
        }
    }

    private var currentDateRangeText: String {
        if selectedPeriod == .custom {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return "\(formatter.string(from: customStartDate)) – \(formatter.string(from: customEndDate))"
        }
        return selectedPeriod.dateRangeText
    }

    private var propertiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROPERTIES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B7280"))
                .kerning(0.5)

            Button {
                showPropertyPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.teal500)

                    Text(propertyFilterText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
                .padding(14)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "E5E7EB"), lineWidth: 1.5)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .sheet(isPresented: $showPropertyPicker) {
            propertyPickerSheet
        }
    }

    private var propertyFilterText: String {
        if selectedProperties.isEmpty {
            return "All Properties (\(properties.count))"
        } else if selectedProperties.count == 1 {
            if let prop = properties.first(where: { selectedProperties.contains($0.objectID) }) {
                return prop.displayName
            }
            return "1 Property"
        } else {
            return "\(selectedProperties.count) Properties"
        }
    }

    private var propertiesSummaryText: String {
        if selectedProperties.isEmpty {
            return "All (\(properties.count))"
        } else if selectedProperties.count == 1 {
            if let prop = properties.first(where: { selectedProperties.contains($0.objectID) }) {
                return prop.displayName
            }
            return "1 Property"
        } else {
            return "\(selectedProperties.count) Properties"
        }
    }

    private var propertyPickerSheet: some View {
        NavigationStack {
            List {
                // All Properties option
                Button {
                    selectedProperties.removeAll()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.tintedTeal)
                                .frame(width: 40, height: 40)
                            Image(systemName: "house.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(AppColors.teal500)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("All Properties")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                            Text("\(properties.count) properties")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(hex: "6B7280"))
                        }

                        Spacer()

                        if selectedProperties.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(AppColors.teal500)
                        } else {
                            Circle()
                                .stroke(Color(hex: "D1D5DB"), lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)

                // Individual properties
                ForEach(properties, id: \.objectID) { property in
                    Button {
                        toggleProperty(property)
                    } label: {
                        HStack(spacing: 12) {
                            // Property thumbnail
                            ZStack {
                                if let coverImage = property.coverImage {
                                    Image(uiImage: coverImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    LinearGradient(
                                        colors: property.illustrationGradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        Image(systemName: "house.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.white.opacity(0.7))
                                    )
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(property.displayName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(property.shortAddress)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "6B7280"))
                            }

                            Spacer()

                            if selectedProperties.contains(property.objectID) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(AppColors.teal500)
                            } else {
                                Circle()
                                    .stroke(Color(hex: "D1D5DB"), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .background(AppColors.background)
            .navigationTitle("Select Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showPropertyPicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggleProperty(_ property: PropertyEntity) {
        if selectedProperties.contains(property.objectID) {
            selectedProperties.remove(property.objectID)
        } else {
            selectedProperties.insert(property.objectID)
        }
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EXPORT FORMAT")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B7280"))
                .kerning(0.5)

            HStack(spacing: 8) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    FormatOption(
                        format: format,
                        isSelected: selectedFormat == format,
                        onTap: { selectedFormat = format }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var selectionBottomButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                startGenerating()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 16))

                    Text("Generate Report")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedDataTypes.isEmpty)
            .opacity(selectedDataTypes.isEmpty ? 0.6 : 1)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(AppColors.elevated)
    }

    // MARK: - Generating Content

    private var generatingContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // Animated circle with icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.tintedTeal, Color(hex: "D1FAE5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Spinning border
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(AppColors.teal500, lineWidth: 3)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(generationProgress * 360))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: generationProgress)

                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.teal500)
                }
                .padding(.bottom, 32)

                Text("Generating Report")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.bottom, 8)

                Text("Compiling your \(selectedDataTypesText) data for \(selectedPeriod.displayName.lowercased())...")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 32)

                // Progress bar
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "F3F4F6"))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [AppColors.teal600, AppColors.teal300],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * generationProgress, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(Int(generationProgress * 100))%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.teal500)
                }
                .padding(.horizontal, 40)

                Spacer()
            }

            // Export Summary Card
            exportSummaryCard

            // Cancel button
            generatingBottomButton
        }
    }

    private var selectedDataTypesText: String {
        selectedDataTypes.map { $0.displayName.lowercased() }.joined(separator: " and ")
    }

    private var exportSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXPORT SUMMARY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B7280"))
                .kerning(0.5)

            VStack(spacing: 0) {
                SummaryRow(label: "Data", value: selectedDataTypes.map { $0.displayName }.joined(separator: ", "))
                Divider().padding(.vertical, 10)
                SummaryRow(label: "Period", value: selectedPeriod.displayName)
                Divider().padding(.vertical, 10)
                SummaryRow(label: "Properties", value: propertiesSummaryText)
                Divider().padding(.vertical, 10)
                HStack {
                    Text("Format")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "6B7280"))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.error)
                        Text(selectedFormat.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
            .padding(16)
            .background(Color(hex: "F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
    }

    private var generatingBottomButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                withAnimation { exportState = .selection }
            } label: {
                Text("Cancel")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(hex: "E5E7EB"), lineWidth: 1.5)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(AppColors.elevated)
    }

    // MARK: - Success Content

    private var successContent: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Success header
                    VStack(spacing: 0) {
                        Spacer().frame(height: 48)

                        // Success circle
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "D1FAE5"), Color(hex: "A7F3D0")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(AppColors.success)
                        }
                        .padding(.bottom, 24)

                        Text("Report Ready!")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(AppColors.textPrimary)
                            .padding(.bottom, 6)

                        Text("Your export has been generated successfully and is ready to download.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "6B7280"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // File preview card
                    filePreviewCard
                        .padding(.top, 24)

                    // Report highlights
                    reportHighlights
                        .padding(.top, 20)
                }
                .padding(.bottom, 160)
            }

            successBottomButtons
        }
    }

    private var filePreviewCard: some View {
        HStack(spacing: 16) {
            // PDF icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 52, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "FCA5A5"), lineWidth: 1.5)
                    )

                VStack(spacing: 2) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.error)

                    Text("PDF")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundStyle(AppColors.error)
                }

                // Corner fold
                VStack {
                    HStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "FCA5A5"))
                            .frame(width: 14, height: 14)
                    }
                    Spacer()
                }
                .frame(width: 52, height: 64)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("RentDar-Report-\(currentMonthYear).pdf")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Text(pdfFileInfo)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "6B7280"))

                HStack(spacing: 6) {
                    ForEach(Array(selectedDataTypes), id: \.self) { dataType in
                        Text(dataType.displayName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppColors.teal500)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppColors.tintedTeal)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color(hex: "F9FAFB"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMyyyy"
        return formatter.string(from: Date())
    }

    private var pdfFileInfo: String {
        guard let url = generatedPDFURL else {
            return String(localized: "Generating...")
        }

        // Get file size
        var sizeString = ""
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64 {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            sizeString = formatter.string(fromByteCount: fileSize)
        }

        // Get page count
        var pageCount = 0
        if let pdfDocument = PDFDocument(url: url) {
            pageCount = pdfDocument.pageCount
        }

        if !sizeString.isEmpty && pageCount > 0 {
            return String(localized: "\(sizeString) · \(pageCount) pages")
        } else if !sizeString.isEmpty {
            return sizeString
        } else if pageCount > 0 {
            return String(localized: "\(pageCount) pages")
        }
        return String(localized: "PDF Report")
    }

    private var reportHighlights: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REPORT HIGHLIGHTS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B7280"))
                .kerning(0.5)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if selectedDataTypes.contains(.bookings) {
                    HighlightCard(
                        title: String(localized: "Total Bookings"),
                        value: "\(totalBookings)",
                        subtitle: periodDisplayText,
                        isTeal: true
                    )
                }

                if selectedDataTypes.contains(.income) {
                    HighlightCard(
                        title: String(localized: "Total Income"),
                        value: "\(AppSettings.shared.currencySymbol)\(totalIncome.formatted())",
                        subtitle: "\(selectedPropertiesCount) \(selectedPropertiesCount == 1 ? String(localized: "property") : String(localized: "properties"))",
                        isTeal: true
                    )
                }

                if selectedDataTypes.contains(.expenses) {
                    HighlightCard(
                        title: String(localized: "Total Expenses"),
                        value: "\(AppSettings.shared.currencySymbol)\(totalExpenses.formatted())",
                        subtitle: periodDisplayText,
                        isTeal: false
                    )
                }

                if selectedDataTypes.contains(.occupancy) || selectedDataTypes.contains(.bookings) {
                    HighlightCard(
                        title: String(localized: "Nights Booked"),
                        value: "\(totalNights)",
                        subtitle: selectedPropertiesCount == 1 ? String(localized: "This property") : String(localized: "Across all units"),
                        isTeal: false
                    )
                }

                if selectedDataTypes.contains(.bookings) || selectedDataTypes.contains(.income) {
                    HighlightCard(
                        title: String(localized: "Top Platform"),
                        value: topPlatform,
                        subtitle: totalBookings > 0 ? "\(topPlatformPercent)% \(String(localized: "of bookings"))" : String(localized: "No bookings"),
                        isTeal: false
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Filtered Data

    private var filteredTransactions: [TransactionEntity] {
        let calendar = Calendar.current
        let (startDate, endDate) = dateRangeForPeriod

        return transactions.filter { tx in
            // Filter by date
            guard let txDate = tx.date else { return false }
            let txDay = calendar.startOfDay(for: txDate)
            guard txDay >= startDate && txDay <= endDate else { return false }

            // Filter by property if specific properties are selected
            if !selectedProperties.isEmpty {
                guard let propertyId = tx.property?.objectID else { return false }
                guard selectedProperties.contains(propertyId) else { return false }
            }

            return true
        }
    }

    private var dateRangeForPeriod: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch selectedPeriod {
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .day, value: 6, to: start)!
            return (calendar.startOfDay(for: start), calendar.startOfDay(for: end))
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (calendar.startOfDay(for: start), calendar.startOfDay(for: end))
        case .lastMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            let end = calendar.date(byAdding: .day, value: -1, to: thisMonthStart)!
            return (calendar.startOfDay(for: start), calendar.startOfDay(for: end))
        case .last3Months:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -3, to: thisMonthStart)!
            let end = calendar.date(byAdding: .day, value: -1, to: thisMonthStart)!
            return (calendar.startOfDay(for: start), calendar.startOfDay(for: end))
        case .thisYear:
            let start = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 1, day: 1))!
            let end = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 12, day: 31))!
            return (calendar.startOfDay(for: start), calendar.startOfDay(for: end))
        case .custom:
            return (calendar.startOfDay(for: customStartDate), calendar.startOfDay(for: customEndDate))
        }
    }

    private var selectedPropertiesCount: Int {
        selectedProperties.isEmpty ? properties.count : selectedProperties.count
    }

    private var totalBookings: Int {
        filteredTransactions.filter { $0.isIncome }.count
    }

    private var totalIncome: Int {
        Int(filteredTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount })
    }

    private var totalExpenses: Int {
        Int(filteredTransactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount })
    }

    private var totalNights: Int {
        filteredTransactions.filter { $0.isIncome }.reduce(0) { $0 + $1.nights }
    }

    private var topPlatform: String {
        let incomeTransactions = filteredTransactions.filter { $0.isIncome }
        guard !incomeTransactions.isEmpty else { return String(localized: "N/A") }
        let platforms = incomeTransactions.compactMap { $0.platform }
        guard !platforms.isEmpty else { return "Direct" }
        let counts = Dictionary(grouping: platforms) { $0 }.mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "Direct"
    }

    private var topPlatformPercent: Int {
        let incomeTransactions = filteredTransactions.filter { $0.isIncome }
        let total = incomeTransactions.count
        guard total > 0 else { return 0 }
        let platforms = incomeTransactions.compactMap { $0.platform }
        guard !platforms.isEmpty else { return 100 }
        let counts = Dictionary(grouping: platforms) { $0 }.mapValues { $0.count }
        let maxCount = counts.max(by: { $0.value < $1.value })?.value ?? 0
        return Int((Double(maxCount) / Double(total)) * 100)
    }

    private var periodDisplayText: String {
        if selectedPeriod == .custom {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: customStartDate)) – \(formatter.string(from: customEndDate))"
        }
        return selectedPeriod.shortText
    }

    private var successBottomButtons: some View {
        VStack(spacing: 0) {
            Divider()

            VStack(spacing: 10) {
                // Download button
                Button {
                    downloadReport()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 16))

                        Text("Download PDF")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Share and Email buttons
                HStack(spacing: 10) {
                    Button {
                        shareReport()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                            Text("Share")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: "374151"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.5)
                        )
                    }

                    Button {
                        emailReport()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 14))
                            Text("Email")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(Color(hex: "374151"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: "E5E7EB"), lineWidth: 1.5)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(AppColors.elevated)
    }

    // MARK: - Actions

    private func toggleDataType(_ type: ExportDataType) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if selectedDataTypes.contains(type) {
                selectedDataTypes.remove(type)
            } else {
                selectedDataTypes.insert(type)
            }
        }
    }

    private func startGenerating() {
        withAnimation { exportState = .generating }
        generationProgress = 0

        // Animate progress while generating PDF in background
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if generationProgress < 0.9 {
                generationProgress += 0.015
            }
        }

        // Generate PDF in background
        DispatchQueue.global(qos: .userInitiated).async {
            let (startDate, endDate) = dateRangeForPeriod

            // Get selected properties
            let selectedProps: [PropertyEntity]
            if selectedProperties.isEmpty {
                selectedProps = Array(properties)
            } else {
                selectedProps = properties.filter { selectedProperties.contains($0.objectID) }
            }

            // Create report data
            let reportData = PDFReportGenerator.ReportData(
                periodStart: startDate,
                periodEnd: endDate,
                properties: selectedProps,
                transactions: Array(filteredTransactions),
                selectedDataTypes: Set(selectedDataTypes.map { $0.rawValue }),
                currencySymbol: AppSettings.shared.currencySymbol
            )

            // Generate PDF
            let pdfURL = PDFReportGenerator.generatePDF(data: reportData)

            DispatchQueue.main.async {
                progressTimer.invalidate()
                generationProgress = 1.0
                generatedPDFURL = pdfURL

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { exportState = .success }
                }
            }
        }
    }

    private func downloadReport() {
        if let url = generatedPDFURL {
            showPDFPreview = true
        }
    }

    private func shareReport() {
        guard let url = generatedPDFURL else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func emailReport() {
        shareReport() // Use share sheet which includes email option
    }
}

// MARK: - Supporting Views

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "6B7280"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

private struct HighlightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let isTeal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "6B7280"))

            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(isTeal ? Color(hex: "0A3D3D") : AppColors.textPrimary)

            Text(subtitle)
                .font(.system(size: 10, weight: isTeal ? .semibold : .medium))
                .foregroundStyle(isTeal ? AppColors.success : Color(hex: "6B7280"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(isTeal ? AppColors.tintedTeal : Color(hex: "F9FAFB"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Data Types

enum ExportDataType: String, CaseIterable {
    case bookings = "Bookings"
    case income = "Income"
    case expenses = "Expenses"
    case occupancy = "Occupancy"

    var displayName: String {
        switch self {
        case .bookings: return String(localized: "Bookings")
        case .income: return String(localized: "Income")
        case .expenses: return String(localized: "Expenses")
        case .occupancy: return String(localized: "Occupancy")
        }
    }

    var subtitle: String {
        switch self {
        case .bookings: return String(localized: "Guest names, dates, platforms, status")
        case .income: return String(localized: "Revenue by property, platform breakdown")
        case .expenses: return String(localized: "Cleaning, maintenance, fees, taxes")
        case .occupancy: return String(localized: "Occupancy rates, nights booked, gaps")
        }
    }

    var icon: String {
        switch self {
        case .bookings: return "calendar"
        case .income: return "dollarsign.circle.fill"
        case .expenses: return "doc.text.fill"
        case .occupancy: return "house.fill"
        }
    }
}

enum TimePeriod: String, CaseIterable {
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case last3Months = "Last 3 Months"
    case thisYear = "This Year"
    case custom = "Custom"

    var displayName: String {
        switch self {
        case .thisWeek: return String(localized: "This Week")
        case .thisMonth: return String(localized: "This Month")
        case .lastMonth: return String(localized: "Last Month")
        case .last3Months: return String(localized: "Last 3 Months")
        case .thisYear: return String(localized: "This Year")
        case .custom: return String(localized: "Custom")
        }
    }

    var shortText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let now = Date()
        let calendar = Calendar.current

        switch self {
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .day, value: 6, to: start)!
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        default:
            return rawValue
        }
    }

    var dateRangeText: String {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        switch self {
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .day, value: 6, to: start)!
            return "\(formatter.string(from: start)) – \(formatter.string(from: end)), \(calendar.component(.year, from: now))"
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return "\(formatter.string(from: start)) – \(formatter.string(from: end)), \(calendar.component(.year, from: now))"
        case .lastMonth:
            let start = calendar.date(byAdding: .month, value: -1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return "\(formatter.string(from: start)) – \(formatter.string(from: end)), \(calendar.component(.year, from: now))"
        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
            let end = calendar.date(byAdding: .day, value: -1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
            return "\(formatter.string(from: start)) – \(formatter.string(from: end)), \(calendar.component(.year, from: now))"
        case .thisYear:
            return "Jan 1 – Dec 31, \(calendar.component(.year, from: now))"
        case .custom:
            return String(localized: "Select date range")
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case pdf = "PDF"
    case csv = "CSV"
    case excel = "Excel"
}

enum PropertyFilter {
    case all
    case specific(PropertyEntity)
}

// MARK: - Export Option Row

private struct ExportOptionRow: View {
    let dataType: ExportDataType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? AppColors.tintedTeal : Color(hex: "F9FAFB"))
                        .frame(width: 36, height: 36)

                    Image(systemName: dataType.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(isSelected ? AppColors.teal500 : Color(hex: "9CA3AF"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(dataType.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(dataType.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "6B7280"))
                }

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? AppColors.teal500 : Color.clear)
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? AppColors.teal500 : Color(hex: "D1D5DB"), lineWidth: 1.5)
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(14)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.teal500 : Color(hex: "E5E7EB"), lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Period Chip

private struct PeriodChip: View {
    let period: TimePeriod
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if period == .custom {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? AppColors.teal500 : Color(hex: "6B7280"))
                }

                Text(period.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? AppColors.teal500 : Color(hex: "374151"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? AppColors.tintedTeal : Color(hex: "F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? AppColors.teal500 : Color(hex: "E5E7EB"), lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Format Option

private struct FormatOption: View {
    let format: ExportFormat
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? AppColors.teal500 : Color(hex: "9CA3AF"))

                    Text(format.rawValue)
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(isSelected ? AppColors.teal500 : Color(hex: "9CA3AF"))
                        .offset(y: 4)
                }

                Text(format.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? AppColors.teal500 : Color(hex: "6B7280"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? AppColors.tintedTeal : Color(hex: "F9FAFB"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.teal500 : Color(hex: "E5E7EB"), lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            height = y + rowHeight
        }
    }
}

// MARK: - Custom Date Range View

private struct CustomDateRangeView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    var onDismiss: () -> Void

    @State private var displayedMonth: Date = Date()
    @State private var selectingStart: Bool = true

    private let calendar = Calendar.current
    private let weekdays = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    dateFieldsSection
                    calendarSection
                    quickRangeSection
                }
                .padding(.bottom, 120)
            }

            bottomButton
        }
        .background(AppColors.background)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Text("Custom Range")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("Apply")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "2DD4A8"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Date Fields

    private var dateFieldsSection: some View {
        VStack(spacing: 16) {
            // Start Date
            VStack(alignment: .leading, spacing: 8) {
                Text("START DATE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .kerning(0.5)

                Button {
                    selectingStart = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundStyle(selectingStart ? AppColors.teal500 : Color(hex: "9CA3AF"))

                        Text(formatDate(startDate))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(selectingStart ? AppColors.teal500 : Color(hex: "9CA3AF"))
                    }
                    .padding(14)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectingStart ? AppColors.teal500 : Color(hex: "E5E7EB"), lineWidth: 1.5)
                    )
                }
            }

            // End Date
            VStack(alignment: .leading, spacing: 8) {
                Text("END DATE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .kerning(0.5)

                Button {
                    selectingStart = false
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundStyle(!selectingStart ? AppColors.teal500 : Color(hex: "9CA3AF"))

                        Text(formatDate(endDate))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(!selectingStart ? AppColors.teal500 : Color(hex: "9CA3AF"))
                    }
                    .padding(14)
                    .background(AppColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(!selectingStart ? AppColors.teal500 : Color(hex: "E5E7EB"), lineWidth: 1.5)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        VStack(spacing: 16) {
            // Month navigation
            HStack {
                Button {
                    shiftMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "374151"))
                        .frame(width: 32, height: 32)
                }

                Spacer()

                Text(monthYearString)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button {
                    shiftMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "374151"))
                        .frame(width: 32, height: 32)
                }
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(daysInMonth, id: \.self) { day in
                    if day == 0 {
                        Text("")
                            .frame(height: 40)
                    } else {
                        dayCell(day: day)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "F9FAFB"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private func dayCell(day: Int) -> some View {
        let date = dateForDay(day)
        let isInRange = isDateInRange(date)
        let isStart = calendar.isDate(date, inSameDayAs: startDate)
        let isEnd = calendar.isDate(date, inSameDayAs: endDate)

        return Button {
            selectDate(date)
        } label: {
            ZStack {
                if isStart || isEnd {
                    Circle()
                        .fill(AppColors.teal500)
                        .frame(width: 32, height: 32)
                } else if isInRange {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "E6FAF5"))
                        .frame(width: 32, height: 32)
                }

                Text("\(day)")
                    .font(.system(size: 13, weight: (isStart || isEnd) ? .bold : .medium))
                    .foregroundStyle(
                        (isStart || isEnd) ? .white :
                        isInRange ? AppColors.teal500 :
                        Color(hex: "374151")
                    )
            }
            .frame(height: 40)
        }
    }

    // MARK: - Quick Range

    private var quickRangeSection: some View {
        HStack(spacing: 8) {
            QuickRangeChip(title: String(localized: "Last 7 Days")) {
                setQuickRange(days: 7)
            }
            QuickRangeChip(title: String(localized: "Last 30 Days")) {
                setQuickRange(days: 30)
            }
            QuickRangeChip(title: String(localized: "Last 90 Days")) {
                setQuickRange(days: 90)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                onDismiss()
            } label: {
                Text("Apply Date Range")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(AppColors.elevated)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func shiftMonth(_ delta: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            withAnimation(.easeInOut(duration: 0.2)) {
                displayedMonth = newMonth
            }
        }
    }

    private var daysInMonth: [Int] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        // Weekday of first day (1 = Sunday, 2 = Monday, ...)
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        // Convert to Monday = 0
        let offset = (firstWeekday + 5) % 7

        var days: [Int] = Array(repeating: 0, count: offset)
        days.append(contentsOf: range.map { $0 })

        return days
    }

    private func dateForDay(_ day: Int) -> Date {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        var dateComponents = components
        dateComponents.day = day
        return calendar.date(from: dateComponents) ?? displayedMonth
    }

    private func isDateInRange(_ date: Date) -> Bool {
        date >= calendar.startOfDay(for: startDate) && date <= calendar.startOfDay(for: endDate)
    }

    private func selectDate(_ date: Date) {
        if selectingStart {
            startDate = date
            if date > endDate {
                endDate = date
            }
            selectingStart = false
        } else {
            if date < startDate {
                startDate = date
            } else {
                endDate = date
            }
        }
    }

    private func setQuickRange(days: Int) {
        endDate = Date()
        startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        displayedMonth = endDate
    }
}

// MARK: - Quick Range Chip

private struct QuickRangeChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "6B7280"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "F9FAFB"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    ExportDataView(onDismiss: {})
}
