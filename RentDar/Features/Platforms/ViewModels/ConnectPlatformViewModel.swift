import SwiftUI
import CoreData

enum PlatformType: String, CaseIterable, Identifiable {
    case airbnb = "Airbnb"
    case booking = "Booking.com"
    case vrbo = "VRBO"
    case direct = "Direct"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .airbnb: return "flame.fill"
        case .booking: return "b.square.fill"
        case .vrbo: return "house.fill"
        case .direct: return "person.fill"
        }
    }

    var color: Color {
        switch self {
        case .airbnb: return Color(hex: "FF5A5F")
        case .booking: return Color(hex: "003580")
        case .vrbo: return Color(hex: "3B5998")
        case .direct: return AppColors.teal500
        }
    }

    var tintedBackground: Color {
        switch self {
        case .airbnb: return Color(hex: "FFF1F0")
        case .booking: return Color(hex: "E8F0FE")
        case .vrbo: return Color(hex: "EEF2FF")
        case .direct: return AppColors.tintedTeal
        }
    }

    var urlPattern: String {
        switch self {
        case .airbnb: return "airbnb.com/calendar/ical"
        case .booking: return "ical.booking.com"
        case .vrbo: return "vrbo.com"
        case .direct: return ""
        }
    }

    var instructions: [(step: Int, title: String, description: String)] {
        switch self {
        case .airbnb:
            return [
                (1, "Open your Airbnb listing", "Go to airbnb.com → Host Dashboard → Select your listing"),
                (2, "Go to Calendar settings", "Tap Calendar → Availability → Sync calendars"),
                (3, "Export Calendar", "Tap \"Export Calendar\" and copy the link that appears"),
                (4, "Paste it on the next screen", "Come back to RentDar and paste the copied link")
            ]
        case .booking:
            return [
                (1, "Open Booking.com Extranet", "Go to admin.booking.com and log in"),
                (2, "Navigate to Calendar", "Click Property → Calendar → Sync"),
                (3, "Export iCal URL", "Find \"Export Calendar\" and copy the iCal link"),
                (4, "Paste it on the next screen", "Come back to RentDar and paste the copied link")
            ]
        case .vrbo:
            return [
                (1, "Open VRBO Dashboard", "Go to vrbo.com and access your listing"),
                (2, "Find Calendar Export", "Go to Calendar → Import/Export"),
                (3, "Copy iCal Link", "Click \"Export\" and copy the calendar URL"),
                (4, "Paste it on the next screen", "Come back to RentDar and paste the copied link")
            ]
        case .direct:
            return []
        }
    }
}

enum ConnectPlatformStep: Int, CaseIterable {
    case instructions = 1
    case pasteURL = 2
    case syncing = 3
    case success = 4
}

@Observable
final class ConnectPlatformViewModel {
    var selectedPlatform: PlatformType = .airbnb
    var currentStep: ConnectPlatformStep = .instructions
    var calendarURL: String = ""
    var isValidURL: Bool = false
    var syncFrequency: Int = 30 // minutes
    var conflictAlertsEnabled: Bool = true

    // Sync progress
    var syncProgress: Double = 0
    var syncStatus: [SyncStatusItem] = []
    var isSyncing: Bool = false

    // Results
    var importedBookings: Int = 0
    var importedBlocked: Int = 0
    var conflicts: Int = 0
    var upcomingBookings: [ImportedBooking] = []

    let property: PropertyEntity
    private let context: NSManagedObjectContext

    init(property: PropertyEntity, context: NSManagedObjectContext) {
        self.property = property
        self.context = context
    }

    var urlHint: String {
        switch selectedPlatform {
        case .airbnb: return "airbnb.com/calendar/ical/..."
        case .booking: return "admin.booking.com/..."
        case .vrbo: return "vrbo.com/calendar/..."
        case .direct: return ""
        }
    }

    func validateURL() {
        let trimmed = calendarURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            isValidURL = false
            return
        }

        // Basic URL validation
        guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else {
            isValidURL = false
            return
        }

        // Platform-specific validation
        let pattern = selectedPlatform.urlPattern
        if !pattern.isEmpty {
            isValidURL = trimmed.lowercased().contains(pattern.lowercased())
        } else {
            isValidURL = true
        }
    }

    func nextStep() {
        guard let nextIndex = ConnectPlatformStep.allCases.firstIndex(where: { $0.rawValue == currentStep.rawValue + 1 }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = ConnectPlatformStep.allCases[nextIndex]
        }

        if currentStep == .syncing {
            startSync()
        }
    }

    func previousStep() {
        guard let prevIndex = ConnectPlatformStep.allCases.firstIndex(where: { $0.rawValue == currentStep.rawValue - 1 }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = ConnectPlatformStep.allCases[prevIndex]
        }
    }

    func startSync() {
        isSyncing = true
        syncProgress = 0
        syncStatus = []

        Task { @MainActor in
            // Step 1: Connect
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.spring(response: 0.3)) {
                syncStatus.append(SyncStatusItem(message: "Connecting to \(selectedPlatform.rawValue)...", time: "0.2s", isComplete: true))
                syncProgress = 0.15
            }

            // Step 2: Fetch calendar
            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.spring(response: 0.3)) {
                syncStatus.append(SyncStatusItem(message: "Fetching calendar data...", time: "0.4s", isComplete: true))
                syncProgress = 0.25
            }

            // Actually fetch the iCal data
            let events = await fetchAndParseICalendar()

            // Step 3: Report findings
            try? await Task.sleep(nanoseconds: 300_000_000)
            let reservations = events.filter { $0.isReservation }
            let blocked = events.filter { !$0.isReservation }

            withAnimation(.spring(response: 0.3)) {
                syncStatus.append(SyncStatusItem(message: "Found \(reservations.count) bookings, \(blocked.count) blocked", time: "1.2s", isComplete: true))
                syncProgress = 0.5
                importedBookings = reservations.count
                importedBlocked = blocked.count
            }

            // Step 4: Import bookings
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.spring(response: 0.3)) {
                syncStatus.append(SyncStatusItem(message: "Importing to RentDar...", time: "1.8s", isComplete: true))
                syncProgress = 0.7
            }

            // Save real bookings to Core Data
            saveBookingsToDatabase(events: events)

            // Convert to ImportedBooking for display
            upcomingBookings = reservations
                .filter { $0.startDate >= Date() }
                .sorted { $0.startDate < $1.startDate }
                .prefix(5)
                .map { event in
                    ImportedBooking(
                        guestName: event.guestName ?? "Guest",
                        startDate: event.startDate,
                        endDate: event.endDate,
                        nights: event.nights,
                        platform: selectedPlatform
                    )
                }

            // Step 5: Complete
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                syncProgress = 1.0
                isSyncing = false
                currentStep = .success
            }

            // Save connection info
            saveConnection()
        }
    }

    // MARK: - iCal Parsing

    private func fetchAndParseICalendar() async -> [ICalEvent] {
        guard let url = URL(string: calendarURL.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return []
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let icsContent = String(data: data, encoding: .utf8) else {
                return []
            }
            return parseICS(icsContent)
        } catch {
            print("Failed to fetch iCal: \(error)")
            return []
        }
    }

    private func parseICS(_ content: String) -> [ICalEvent] {
        var events: [ICalEvent] = []
        let lines = content.components(separatedBy: .newlines)

        var currentEvent: [String: String] = [:]
        var inEvent = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                currentEvent = [:]
            } else if trimmed == "END:VEVENT" {
                inEvent = false
                if let event = createEvent(from: currentEvent) {
                    events.append(event)
                }
            } else if inEvent {
                // Parse key:value pairs
                if let colonIndex = trimmed.firstIndex(of: ":") {
                    let key = String(trimmed[..<colonIndex])
                    let value = String(trimmed[trimmed.index(after: colonIndex)...])
                    // Handle keys with parameters like DTSTART;VALUE=DATE:20260209
                    let baseKey = key.components(separatedBy: ";").first ?? key
                    currentEvent[baseKey] = value
                }
            }
        }

        return events
    }

    private func createEvent(from dict: [String: String]) -> ICalEvent? {
        guard let dtStart = dict["DTSTART"],
              let dtEnd = dict["DTEND"] else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone.current

        guard let startDate = dateFormatter.date(from: dtStart),
              let endDate = dateFormatter.date(from: dtEnd) else {
            return nil
        }

        let summary = dict["SUMMARY"] ?? ""
        let description = dict["DESCRIPTION"] ?? ""
        let uid = dict["UID"] ?? UUID().uuidString

        let nights = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1

        // Determine if this is a real reservation or just blocked dates
        var isReservation = false
        var guestName: String? = nil

        let lowerSummary = summary.lowercased()

        if lowerSummary.contains("reserved") && !lowerSummary.contains("not available") {
            // Airbnb format: "Reserved" = actual booking
            isReservation = true
            guestName = "Airbnb Guest"
        } else if lowerSummary.contains("closed") || lowerSummary.contains("not available") {
            // Booking.com format: "CLOSED - Not available" for everything
            // Heuristic: treat short blocks (1-14 nights) as likely reservations
            // Longer blocks are probably manually blocked periods
            if nights <= 14 {
                isReservation = true
                guestName = "Booking.com Guest"
            }
        }

        return ICalEvent(
            uid: uid,
            startDate: startDate,
            endDate: endDate,
            summary: summary,
            description: description,
            isReservation: isReservation,
            guestName: guestName
        )
    }

    private func saveBookingsToDatabase(events: [ICalEvent]) {
        let reservations = events.filter { $0.isReservation }

        for event in reservations {
            // Check if this booking already exists (by UID)
            let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "externalId == %@", event.uid)

            do {
                let existing = try context.fetch(fetchRequest)
                if !existing.isEmpty {
                    continue // Skip duplicates
                }
            } catch {
                print("Error checking for existing booking: \(error)")
            }

            // Create new transaction
            let transaction = TransactionEntity(context: context)
            transaction.id = UUID()
            transaction.date = event.startDate
            transaction.endDate = event.endDate
            transaction.amount = property.nightlyRate * Double(event.nights)
            transaction.isIncome = true
            transaction.category = "Booking"
            transaction.platform = selectedPlatform.rawValue
            transaction.detail = event.guestName ?? "Imported from \(selectedPlatform.rawValue)"
            transaction.externalId = event.uid
            transaction.property = property
        }

        do {
            try context.save()
        } catch {
            print("Error saving bookings: \(error)")
        }
    }

    private func saveConnection() {
        // For now, just store the URL in UserDefaults as a simple approach
        // In a full implementation, you'd create a PlatformConnection entity
        let key = "platform_\(property.id?.uuidString ?? "")_\(selectedPlatform.rawValue)"
        UserDefaults.standard.set(calendarURL, forKey: key)
        UserDefaults.standard.set(Date(), forKey: "\(key)_lastSync")
    }
}

struct SyncStatusItem: Identifiable {
    let id = UUID()
    let message: String
    let time: String
    let isComplete: Bool
}

struct ImportedBooking: Identifiable {
    let id = UUID()
    let guestName: String
    let startDate: Date
    let endDate: Date
    let nights: Int
    let platform: PlatformType

    var dateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}

struct ICalEvent {
    let uid: String
    let startDate: Date
    let endDate: Date
    let summary: String
    let description: String
    let isReservation: Bool
    let guestName: String?

    var nights: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
    }
}
