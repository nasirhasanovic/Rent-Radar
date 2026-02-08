import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var onDismiss: () -> Void

    @State private var searchText = ""
    @State private var selectedFilter: SearchFilter = .all
    @State private var recentSearches: [String] = ["Mountain Cabin", "Sarah Mitchell", "January revenue"]
    @FocusState private var isSearchFocused: Bool

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

    private enum SearchFilter: String, CaseIterable {
        case all = "All"
        case properties = "Properties"
        case bookings = "Bookings"
        case guests = "Guests"
        case expenses = "Expenses"

        var displayName: String {
            switch self {
            case .all: return String(localized: "All")
            case .properties: return String(localized: "Properties")
            case .bookings: return String(localized: "Bookings")
            case .guests: return String(localized: "Guests")
            case .expenses: return String(localized: "Expenses")
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            searchBar
                .padding(.horizontal, 20)
                .padding(.top, 10)

            if searchText.isEmpty {
                emptyStateContent
            } else {
                // Filter chips (only when searching)
                filterChips
                    .padding(.top, 14)

                searchResultsSection
            }

            Spacer()
        }
        .background(Color.white)
        .onAppear {
            isSearchFocused = true
        }
    }

    // MARK: - Empty State Content

    private var emptyStateContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                quickAccessSection
                recentSearchesSection
                suggestedSection
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Quick Access

    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Access")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            FlowLayout(spacing: 10) {
                QuickAccessChip(
                    icon: "house.fill",
                    title: "All Properties",
                    bgColor: Color(hex: "F0FDFA"),
                    borderColor: Color(hex: "D1FAE5"),
                    textColor: AppColors.teal500
                )

                QuickAccessChip(
                    icon: "calendar",
                    title: "Today's Bookings",
                    bgColor: Color(hex: "FFF1F0"),
                    borderColor: Color(hex: "FFE4E6"),
                    textColor: Color(hex: "FF5A5F")
                )

                QuickAccessChip(
                    icon: "clock.fill",
                    title: "Pending Check-ins",
                    bgColor: Color(hex: "FEF3C7"),
                    borderColor: Color(hex: "FDE68A"),
                    textColor: Color(hex: "D97706")
                )

                QuickAccessChip(
                    icon: "star.fill",
                    title: "Top Earners",
                    bgColor: Color(hex: "EDE9FE"),
                    borderColor: Color(hex: "DDD6FE"),
                    textColor: Color(hex: "7C3AED")
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - Suggested

    private var suggestedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Suggested")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    SuggestedChip(title: "upcoming check-ins") {
                        searchText = "upcoming check-ins"
                    }
                    SuggestedChip(title: "overdue payments") {
                        searchText = "overdue payments"
                    }
                }

                HStack(spacing: 8) {
                    SuggestedChip(title: "highest revenue") {
                        searchText = "highest revenue"
                    }
                    SuggestedChip(title: "sync conflicts") {
                        searchText = "sync conflicts"
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.teal500)

                TextField("Search properties, bookings, guests...", text: $searchText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "F3F4F6"))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppColors.teal500, lineWidth: 2)
            )

            Button(action: onDismiss) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.teal500)
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selectedFilter == filter ? .white : Color(hex: "6B7280"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedFilter == filter ? AppColors.teal500 : Color(hex: "F3F4F6"))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Results header
                Text("\(filteredResults.count) results for \"\(searchText)\"")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "6B7280"))
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                // Results list
                VStack(spacing: 8) {
                    ForEach(filteredResults) { result in
                        SearchResultCard(result: result, searchTerm: searchText)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
    }

    private var filteredResults: [SearchResult] {
        var results: [SearchResult] = []

        let lowercasedSearch = searchText.lowercased()

        // Search properties
        if selectedFilter == .all || selectedFilter == .properties {
            for property in properties {
                if property.displayName.lowercased().contains(lowercasedSearch) ||
                   (property.address?.lowercased().contains(lowercasedSearch) ?? false) {
                    results.append(SearchResult(
                        id: property.objectID.uriRepresentation().absoluteString,
                        type: .property,
                        title: property.displayName,
                        subtitle: "\(property.shortAddress) · \(Int.random(in: 60...95))% occupancy",
                        platformColor: nil
                    ))
                }
            }
        }

        // Search bookings (income transactions)
        if selectedFilter == .all || selectedFilter == .bookings {
            for transaction in transactions where transaction.isIncome {
                let guestName = transaction.detail ?? "Guest"
                let propertyName = transaction.property?.displayName ?? "Property"

                if guestName.lowercased().contains(lowercasedSearch) ||
                   propertyName.lowercased().contains(lowercasedSearch) {
                    results.append(SearchResult(
                        id: transaction.objectID.uriRepresentation().absoluteString,
                        type: .booking,
                        title: "\(guestName) → \(propertyName)",
                        subtitle: "\(transaction.displayDateRange) · $\(Int(transaction.amount))",
                        platformColor: platformColor(for: transaction.platform ?? "")
                    ))
                }
            }
        }

        // Search expenses
        if selectedFilter == .all || selectedFilter == .expenses {
            for transaction in transactions where !transaction.isIncome {
                let description = transaction.detail ?? transaction.category ?? "Expense"
                let propertyName = transaction.property?.displayName ?? ""

                if description.lowercased().contains(lowercasedSearch) ||
                   propertyName.lowercased().contains(lowercasedSearch) {
                    results.append(SearchResult(
                        id: transaction.objectID.uriRepresentation().absoluteString,
                        type: .expense,
                        title: description,
                        subtitle: "\(transaction.displayDateRange) · -$\(Int(transaction.amount))",
                        platformColor: nil
                    ))
                }
            }
        }

        return results
    }

    private func platformColor(for platform: String) -> Color {
        switch platform.lowercased() {
        case "airbnb": return Color(hex: "FF5A5F")
        case "booking.com", "booking": return Color(hex: "003580")
        case "vrbo": return Color(hex: "3B5998")
        default: return AppColors.teal500
        }
    }

    // MARK: - Recent Searches

    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent Searches")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button {
                    withAnimation {
                        recentSearches.removeAll()
                    }
                } label: {
                    Text("Clear All")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
            }

            VStack(spacing: 0) {
                ForEach(recentSearches, id: \.self) { search in
                    Button {
                        searchText = search
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "D1D5DB"))
                                .frame(width: 16)

                            Text(search)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "374151"))

                            Spacer()

                            Button {
                                withAnimation {
                                    recentSearches.removeAll { $0 == search }
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color(hex: "D1D5DB"))
                            }
                        }
                        .padding(.vertical, 12)
                    }

                    if search != recentSearches.last {
                        Divider()
                    }
                }
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
    }
}

// MARK: - Quick Access Chip

private struct QuickAccessChip: View {
    let icon: String
    let title: String
    let bgColor: Color
    let borderColor: Color
    let textColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(textColor)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Suggested Chip

private struct SuggestedChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "6B7280"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "F3F4F6"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
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
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
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

// MARK: - Search Result Model

struct SearchResult: Identifiable {
    let id: String
    let type: SearchResultType
    let title: String
    let subtitle: String
    let platformColor: Color?

    enum SearchResultType {
        case property
        case booking
        case expense
        case guest
    }
}

// MARK: - Search Result Card

private struct SearchResultCard: View {
    let result: SearchResult
    let searchTerm: String

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            resultIcon

            // Content
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    highlightedTitle
                    if result.type != .booking {
                        resultBadge
                    }
                }

                if result.type == .booking {
                    HStack(spacing: 6) {
                        resultBadge
                        Text(result.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                    }
                } else {
                    Text(result.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "9CA3AF"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "9CA3AF"))
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "F3F4F6"), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
    }

    @ViewBuilder
    private var resultIcon: some View {
        switch result.type {
        case .property:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0D9488"), Color(hex: "2DD4A8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: "house.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
            }
        case .booking:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "FFF1F0"))
                    .frame(width: 48, height: 48)
                Image("airbnb_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
        case .expense:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "FEF3C7"))
                    .frame(width: 48, height: 48)
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "F59E0B"))
            }
        case .guest:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.tintedTeal)
                    .frame(width: 48, height: 48)
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.teal500)
            }
        }
    }

    private var highlightedTitle: Text {
        let title = result.title
        let lowercasedTitle = title.lowercased()
        let lowercasedTerm = searchTerm.lowercased()

        if let range = lowercasedTitle.range(of: lowercasedTerm) {
            let startIndex = title.distance(from: title.startIndex, to: range.lowerBound)
            let length = searchTerm.count

            let before = String(title.prefix(startIndex))
            let match = String(title.dropFirst(startIndex).prefix(length))
            let after = String(title.dropFirst(startIndex + length))

            return Text(before)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            + Text(match)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.teal600)
            + Text(after)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        } else {
            return Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private var resultBadge: some View {
        let (text, bgColor, textColor) = badgeInfo

        return Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var badgeInfo: (String, Color, Color) {
        switch result.type {
        case .property:
            return ("PROPERTY", Color(hex: "F0FDFA"), AppColors.teal500)
        case .booking:
            return ("AIRBNB", Color(hex: "FFF1F0"), Color(hex: "FF5A5F"))
        case .expense:
            return ("EXPENSE", Color(hex: "FEF3C7"), Color(hex: "D97706"))
        case .guest:
            return ("GUEST", AppColors.tintedTeal, AppColors.teal500)
        }
    }
}

#Preview {
    SearchView(onDismiss: {})
}
