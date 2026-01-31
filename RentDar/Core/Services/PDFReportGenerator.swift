import UIKit
import PDFKit
import CoreData

struct PDFReportGenerator {

    // MARK: - Report Data

    struct ReportData {
        let periodStart: Date
        let periodEnd: Date
        let properties: [PropertyEntity]
        let transactions: [TransactionEntity]
        let selectedDataTypes: Set<String>
        let currencySymbol: String

        var incomeTransactions: [TransactionEntity] {
            transactions.filter { $0.isIncome }
        }

        var totalIncome: Double {
            incomeTransactions.reduce(0) { $0 + $1.amount }
        }

        var totalBookings: Int {
            incomeTransactions.count
        }

        var totalNights: Int {
            incomeTransactions.reduce(0) { $0 + $1.nights }
        }

        var occupancyPercent: Int {
            let calendar = Calendar.current
            let totalDays = calendar.dateComponents([.day], from: periodStart, to: periodEnd).day ?? 1
            let totalPropertyDays = max(1, totalDays * properties.count)
            return min(100, Int((Double(totalNights) / Double(totalPropertyDays)) * 100))
        }

        // Income grouped by property
        var incomeByProperty: [(property: PropertyEntity, bookings: Int, nights: Int, income: Double)] {
            var result: [(PropertyEntity, Int, Int, Double)] = []
            for property in properties {
                let propertyTransactions = incomeTransactions.filter { $0.property?.objectID == property.objectID }
                let bookings = propertyTransactions.count
                let nights = propertyTransactions.reduce(0) { $0 + $1.nights }
                let income = propertyTransactions.reduce(0) { $0 + $1.amount }
                if bookings > 0 {
                    result.append((property, bookings, nights, income))
                }
            }
            return result.sorted { $0.3 > $1.3 }
        }

        // Platform breakdown
        var platformBreakdown: [(platform: String, bookings: Int, percent: Int, income: Double)] {
            let platforms = ["Airbnb", "Booking.com", "VRBO", "Direct"]
            var result: [(String, Int, Int, Double)] = []
            let total = totalBookings

            for platform in platforms {
                let platformTransactions = incomeTransactions.filter {
                    $0.platform?.lowercased() == platform.lowercased() ||
                    (platform == "Booking.com" && $0.platform?.lowercased() == "booking")
                }
                let bookings = platformTransactions.count
                if bookings > 0 {
                    let percent = total > 0 ? Int((Double(bookings) / Double(total)) * 100) : 0
                    let income = platformTransactions.reduce(0) { $0 + $1.amount }
                    result.append((platform, bookings, percent, income))
                }
            }
            return result.sorted { $0.1 > $1.1 }
        }

        var periodString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let yearFormatter = DateFormatter()
            yearFormatter.dateFormat = "yyyy"
            return "\(formatter.string(from: periodStart)) – \(formatter.string(from: periodEnd)), \(yearFormatter.string(from: periodEnd))"
        }

        var generatedDateString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: Date())
        }

        // MARK: - Expense Data

        var expenseTransactions: [TransactionEntity] {
            transactions.filter { !$0.isIncome }
        }

        var totalExpenses: Double {
            expenseTransactions.reduce(0) { $0 + $1.amount }
        }

        var netProfit: Double {
            totalIncome - totalExpenses
        }

        var profitMargin: Int {
            guard totalIncome > 0 else { return 0 }
            return Int((netProfit / totalIncome) * 100)
        }

        var avgExpensePerProperty: Double {
            guard properties.count > 0 else { return 0 }
            return totalExpenses / Double(properties.count)
        }

        var hasExpenses: Bool {
            selectedDataTypes.contains("Expenses") && !expenseTransactions.isEmpty
        }

        var hasBookingsOrIncome: Bool {
            (selectedDataTypes.contains("Bookings") || selectedDataTypes.contains("Income")) && !incomeTransactions.isEmpty
        }

        var reportSubtitle: String {
            var parts: [String] = []
            if selectedDataTypes.contains("Bookings") { parts.append("Bookings") }
            if selectedDataTypes.contains("Income") { parts.append("Income") }
            if selectedDataTypes.contains("Expenses") { parts.append("Expenses") }
            if selectedDataTypes.contains("Occupancy") { parts.append("Occupancy") }
            return parts.isEmpty ? "Summary" : parts.joined(separator: " & ") + " Summary"
        }

        // Expenses grouped by category
        var expensesByCategory: [(category: String, amount: Double, percent: Int, color: UIColor)] {
            let categories = ["Cleaning", "Platform Fees", "Maintenance", "Taxes", "Supplies", "Utilities", "Other"]
            let categoryColors: [String: UIColor] = [
                "Cleaning": UIColor(red: 139/255, green: 92/255, blue: 246/255, alpha: 1),
                "Platform Fees": UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1),
                "Maintenance": UIColor(red: 59/255, green: 130/255, blue: 246/255, alpha: 1),
                "Taxes": UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1),
                "Supplies": UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1),
                "Utilities": UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1),
                "Other": UIColor(red: 156/255, green: 163/255, blue: 175/255, alpha: 1)
            ]

            var result: [(String, Double, Int, UIColor)] = []
            let total = totalExpenses

            for category in categories {
                let categoryTransactions = expenseTransactions.filter {
                    $0.category?.lowercased().contains(category.lowercased()) == true ||
                    (category == "Other" && ($0.category == nil || $0.category?.isEmpty == true))
                }
                let amount = categoryTransactions.reduce(0) { $0 + $1.amount }
                if amount > 0 {
                    let percent = total > 0 ? Int((amount / total) * 100) : 0
                    let color = categoryColors[category] ?? categoryColors["Other"]!
                    result.append((category, amount, percent, color))
                }
            }
            return result.sorted { $0.1 > $1.1 }
        }

        // Property profit breakdown
        var propertyProfitBreakdown: [(property: PropertyEntity, income: Double, expenses: Double, profit: Double, margin: Int)] {
            var result: [(PropertyEntity, Double, Double, Double, Int)] = []
            for property in properties {
                let propIncome = incomeTransactions.filter { $0.property?.objectID == property.objectID }
                    .reduce(0) { $0 + $1.amount }
                let propExpenses = expenseTransactions.filter { $0.property?.objectID == property.objectID }
                    .reduce(0) { $0 + $1.amount }
                let profit = propIncome - propExpenses
                let margin = propIncome > 0 ? Int((profit / propIncome) * 100) : 0

                if propIncome > 0 || propExpenses > 0 {
                    result.append((property, propIncome, propExpenses, profit, margin))
                }
            }
            return result.sorted { $0.1 > $1.1 }
        }
    }

    // MARK: - Colors

    private static let tealDark = UIColor(red: 10/255, green: 61/255, blue: 61/255, alpha: 1)
    private static let tealMid = UIColor(red: 13/255, green: 124/255, blue: 110/255, alpha: 1)
    private static let tealLight = UIColor(red: 240/255, green: 253/255, blue: 250/255, alpha: 1)
    private static let gray50 = UIColor(red: 249/255, green: 250/255, blue: 251/255, alpha: 1)
    private static let gray100 = UIColor(red: 243/255, green: 244/255, blue: 246/255, alpha: 1)
    private static let gray200 = UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1)
    private static let gray500 = UIColor(red: 107/255, green: 114/255, blue: 128/255, alpha: 1)
    private static let gray700 = UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1)
    private static let gray900 = UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1)
    private static let success = UIColor(red: 5/255, green: 150/255, blue: 105/255, alpha: 1)
    private static let error = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)
    private static let errorDark = UIColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 1)
    private static let errorLight = UIColor(red: 254/255, green: 242/255, blue: 242/255, alpha: 1)
    private static let warning = UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1)
    private static let airbnbRed = UIColor(red: 255/255, green: 90/255, blue: 95/255, alpha: 1)
    private static let bookingBlue = UIColor(red: 0/255, green: 58/255, blue: 154/255, alpha: 1)
    private static let vrboBlue = UIColor(red: 49/255, green: 83/255, blue: 205/255, alpha: 1)

    // MARK: - Generate PDF

    static func generatePDF(data: ReportData) -> URL? {
        let pageWidth: CGFloat = 595  // A4
        let pageHeight: CGFloat = 842
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        // Check if this is expenses-only (expenses shown on cover page)
        let expensesOnly = data.hasExpenses && !data.hasBookingsOrIncome

        // Calculate total pages
        var totalPages = 1
        if data.hasBookingsOrIncome { totalPages += 1 }
        // Only add separate expenses page if there's also income data (not expenses-only)
        if data.hasExpenses && !expensesOnly { totalPages += 1 }
        // Add page for per-property breakdown if expenses-only with multiple properties
        if expensesOnly && data.properties.count > 1 { totalPages += 1 }

        let pdfData = renderer.pdfData { context in
            var currentPage = 1

            // Page 1: Cover & Summary (includes expenses if expenses-only)
            context.beginPage()
            drawCoverPage(in: context.cgContext, rect: pageRect, data: data, pageNumber: currentPage, totalPages: totalPages)
            currentPage += 1

            // Page 2: Bookings Detail (if bookings or income selected and have data)
            if data.hasBookingsOrIncome {
                context.beginPage()
                drawBookingsPage(in: context.cgContext, rect: pageRect, data: data, pageNumber: currentPage, totalPages: totalPages)
                currentPage += 1
            }

            // Page 3: Expenses Breakdown (only if also has income data - not expenses-only)
            if data.hasExpenses && !expensesOnly {
                context.beginPage()
                drawExpensesPage(in: context.cgContext, rect: pageRect, data: data, pageNumber: currentPage, totalPages: totalPages)
                currentPage += 1
            }

            // Additional page for per-property breakdown if expenses-only with multiple properties
            if expensesOnly && data.properties.count > 1 {
                context.beginPage()
                drawExpensesPropertyBreakdownPage(in: context.cgContext, rect: pageRect, data: data, pageNumber: currentPage, totalPages: totalPages)
            }
        }

        // Save to temporary file
        let fileName = "RentDar-Report-\(formattedFileName()).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try pdfData.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }

    private static func formattedFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMyyyy"
        return formatter.string(from: Date())
    }

    // MARK: - Page 1: Cover & Summary

    private static func drawCoverPage(in context: CGContext, rect: CGRect, data: ReportData, pageNumber: Int, totalPages: Int) {
        let margin: CGFloat = 48
        var y: CGFloat = 0

        // Header gradient background - taller to fit badges
        let headerHeight: CGFloat = 210
        drawGradientHeader(in: context, rect: CGRect(x: 0, y: 0, width: rect.width, height: headerHeight))

        // Logo
        y = 36
        drawLogo(in: context, at: CGPoint(x: margin, y: y))

        // Title
        y = 82
        drawText("Monthly Report", at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 28, weight: .heavy), color: .white)

        y = 116
        drawText(data.reportSubtitle, at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 14, weight: .regular), color: UIColor.white.withAlphaComponent(0.7))

        // Info badges
        y = 145
        drawInfoBadges(in: context, at: CGPoint(x: margin, y: y), data: data)

        // Check if this is an expenses-only report
        let expensesOnly = data.hasExpenses && !data.hasBookingsOrIncome

        if expensesOnly {
            // Expenses-only: Show expense metrics and detail on cover page
            y = headerHeight + 28
            drawText("EXPENSES OVERVIEW", at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

            y += 16
            drawExpensesSummaryCards(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)

            // Expenses Detail
            y += 100
            drawText("EXPENSES DETAIL", at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

            y += 14
            y = drawExpensesDetailTable(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data, maxRows: 6)

            // Category Summary
            y += 20
            drawText("BY CATEGORY", at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

            y += 14
            _ = drawExpensesCategoryTable(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)

        } else {
            // Normal flow: Show income metrics
            y = headerHeight + 28
            drawText("KEY METRICS", at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

            y += 20
            drawMetricsGrid(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)

            // Income by Property - only if bookings or income selected
            if data.hasBookingsOrIncome {
                y += 110
                drawText("INCOME BY PROPERTY", at: CGPoint(x: margin, y: y),
                         font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

                y += 16
                y = drawPropertyTable(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)

                // Platform Breakdown
                if !data.platformBreakdown.isEmpty {
                    y += 24
                    drawText("PLATFORM BREAKDOWN", at: CGPoint(x: margin, y: y),
                             font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

                    y += 16
                    drawPlatformBreakdown(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)
                }
            }
        }

        // Footer
        drawFooter(in: context, rect: rect, pageNumber: pageNumber, totalPages: totalPages)
    }

    // MARK: - Page 2: Bookings Detail

    private static func drawBookingsPage(in context: CGContext, rect: CGRect, data: ReportData, pageNumber: Int, totalPages: Int) {
        let margin: CGFloat = 48
        var y: CGFloat = 0

        // Mini header
        let miniHeaderHeight: CGFloat = 48
        drawGradientHeader(in: context, rect: CGRect(x: 0, y: 0, width: rect.width, height: miniHeaderHeight))

        // Mini logo
        drawText("RentDar", at: CGPoint(x: margin + 24, y: 16),
                 font: .systemFont(ofSize: 14, weight: .bold), color: .white)

        let periodText = "Monthly Report · \(data.periodString)"
        let periodWidth = periodText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 11)]).width
        drawText(periodText, at: CGPoint(x: rect.width - margin - periodWidth, y: 18),
                 font: .systemFont(ofSize: 11, weight: .regular), color: UIColor.white.withAlphaComponent(0.6))

        // Bookings Detail Table
        y = miniHeaderHeight + 24
        drawText("BOOKINGS DETAIL", at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

        y += 18
        drawBookingsTable(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)

        // Disclaimer
        y = rect.height - 120
        drawDisclaimer(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2)

        // Footer
        drawFooter(in: context, rect: rect, pageNumber: pageNumber, totalPages: totalPages)
    }

    // MARK: - Page 3: Expenses Breakdown

    private static func drawExpensesPage(in context: CGContext, rect: CGRect, data: ReportData, pageNumber: Int, totalPages: Int) {
        let margin: CGFloat = 48
        var y: CGFloat = 0

        // Mini header
        let miniHeaderHeight: CGFloat = 48
        drawGradientHeader(in: context, rect: CGRect(x: 0, y: 0, width: rect.width, height: miniHeaderHeight))

        // Mini logo
        drawText("RentDar", at: CGPoint(x: margin + 24, y: 16),
                 font: .systemFont(ofSize: 14, weight: .bold), color: .white)

        let periodText = "Monthly Report · \(data.periodString)"
        let periodWidth = periodText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 11)]).width
        drawText(periodText, at: CGPoint(x: rect.width - margin - periodWidth, y: 18),
                 font: .systemFont(ofSize: 11, weight: .regular), color: UIColor.white.withAlphaComponent(0.6))

        // Expenses Overview
        y = miniHeaderHeight + 20
        drawText("EXPENSES OVERVIEW", at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

        y += 16
        drawExpensesSummaryCards(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)

        // Expenses Detail (individual items)
        y += 90
        drawText("EXPENSES DETAIL", at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

        y += 14
        y = drawExpensesDetailTable(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data, maxRows: 8)

        // Category Summary
        y += 20
        drawText("BY CATEGORY", at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

        y += 14
        y = drawExpensesCategoryTable(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)

        // Per-property breakdown if multiple properties
        if data.properties.count > 1 {
            y += 20
            drawText("BY PROPERTY", at: CGPoint(x: margin, y: y),
                     font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

            y += 14
            drawPropertyExpensesSummary(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)
        }

        // Footer
        drawFooter(in: context, rect: rect, pageNumber: pageNumber, totalPages: totalPages)
    }

    // MARK: - Expenses Property Breakdown Page (for expenses-only with multiple properties)

    private static func drawExpensesPropertyBreakdownPage(in context: CGContext, rect: CGRect, data: ReportData, pageNumber: Int, totalPages: Int) {
        let margin: CGFloat = 48
        var y: CGFloat = 0

        // Mini header
        let miniHeaderHeight: CGFloat = 48
        drawGradientHeader(in: context, rect: CGRect(x: 0, y: 0, width: rect.width, height: miniHeaderHeight))

        // Mini logo
        drawText("RentDar", at: CGPoint(x: margin + 24, y: 16),
                 font: .systemFont(ofSize: 14, weight: .bold), color: .white)

        let periodText = "Expenses Report · \(data.periodString)"
        let periodWidth = periodText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 11)]).width
        drawText(periodText, at: CGPoint(x: rect.width - margin - periodWidth, y: 18),
                 font: .systemFont(ofSize: 11, weight: .regular), color: UIColor.white.withAlphaComponent(0.6))

        // Per-property breakdown
        y = miniHeaderHeight + 24
        drawText("EXPENSES BY PROPERTY", at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 11, weight: .bold), color: gray500)

        y += 16
        drawPropertyExpensesSummary(in: context, at: CGPoint(x: margin, y: y), width: rect.width - margin * 2, data: data)

        // Footer
        drawFooter(in: context, rect: rect, pageNumber: pageNumber, totalPages: totalPages)
    }

    // MARK: - Expenses Page Helpers

    private static func drawExpensesSummaryCards(in context: CGContext, at point: CGPoint, width: CGFloat, data: ReportData) {
        let cardWidth = (width - 24) / 3
        let cardHeight: CGFloat = 76
        let spacing: CGFloat = 12

        let cards: [(String, String, String, UIColor, UIColor)] = [
            ("Total Expenses", "\(data.currencySymbol)\(Int(data.totalExpenses).formatted())", "-8% vs last month", errorDark, errorLight),
            ("Net Profit", "\(data.currencySymbol)\(Int(data.netProfit).formatted())", "\(data.profitMargin)% margin", success, tealLight),
            ("Avg per Property", "\(data.currencySymbol)\(Int(data.avgExpensePerProperty).formatted())", "\(data.properties.count) properties", gray900, gray50)
        ]

        for (index, card) in cards.enumerated() {
            let x = point.x + CGFloat(index) * (cardWidth + spacing)

            // Card background
            let cardRect = CGRect(x: x, y: point.y, width: cardWidth, height: cardHeight)
            context.setFillColor(card.4.cgColor)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 12)
            context.addPath(path.cgPath)
            context.fillPath()

            // Title
            drawText(card.0, at: CGPoint(x: x + 16, y: point.y + 14),
                     font: .systemFont(ofSize: 10, weight: .regular), color: gray500)

            // Value
            drawText(card.1, at: CGPoint(x: x + 16, y: point.y + 30),
                     font: .systemFont(ofSize: 24, weight: .heavy), color: card.3)

            // Subtitle
            drawText(card.2, at: CGPoint(x: x + 16, y: point.y + 56),
                     font: .systemFont(ofSize: 10, weight: .semibold), color: index == 2 ? gray500 : card.3)
        }
    }

    private static func drawExpensesDetailTable(in context: CGContext, at point: CGPoint, width: CGFloat, data: ReportData, maxRows: Int) -> CGFloat {
        var y = point.y
        let rowHeight: CGFloat = 28
        let expenses = Array(data.expenseTransactions.prefix(maxRows))

        guard !expenses.isEmpty else { return y }

        // Border
        let tableHeight = rowHeight * CGFloat(expenses.count + 1)
        let tableRect = CGRect(x: point.x, y: point.y, width: width, height: tableHeight)
        context.setStrokeColor(gray200.cgColor)
        context.setLineWidth(1)
        let tablePath = UIBezierPath(roundedRect: tableRect, cornerRadius: 10)
        context.addPath(tablePath.cgPath)
        context.strokePath()

        // Header
        let headerRect = CGRect(x: point.x, y: y, width: width, height: rowHeight)
        context.setFillColor(gray50.cgColor)
        context.addPath(UIBezierPath(roundedRect: headerRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath)
        context.fillPath()

        let cols: [CGFloat] = [
            point.x + 14,           // Description
            point.x + width * 0.35, // Property
            point.x + width * 0.55, // Category
            point.x + width * 0.72, // Date
            point.x + width - 14    // Amount (right aligned)
        ]

        let headers = ["Description", "Property", "Category", "Date", "Amount"]
        for (i, header) in headers.enumerated() {
            if i == headers.count - 1 {
                drawTextRightAligned(header, at: CGPoint(x: cols[i], y: y + 9), font: .systemFont(ofSize: 9, weight: .semibold), color: gray500)
            } else {
                drawText(header, at: CGPoint(x: cols[i], y: y + 9), font: .systemFont(ofSize: 9, weight: .semibold), color: gray500)
            }
        }

        y += rowHeight

        // Rows
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        for (index, expense) in expenses.enumerated() {
            // Divider
            context.setStrokeColor(gray100.cgColor)
            context.move(to: CGPoint(x: point.x, y: y))
            context.addLine(to: CGPoint(x: point.x + width, y: y))
            context.strokePath()

            // Alternating background
            if index % 2 == 1 {
                let rowRect = CGRect(x: point.x + 1, y: y, width: width - 2, height: rowHeight)
                context.setFillColor(UIColor(white: 0.98, alpha: 1).cgColor)
                context.fill(rowRect)
            }

            let description = expense.detail ?? expense.name ?? "Expense"
            let propertyName = expense.property?.displayName ?? "—"
            let category = expense.category ?? "Other"
            let dateStr = expense.date.map { dateFormatter.string(from: $0) } ?? "—"
            let amount = "-\(data.currencySymbol)\(Int(expense.amount).formatted())"

            // Truncate long text
            let maxDescLen = 20
            let truncatedDesc = description.count > maxDescLen ? String(description.prefix(maxDescLen)) + "..." : description
            let maxPropLen = 12
            let truncatedProp = propertyName.count > maxPropLen ? String(propertyName.prefix(maxPropLen)) + "..." : propertyName

            drawText(truncatedDesc, at: CGPoint(x: cols[0], y: y + 8), font: .systemFont(ofSize: 10, weight: .medium), color: gray900)
            drawText(truncatedProp, at: CGPoint(x: cols[1], y: y + 8), font: .systemFont(ofSize: 10, weight: .regular), color: gray700)
            drawText(category, at: CGPoint(x: cols[2], y: y + 8), font: .systemFont(ofSize: 10, weight: .regular), color: gray700)
            drawText(dateStr, at: CGPoint(x: cols[3], y: y + 8), font: .systemFont(ofSize: 10, weight: .regular), color: gray700)
            drawTextRightAligned(amount, at: CGPoint(x: cols[4], y: y + 8), font: .systemFont(ofSize: 10, weight: .semibold), color: error)

            y += rowHeight
        }

        return y
    }

    private static func drawPropertyExpensesSummary(in context: CGContext, at point: CGPoint, width: CGFloat, data: ReportData) {
        let properties = data.properties
        let cardWidth = (width - 12 * CGFloat(min(properties.count, 3) - 1)) / CGFloat(min(properties.count, 3))
        let cardHeight: CGFloat = 70
        let spacing: CGFloat = 12

        for (index, property) in properties.prefix(3).enumerated() {
            let x = point.x + CGFloat(index) * (cardWidth + spacing)

            // Get property expenses
            let propExpenses = data.expenseTransactions.filter { $0.property?.objectID == property.objectID }
            let totalExpense = propExpenses.reduce(0) { $0 + $1.amount }
            let expenseCount = propExpenses.count

            // Card background
            let cardRect = CGRect(x: x, y: point.y, width: cardWidth, height: cardHeight)
            context.setFillColor(errorLight.cgColor)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 10)
            context.addPath(path.cgPath)
            context.fillPath()

            // Property name
            let propName = property.displayName
            let maxLen = 14
            let truncatedName = propName.count > maxLen ? String(propName.prefix(maxLen)) + "..." : propName
            drawText(truncatedName, at: CGPoint(x: x + 12, y: point.y + 10),
                     font: .systemFont(ofSize: 11, weight: .semibold), color: gray900)

            // Expense amount
            drawText("-\(data.currencySymbol)\(Int(totalExpense).formatted())", at: CGPoint(x: x + 12, y: point.y + 28),
                     font: .systemFont(ofSize: 18, weight: .heavy), color: errorDark)

            // Count
            drawText("\(expenseCount) expense\(expenseCount == 1 ? "" : "s")", at: CGPoint(x: x + 12, y: point.y + 50),
                     font: .systemFont(ofSize: 10, weight: .regular), color: gray500)
        }
    }

    private static func drawExpensesCategoryTable(in context: CGContext, at point: CGPoint, width: CGFloat, data: ReportData) -> CGFloat {
        var y = point.y
        let rowHeight: CGFloat = 28
        let categories = data.expensesByCategory

        // Border
        let tableRect = CGRect(x: point.x, y: point.y, width: width, height: rowHeight * CGFloat(categories.count + 2))
        context.setStrokeColor(gray200.cgColor)
        context.setLineWidth(1)
        let tablePath = UIBezierPath(roundedRect: tableRect, cornerRadius: 10)
        context.addPath(tablePath.cgPath)
        context.strokePath()

        // Header
        let headerRect = CGRect(x: point.x, y: y, width: width, height: rowHeight)
        context.setFillColor(gray50.cgColor)
        context.addPath(UIBezierPath(roundedRect: headerRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath)
        context.fillPath()

        let col1 = point.x + 16
        let col2 = point.x + width * 0.5
        let col3 = point.x + width * 0.7
        let col4 = point.x + width - 16

        drawText("Category", at: CGPoint(x: col1, y: y + 9), font: .systemFont(ofSize: 9, weight: .semibold), color: gray500)
        drawTextRightAligned("Amount", at: CGPoint(x: col2 + 30, y: y + 9), font: .systemFont(ofSize: 9, weight: .semibold), color: gray500)
        drawTextRightAligned("% of Total", at: CGPoint(x: col3 + 30, y: y + 9), font: .systemFont(ofSize: 9, weight: .semibold), color: gray500)
        drawTextRightAligned("vs Last Mo.", at: CGPoint(x: col4, y: y + 9), font: .systemFont(ofSize: 9, weight: .semibold), color: gray500)

        y += rowHeight

        // Rows
        for (index, cat) in categories.enumerated() {
            // Divider
            context.setStrokeColor(gray100.cgColor)
            context.move(to: CGPoint(x: point.x, y: y))
            context.addLine(to: CGPoint(x: point.x + width, y: y))
            context.strokePath()

            // Alternating background
            if index % 2 == 1 {
                let rowRect = CGRect(x: point.x + 1, y: y, width: width - 2, height: rowHeight)
                context.setFillColor(UIColor(white: 0.98, alpha: 1).cgColor)
                context.fill(rowRect)
            }

            // Category with color dot
            let dotRect = CGRect(x: col1, y: y + 10, width: 7, height: 7)
            context.setFillColor(cat.color.cgColor)
            let dotPath = UIBezierPath(roundedRect: dotRect, cornerRadius: 2)
            context.addPath(dotPath.cgPath)
            context.fillPath()

            drawText(cat.category, at: CGPoint(x: col1 + 12, y: y + 8), font: .systemFont(ofSize: 11, weight: .medium), color: gray900)
            drawTextRightAligned("\(data.currencySymbol)\(Int(cat.amount).formatted())", at: CGPoint(x: col2 + 30, y: y + 8), font: .systemFont(ofSize: 11, weight: .semibold), color: gray900)
            drawTextRightAligned("\(cat.percent)%", at: CGPoint(x: col3 + 30, y: y + 8), font: .systemFont(ofSize: 11, weight: .regular), color: gray700)
            drawTextRightAligned("—", at: CGPoint(x: col4, y: y + 8), font: .systemFont(ofSize: 10, weight: .medium), color: gray500)

            y += rowHeight
        }

        // Total row
        context.setStrokeColor(gray100.cgColor)
        context.move(to: CGPoint(x: point.x, y: y))
        context.addLine(to: CGPoint(x: point.x + width, y: y))
        context.strokePath()

        let totalRect = CGRect(x: point.x + 1, y: y, width: width - 2, height: rowHeight - 1)
        context.setFillColor(errorLight.cgColor)
        context.addPath(UIBezierPath(roundedRect: totalRect, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 9, height: 9)).cgPath)
        context.fillPath()

        drawText("Total", at: CGPoint(x: col1, y: y + 8), font: .systemFont(ofSize: 11, weight: .bold), color: errorDark)
        drawTextRightAligned("\(data.currencySymbol)\(Int(data.totalExpenses).formatted())", at: CGPoint(x: col2 + 30, y: y + 8), font: .systemFont(ofSize: 11, weight: .bold), color: errorDark)
        drawTextRightAligned("100%", at: CGPoint(x: col3 + 30, y: y + 8), font: .systemFont(ofSize: 11, weight: .bold), color: errorDark)
        drawTextRightAligned("—", at: CGPoint(x: col4, y: y + 8), font: .systemFont(ofSize: 10, weight: .semibold), color: success)

        return y + rowHeight
    }

    private static func drawPropertyProfitTable(in context: CGContext, at point: CGPoint, width: CGFloat, data: ReportData) {
        var y = point.y
        let rowHeight: CGFloat = 40
        let properties = data.propertyProfitBreakdown

        // Border
        let tableRect = CGRect(x: point.x, y: point.y, width: width, height: rowHeight * CGFloat(properties.count + 2))
        context.setStrokeColor(gray200.cgColor)
        context.setLineWidth(1)
        let tablePath = UIBezierPath(roundedRect: tableRect, cornerRadius: 10)
        context.addPath(tablePath.cgPath)
        context.strokePath()

        // Header
        let headerRect = CGRect(x: point.x, y: y, width: width, height: rowHeight)
        context.setFillColor(gray50.cgColor)
        context.addPath(UIBezierPath(roundedRect: headerRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath)
        context.fillPath()

        let col1 = point.x + 16
        let col2 = point.x + width * 0.36
        let col3 = point.x + width * 0.52
        let col4 = point.x + width * 0.68
        let col5 = point.x + width - 16

        drawText("Property", at: CGPoint(x: col1, y: y + 14), font: .systemFont(ofSize: 10, weight: .semibold), color: gray500)
        drawTextRightAligned("Income", at: CGPoint(x: col2 + 30, y: y + 14), font: .systemFont(ofSize: 10, weight: .semibold), color: gray500)
        drawTextRightAligned("Expenses", at: CGPoint(x: col3 + 30, y: y + 14), font: .systemFont(ofSize: 10, weight: .semibold), color: gray500)
        drawTextRightAligned("Profit", at: CGPoint(x: col4 + 30, y: y + 14), font: .systemFont(ofSize: 10, weight: .semibold), color: gray500)
        drawTextRightAligned("Margin", at: CGPoint(x: col5, y: y + 14), font: .systemFont(ofSize: 10, weight: .semibold), color: gray500)

        y += rowHeight

        // Rows
        for (index, prop) in properties.enumerated() {
            // Divider
            context.setStrokeColor(gray100.cgColor)
            context.move(to: CGPoint(x: point.x, y: y))
            context.addLine(to: CGPoint(x: point.x + width, y: y))
            context.strokePath()

            // Alternating background
            if index % 2 == 1 {
                let rowRect = CGRect(x: point.x + 1, y: y, width: width - 2, height: rowHeight)
                context.setFillColor(UIColor(white: 0.98, alpha: 1).cgColor)
                context.fill(rowRect)
            }

            drawText(prop.property.displayName, at: CGPoint(x: col1, y: y + 10), font: .systemFont(ofSize: 12, weight: .semibold), color: gray900)
            drawText(prop.property.shortAddress, at: CGPoint(x: col1, y: y + 24), font: .systemFont(ofSize: 10, weight: .regular), color: gray500)
            drawTextRightAligned("\(data.currencySymbol)\(Int(prop.income).formatted())", at: CGPoint(x: col2 + 30, y: y + 14), font: .systemFont(ofSize: 12, weight: .medium), color: success)
            drawTextRightAligned("-\(data.currencySymbol)\(Int(prop.expenses).formatted())", at: CGPoint(x: col3 + 30, y: y + 14), font: .systemFont(ofSize: 12, weight: .medium), color: error)
            drawTextRightAligned("\(data.currencySymbol)\(Int(prop.profit).formatted())", at: CGPoint(x: col4 + 30, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: tealDark)

            let marginColor = prop.margin >= 50 ? success : (prop.margin >= 30 ? warning : error)
            drawTextRightAligned("\(prop.margin)%", at: CGPoint(x: col5, y: y + 14), font: .systemFont(ofSize: 12, weight: .semibold), color: marginColor)

            y += rowHeight
        }

        // Total row
        context.setStrokeColor(gray100.cgColor)
        context.move(to: CGPoint(x: point.x, y: y))
        context.addLine(to: CGPoint(x: point.x + width, y: y))
        context.strokePath()

        let totalRect = CGRect(x: point.x + 1, y: y, width: width - 2, height: rowHeight - 1)
        context.setFillColor(tealLight.cgColor)
        context.addPath(UIBezierPath(roundedRect: totalRect, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 9, height: 9)).cgPath)
        context.fillPath()

        drawText("Total", at: CGPoint(x: col1, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: tealDark)
        drawTextRightAligned("\(data.currencySymbol)\(Int(data.totalIncome).formatted())", at: CGPoint(x: col2 + 30, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: success)
        drawTextRightAligned("-\(data.currencySymbol)\(Int(data.totalExpenses).formatted())", at: CGPoint(x: col3 + 30, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: error)
        drawTextRightAligned("\(data.currencySymbol)\(Int(data.netProfit).formatted())", at: CGPoint(x: col4 + 30, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: tealDark)
        drawTextRightAligned("\(data.profitMargin)%", at: CGPoint(x: col5, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: success)
    }

    // MARK: - Drawing Helpers

    private static func drawGradientHeader(in context: CGContext, rect: CGRect) {
        let colors = [tealDark.cgColor, tealMid.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: colors as CFArray,
                                  locations: [0, 1])!

        context.saveGState()
        context.addRect(rect)
        context.clip()
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: 0),
                                   end: CGPoint(x: rect.width, y: rect.height),
                                   options: [])
        context.restoreGState()
    }

    private static func drawLogo(in context: CGContext, at point: CGPoint) {
        // Logo background
        let logoRect = CGRect(x: point.x, y: point.y, width: 36, height: 36)
        context.setFillColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        let logoPath = UIBezierPath(roundedRect: logoRect, cornerRadius: 10)
        context.addPath(logoPath.cgPath)
        context.fillPath()

        // Logo text (simplified)
        drawText("RentDar", at: CGPoint(x: point.x + 46, y: point.y + 8),
                 font: .systemFont(ofSize: 20, weight: .heavy), color: .white)
    }

    private static func drawInfoBadges(in context: CGContext, at point: CGPoint, data: ReportData) {
        var x = point.x
        let badgeHeight: CGFloat = 36
        let badgeSpacing: CGFloat = 12

        // Period badge
        let periodBadge = drawInfoBadge(in: context, at: CGPoint(x: x, y: point.y),
                                        label: "Period", value: data.periodString)
        x += periodBadge + badgeSpacing

        // Properties badge
        let propertiesText = data.properties.count == 1 ? data.properties.first?.displayName ?? "1 property" : "All (\(data.properties.count) properties)"
        let propertiesBadge = drawInfoBadge(in: context, at: CGPoint(x: x, y: point.y),
                                            label: "Properties", value: propertiesText)
        x += propertiesBadge + badgeSpacing

        // Generated badge
        _ = drawInfoBadge(in: context, at: CGPoint(x: x, y: point.y),
                          label: "Generated", value: data.generatedDateString)
    }

    @discardableResult
    private static func drawInfoBadge(in context: CGContext, at point: CGPoint, label: String, value: String) -> CGFloat {
        let labelFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let valueFont = UIFont.systemFont(ofSize: 12, weight: .semibold)

        let labelSize = label.size(withAttributes: [.font: labelFont])
        let valueSize = value.size(withAttributes: [.font: valueFont])
        let width = max(labelSize.width, valueSize.width) + 24
        let height: CGFloat = 44

        // Badge background
        let badgeRect = CGRect(x: point.x, y: point.y, width: width, height: height)
        context.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        let path = UIBezierPath(roundedRect: badgeRect, cornerRadius: 8)
        context.addPath(path.cgPath)
        context.fillPath()

        // Label
        drawText(label, at: CGPoint(x: point.x + 12, y: point.y + 8),
                 font: labelFont, color: UIColor.white.withAlphaComponent(0.6))

        // Value
        drawText(value, at: CGPoint(x: point.x + 12, y: point.y + 24),
                 font: valueFont, color: .white)

        return width
    }

    private static func drawMetricsGrid(in context: CGContext, at point: CGPoint, width: CGFloat, data: ReportData) {
        let cardWidth = (width - 36) / 4
        let cardHeight: CGFloat = 80
        let spacing: CGFloat = 12

        let metrics: [(String, String, String, Bool)] = [
            ("Total Income", "\(data.currencySymbol)\(Int(data.totalIncome).formatted())", "+12% vs last month", true),
            ("Bookings", "\(data.totalBookings)", "+3 vs last month", true),
            ("Nights Booked", "\(data.totalNights)", "Avg \(String(format: "%.1f", data.totalBookings > 0 ? Double(data.totalNights) / Double(data.totalBookings) : 0))/booking", false),
            ("Occupancy", "\(data.occupancyPercent)%", "+5% vs last month", false)
        ]

        for (index, metric) in metrics.enumerated() {
            let x = point.x + CGFloat(index) * (cardWidth + spacing)
            let isTeal = index < 2

            // Card background
            let cardRect = CGRect(x: x, y: point.y, width: cardWidth, height: cardHeight)
            context.setFillColor((isTeal ? tealLight : gray50).cgColor)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 12)
            context.addPath(path.cgPath)
            context.fillPath()

            // Title
            drawText(metric.0, at: CGPoint(x: x + 16, y: point.y + 14),
                     font: .systemFont(ofSize: 10, weight: .regular), color: gray500, centered: false)

            // Value
            drawText(metric.1, at: CGPoint(x: x + 16, y: point.y + 30),
                     font: .systemFont(ofSize: 24, weight: .heavy), color: isTeal ? tealDark : gray900)

            // Subtitle
            drawText(metric.2, at: CGPoint(x: x + 16, y: point.y + 58),
                     font: .systemFont(ofSize: 10, weight: .semibold), color: metric.3 ? success : gray500)
        }
    }

    private static func drawPropertyTable(in context: CGContext, at point: CGPoint, width: CGFloat, data: ReportData) -> CGFloat {
        var y = point.y
        let rowHeight: CGFloat = 40

        // Border
        let tableRect = CGRect(x: point.x, y: point.y, width: width, height: rowHeight * CGFloat(data.incomeByProperty.count + 2))
        context.setStrokeColor(gray200.cgColor)
        context.setLineWidth(1)
        let tablePath = UIBezierPath(roundedRect: tableRect, cornerRadius: 10)
        context.addPath(tablePath.cgPath)
        context.strokePath()

        // Header
        let headerRect = CGRect(x: point.x, y: y, width: width, height: rowHeight)
        context.setFillColor(gray50.cgColor)
        context.addPath(UIBezierPath(roundedRect: headerRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath)
        context.fillPath()

        let col1 = point.x + 16
        let col2 = point.x + width * 0.5
        let col3 = point.x + width * 0.65
        let col4 = point.x + width - 16

        drawText("Property", at: CGPoint(x: col1, y: y + 14), font: .systemFont(ofSize: 10, weight: .semibold), color: gray500)
        drawText("Bookings", at: CGPoint(x: col2, y: y + 14), font: .systemFont(ofSize: 10, weight: .semibold), color: gray500)
        drawText("Nights", at: CGPoint(x: col3, y: y + 14), font: .systemFont(ofSize: 10, weight: .semibold), color: gray500)
        drawTextRightAligned("Income", at: CGPoint(x: col4, y: y + 14), font: .systemFont(ofSize: 10, weight: .semibold), color: gray500)

        y += rowHeight

        // Rows
        for item in data.incomeByProperty {
            // Divider
            context.setStrokeColor(gray100.cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: point.x, y: y))
            context.addLine(to: CGPoint(x: point.x + width, y: y))
            context.strokePath()

            drawText(item.property.displayName, at: CGPoint(x: col1, y: y + 10), font: .systemFont(ofSize: 12, weight: .semibold), color: gray900)
            drawText(item.property.shortAddress, at: CGPoint(x: col1, y: y + 24), font: .systemFont(ofSize: 10, weight: .regular), color: gray500)
            drawText("\(item.bookings)", at: CGPoint(x: col2, y: y + 14), font: .systemFont(ofSize: 12, weight: .medium), color: gray700)
            drawText("\(item.nights)", at: CGPoint(x: col3, y: y + 14), font: .systemFont(ofSize: 12, weight: .medium), color: gray700)
            drawTextRightAligned("\(data.currencySymbol)\(Int(item.income).formatted())", at: CGPoint(x: col4, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: tealDark)

            y += rowHeight
        }

        // Total row
        context.setStrokeColor(gray100.cgColor)
        context.move(to: CGPoint(x: point.x, y: y))
        context.addLine(to: CGPoint(x: point.x + width, y: y))
        context.strokePath()

        let totalRect = CGRect(x: point.x + 1, y: y, width: width - 2, height: rowHeight - 1)
        context.setFillColor(tealLight.cgColor)
        context.addPath(UIBezierPath(roundedRect: totalRect, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 9, height: 9)).cgPath)
        context.fillPath()

        drawText("Total", at: CGPoint(x: col1, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: tealDark)
        drawText("\(data.totalBookings)", at: CGPoint(x: col2, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: tealDark)
        drawText("\(data.totalNights)", at: CGPoint(x: col3, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: tealDark)
        drawTextRightAligned("\(data.currencySymbol)\(Int(data.totalIncome).formatted())", at: CGPoint(x: col4, y: y + 14), font: .systemFont(ofSize: 12, weight: .bold), color: tealDark)

        return y + rowHeight
    }

    private static func drawPlatformBreakdown(in context: CGContext, at point: CGPoint, width: CGFloat, data: ReportData) {
        let platforms = data.platformBreakdown
        let count = min(platforms.count, 4)
        guard count > 0 else { return }

        let spacing: CGFloat = 12
        let cardWidth = (width - spacing * CGFloat(count - 1)) / CGFloat(count)
        let cardHeight: CGFloat = 120

        for (index, platform) in platforms.prefix(4).enumerated() {
            let x = point.x + CGFloat(index) * (cardWidth + spacing)

            // Card border
            let cardRect = CGRect(x: x, y: point.y, width: cardWidth, height: cardHeight)
            context.setStrokeColor(gray200.cgColor)
            context.setLineWidth(1)
            let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 10)
            context.addPath(path.cgPath)
            context.strokePath()

            // Platform icon (colored rounded rect with name)
            let iconColor = platformColor(for: platform.platform)
            let iconHeight: CGFloat = 28
            let platformName = platform.platform == "Booking.com" ? "Booking" : platform.platform
            let nameFont = UIFont.systemFont(ofSize: 11, weight: .bold)
            let nameSize = platformName.size(withAttributes: [.font: nameFont])
            let iconWidth = nameSize.width + 20

            let iconRect = CGRect(x: x + (cardWidth - iconWidth) / 2, y: point.y + 14, width: iconWidth, height: iconHeight)
            context.setFillColor(iconColor.withAlphaComponent(0.15).cgColor)
            let iconPath = UIBezierPath(roundedRect: iconRect, cornerRadius: 8)
            context.addPath(iconPath.cgPath)
            context.fillPath()

            // Platform name centered in icon
            drawText(platformName, at: CGPoint(x: x + cardWidth / 2, y: point.y + 21),
                     font: nameFont, color: iconColor, centered: true)

            // Bookings count
            drawText("\(platform.bookings)", at: CGPoint(x: x + cardWidth / 2, y: point.y + 52),
                     font: .systemFont(ofSize: 20, weight: .heavy), color: gray900, centered: true)

            // Percentage
            drawText("bookings (\(platform.percent)%)", at: CGPoint(x: x + cardWidth / 2, y: point.y + 76),
                     font: .systemFont(ofSize: 10, weight: .regular), color: gray500, centered: true)

            // Income
            drawText("\(data.currencySymbol)\(Int(platform.income).formatted())", at: CGPoint(x: x + cardWidth / 2, y: point.y + 94),
                     font: .systemFont(ofSize: 14, weight: .bold), color: tealDark, centered: true)
        }
    }

    private static func drawBookingsTable(in context: CGContext, at point: CGPoint, width: CGFloat, data: ReportData) {
        var y = point.y
        let rowHeight: CGFloat = 32
        let bookings = Array(data.incomeTransactions.prefix(12)) // Max 12 per page

        // Border
        let tableHeight = rowHeight * CGFloat(bookings.count + 1)
        let tableRect = CGRect(x: point.x, y: point.y, width: width, height: tableHeight)
        context.setStrokeColor(gray200.cgColor)
        context.setLineWidth(1)
        let tablePath = UIBezierPath(roundedRect: tableRect, cornerRadius: 10)
        context.addPath(tablePath.cgPath)
        context.strokePath()

        // Header
        let headerRect = CGRect(x: point.x, y: y, width: width, height: rowHeight)
        context.setFillColor(gray50.cgColor)
        context.addPath(UIBezierPath(roundedRect: headerRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath)
        context.fillPath()

        let cols: [CGFloat] = [
            point.x + 14,           // Guest
            point.x + width * 0.22, // Property
            point.x + width * 0.44, // Check-in
            point.x + width * 0.56, // Nights
            point.x + width * 0.66, // Platform
            point.x + width - 14    // Amount (right aligned)
        ]

        let headers = ["Guest", "Property", "Check-in", "Nights", "Platform", "Amount"]
        for (i, header) in headers.enumerated() {
            if i == headers.count - 1 {
                drawTextRightAligned(header, at: CGPoint(x: cols[i], y: y + 10), font: .systemFont(ofSize: 9, weight: .semibold), color: gray500)
            } else {
                drawText(header, at: CGPoint(x: cols[i], y: y + 10), font: .systemFont(ofSize: 9, weight: .semibold), color: gray500)
            }
        }

        y += rowHeight

        // Rows
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        for (index, booking) in bookings.enumerated() {
            // Divider
            context.setStrokeColor(gray100.cgColor)
            context.move(to: CGPoint(x: point.x, y: y))
            context.addLine(to: CGPoint(x: point.x + width, y: y))
            context.strokePath()

            // Alternating background
            if index % 2 == 1 {
                let rowRect = CGRect(x: point.x + 1, y: y, width: width - 2, height: rowHeight)
                context.setFillColor(UIColor(white: 0.98, alpha: 1).cgColor)
                context.fill(rowRect)
            }

            let guestName = booking.name ?? "Guest"
            let propertyName = booking.property?.displayName ?? "Unknown"
            let checkIn = booking.date.map { dateFormatter.string(from: $0) } ?? "-"
            let nights = "\(booking.nights)"
            let platform = booking.platform ?? "Direct"
            let amount = "\(data.currencySymbol)\(Int(booking.amount).formatted())"

            drawText(guestName, at: CGPoint(x: cols[0], y: y + 10), font: .systemFont(ofSize: 11, weight: .medium), color: gray900)
            drawText(propertyName, at: CGPoint(x: cols[1], y: y + 10), font: .systemFont(ofSize: 11, weight: .regular), color: gray700)
            drawText(checkIn, at: CGPoint(x: cols[2], y: y + 10), font: .systemFont(ofSize: 11, weight: .regular), color: gray700)
            drawText(nights, at: CGPoint(x: cols[3], y: y + 10), font: .systemFont(ofSize: 11, weight: .regular), color: gray700)

            // Platform with dot
            let platformColor = self.platformColor(for: platform)
            let dotRect = CGRect(x: cols[4], y: y + 12, width: 6, height: 6)
            context.setFillColor(platformColor.cgColor)
            context.fillEllipse(in: dotRect)
            drawText(platform, at: CGPoint(x: cols[4] + 10, y: y + 10), font: .systemFont(ofSize: 10, weight: .regular), color: gray700)

            drawTextRightAligned(amount, at: CGPoint(x: cols[5], y: y + 10), font: .systemFont(ofSize: 11, weight: .semibold), color: gray900)

            y += rowHeight
        }
    }

    private static func drawDisclaimer(in context: CGContext, at point: CGPoint, width: CGFloat) {
        let disclaimerRect = CGRect(x: point.x, y: point.y, width: width, height: 44)
        context.setFillColor(gray50.cgColor)
        let path = UIBezierPath(roundedRect: disclaimerRect, cornerRadius: 8)
        context.addPath(path.cgPath)
        context.fillPath()

        let text = "This report was automatically generated by RentDar. All amounts are shown before platform fees. Data reflects bookings confirmed as of the report generation date."
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor(white: 0.6, alpha: 1),
            .paragraphStyle: paragraphStyle
        ]

        let textRect = CGRect(x: point.x + 24, y: point.y + 10, width: width - 48, height: 30)
        text.draw(in: textRect, withAttributes: attributes)
    }

    private static func drawFooter(in context: CGContext, rect: CGRect, pageNumber: Int, totalPages: Int) {
        let margin: CGFloat = 48
        let y = rect.height - 30

        // Divider
        context.setStrokeColor(gray100.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y - 10))
        context.addLine(to: CGPoint(x: rect.width - margin, y: y - 10))
        context.strokePath()

        drawText("Generated by RentDar · rentdar.app", at: CGPoint(x: margin, y: y),
                 font: .systemFont(ofSize: 9, weight: .regular), color: UIColor(white: 0.6, alpha: 1))

        let pageText = "Page \(pageNumber) of \(totalPages)"
        let pageWidth = pageText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 9)]).width
        drawText(pageText, at: CGPoint(x: rect.width - margin - pageWidth, y: y),
                 font: .systemFont(ofSize: 9, weight: .regular), color: UIColor(white: 0.6, alpha: 1))
    }

    // MARK: - Text Drawing Helpers

    private static func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, centered: Bool = false) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        if centered {
            let size = text.size(withAttributes: attributes)
            let centeredPoint = CGPoint(x: point.x - size.width / 2, y: point.y)
            text.draw(at: centeredPoint, withAttributes: attributes)
        } else {
            text.draw(at: point, withAttributes: attributes)
        }
    }

    private static func drawTextRightAligned(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let size = text.size(withAttributes: attributes)
        let rightPoint = CGPoint(x: point.x - size.width, y: point.y)
        text.draw(at: rightPoint, withAttributes: attributes)
    }

    private static func platformColor(for platform: String) -> UIColor {
        switch platform.lowercased() {
        case "airbnb": return airbnbRed
        case "booking", "booking.com": return bookingBlue
        case "vrbo": return vrboBlue
        case "direct": return tealMid
        default: return gray500
        }
    }
}
