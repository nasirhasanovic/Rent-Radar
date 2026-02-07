import SwiftUI

// MARK: - Booking Source

enum BookingSource: String, CaseIterable {
    case airbnb = "Airbnb"
    case direct = "Direct"
    case vrbo = "VRBO"

    var icon: String {
        switch self {
        case .airbnb: return "house.fill"
        case .direct: return "pencil"
        case .vrbo: return "building.2.fill"
        }
    }

    var tagColor: Color {
        switch self {
        case .airbnb: return AppColors.teal500
        case .direct: return AppColors.success
        case .vrbo: return AppColors.info
        }
    }
}

// MARK: - Property Type

enum PropertyType: String, CaseIterable {
    case shortTerm = "short-term"
    case longTerm = "long-term"

    var displayName: String {
        switch self {
        case .shortTerm: return String(localized: "Short-term Rental")
        case .longTerm: return String(localized: "Long-term Rental")
        }
    }

    var subtitle: String {
        switch self {
        case .shortTerm: return String(localized: "Airbnb, VRBO, direct bookings")
        case .longTerm: return String(localized: "Monthly, biweekly, leases")
        }
    }

    var icon: String {
        switch self {
        case .shortTerm: return "calendar.badge.clock"
        case .longTerm: return "key.fill"
        }
    }

    var rateLabel: String {
        switch self {
        case .shortTerm: return String(localized: "Nightly Rate")
        case .longTerm: return String(localized: "Monthly Rate")
        }
    }

    var ratePeriod: String {
        switch self {
        case .shortTerm: return String(localized: "/night")
        case .longTerm: return String(localized: "/month")
        }
    }
}

// MARK: - Property Status

enum PropertyStatus: String {
    case bookedTonight = "Booked tonight"
    case available = "Available"
    case occupied = "Occupied"

    var displayName: String {
        switch self {
        case .bookedTonight: return String(localized: "Booked tonight")
        case .available: return String(localized: "Available")
        case .occupied: return String(localized: "Occupied")
        }
    }

    var color: Color {
        switch self {
        case .bookedTonight: return AppColors.error
        case .available: return AppColors.success
        case .occupied: return AppColors.warning
        }
    }
}

// MARK: - TransactionEntity Helpers

extension TransactionEntity {
    var displayIcon: String {
        if isIncome {
            return IncomePlatform(rawValue: platform ?? "")?.emoji ?? "\u{1F4B0}"
        }
        return ExpenseCategory(rawValue: category ?? "")?.emoji ?? "\u{1F4CB}"
    }

    var displayIconBg: Color {
        if isIncome {
            return IncomePlatform(rawValue: platform ?? "")?.iconBg ?? AppColors.tintedGray
        }
        return ExpenseCategory(rawValue: category ?? "")?.iconBg ?? AppColors.tintedGray
    }

    var nights: Int {
        guard let start = date, let end = endDate else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0)
    }

    var displayDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        guard let start = date else { return "" }
        if let end = endDate {
            return "\(formatter.string(from: start))-\(formatter.string(from: end))"
        }
        return formatter.string(from: start)
    }

    var displayDetail: String {
        if isIncome {
            let n = nights
            let p = platform ?? "Direct"
            return n > 0 ? String(localized: "\(n) nights \u{2022} \(p)") : p
        }
        return detail ?? ""
    }

    var formattedDisplayAmount: String {
        let symbol = AppSettings.shared.currencySymbol
        let value = Int(abs(amount)).formatted()
        return isIncome ? "+\(symbol)\(value)" : "-\(symbol)\(value)"
    }

    func toMockTransaction() -> MockTransaction {
        MockTransaction(
            name: name ?? "",
            icon: displayIcon,
            iconBg: displayIconBg,
            dateRange: displayDateRange,
            detail: displayDetail,
            amount: amount,
            isIncome: isIncome,
            isEmojiIcon: true
        )
    }
}

// MARK: - Illustration Presets

struct PropertyIllustration: Identifiable {
    let id: Int
    let colors: [Color]

    static let presets: [PropertyIllustration] = [
        PropertyIllustration(id: 0, colors: [AppColors.teal500, AppColors.teal300]),
        PropertyIllustration(id: 1, colors: [Color(hex: "F97316"), Color(hex: "FDBA74")]),
        PropertyIllustration(id: 2, colors: [AppColors.info, Color(hex: "93C5FD")]),
        PropertyIllustration(id: 3, colors: [AppColors.success, Color(hex: "6EE7B7")]),
        PropertyIllustration(id: 4, colors: [Color(hex: "8B5CF6"), Color(hex: "C4B5FD")]),
        PropertyIllustration(id: 5, colors: [AppColors.error, Color(hex: "FCA5A5")]),
        PropertyIllustration(id: 6, colors: [Color(hex: "06B6D4"), Color(hex: "67E8F9")]),
        PropertyIllustration(id: 7, colors: [Color(hex: "EC4899"), Color(hex: "F9A8D4")]),
    ]
}

// MARK: - PropertyEntity Helpers

extension PropertyEntity {
    var displayName: String { name ?? String(localized: "Untitled") }
    var displayAddress: String {
        [address, city, state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
    var shortAddress: String {
        [city, state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }
    var formattedPrice: String { "\(AppSettings.shared.currencySymbol)\(Int(nightlyRate))" }
    var source: BookingSource { BookingSource(rawValue: bookingSource ?? "Airbnb") ?? .airbnb }
    var type: PropertyType { PropertyType(rawValue: propertyType ?? "short-term") ?? .shortTerm }
    var status: PropertyStatus { .available }

    var illustrationGradient: [Color] {
        let idx = Int(illustrationIndex)
        if idx >= 0 && idx < PropertyIllustration.presets.count {
            return PropertyIllustration.presets[idx].colors
        }
        return [AppColors.teal100, AppColors.teal300.opacity(0.3)]
    }

    var coverImage: UIImage? {
        guard let fileName = coverImageName, !fileName.isEmpty else { return nil }
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PropertyImages")
            .appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }
}
