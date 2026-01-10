import SwiftUI
import CoreData

struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var preselectedProperty: PropertyEntity? = nil
    var onDismiss: (() -> Void)? = nil

    private let settings = AppSettings.shared
    @State private var viewModel: CalendarViewModel?
    @State private var showBookingsList = false

    var body: some View {
        Group {
            if let viewModel {
                calendarContent(viewModel)
            } else {
                Color.clear
            }
        }
        .background(AppColors.background)
        .onAppear {
            if viewModel == nil {
                viewModel = CalendarViewModel(context: viewContext, preselectedProperty: preselectedProperty)
            } else {
                viewModel?.fetchData()
            }
        }
        .fullScreenCover(isPresented: $showBookingsList) {
            BookingsListView(onDismiss: { showBookingsList = false })
                .environment(\.managedObjectContext, viewContext)
                .preferredColorScheme(settings.colorScheme)
                .environment(\.locale, settings.locale)
        }
        .alert("Blocked Dates", isPresented: Binding(
            get: { viewModel?.showEditBlockedDate ?? false },
            set: { viewModel?.showEditBlockedDate = $0 }
        )) {
            Button("Unblock Dates", role: .destructive) {
                if let blocked = viewModel?.selectedBlockedDate {
                    viewModel?.deleteBlockedDate(blocked)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(blockedDateMessage)
        }
    }

    private var blockedDateMessage: String {
        guard let blocked = viewModel?.selectedBlockedDate else {
            return "Do you want to unblock these dates?"
        }
        let reason = blocked.reason ?? "No reason"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let start = blocked.startDate.map { formatter.string(from: $0) } ?? "?"
        let end = blocked.endDate.map { formatter.string(from: $0) } ?? "?"
        return "\(reason)\n\(start) - \(end)\n\nDo you want to unblock these dates?"
    }

    // MARK: - Main Content

    private func calendarContent(_ vm: CalendarViewModel) -> some View {
        VStack(spacing: 0) {
            headerSection(vm)

            if vm.allProperties.isEmpty {
                noBookingsEmptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        monthNavigation(vm)
                        CalendarGridView(viewModel: vm)

                        if vm.dayBookingMap.isEmpty {
                            noBookingsThisMonth(vm)
                        }

                        if vm.selectedDay != nil {
                            selectedDayBookings(vm)
                        }

                        if !vm.upcomingBookings.isEmpty {
                            bookingsList(vm)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenPadding)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(AppColors.background)
    }

    // MARK: - Header

    private func headerSection(_ vm: CalendarViewModel) -> some View {
        VStack(spacing: 14) {
            HStack {
                if onDismiss != nil {
                    Button { onDismiss?() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Text("Calendar")
                    .font(AppTypography.heading1)
                    .foregroundStyle(.white)

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CalendarFilterPill(
                        title: "All Properties",
                        isSelected: vm.selectedProperty == nil
                    ) {
                        vm.selectFilter(nil)
                    }

                    ForEach(vm.allProperties, id: \.objectID) { property in
                        CalendarFilterPill(
                            title: property.displayName,
                            isSelected: vm.selectedProperty?.objectID == property.objectID
                        ) {
                            vm.selectFilter(property)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.screenPadding)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Month Navigation

    private func monthNavigation(_ vm: CalendarViewModel) -> some View {
        HStack {
            Button { vm.shiftMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.surface)
                    .clipShape(Circle())
            }

            Spacer()

            Text(vm.monthTitle)
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Button { vm.shiftMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.surface)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - No Bookings Empty State (full illustration)

    private var noBookingsEmptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                // Main circle with emoji
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "F0FDFA"), Color(hex: "CCFBF1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Text("\u{1F4C5}")
                            .font(.system(size: 64))
                    )

                // Floating Airbnb badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColors.error)
                        .frame(width: 8, height: 8)
                    Text("Airbnb")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.error)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .offset(x: 80, y: -60)

                // Floating Booking badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppColors.info)
                        .frame(width: 8, height: 8)
                    Text("Booking")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.info)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppColors.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .offset(x: -75, y: 65)
            }
            .frame(width: 220, height: 200)

            Spacer().frame(height: 24)

            Text("No bookings yet")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Spacer().frame(height: 12)

            Text("Your calendar is empty. Add your first\nbooking to start tracking stays and income.")
                .font(.system(size: 15))
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer().frame(height: 32)

            Button {} label: {
                HStack(spacing: 8) {
                    Text("+")
                        .font(.system(size: 16, weight: .bold))
                    Text("Add Booking")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0D9488"), Color(hex: "0F766E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppColors.teal500.opacity(0.3), radius: 12, x: 0, y: 4)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - No Bookings This Month

    private func noBookingsThisMonth(_ vm: CalendarViewModel) -> some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 8)

            Text("\u{1F4ED}")
                .font(.system(size: 48))

            Text("No bookings this month")
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.textPrimary)

            Text("No bookings found for \(vm.monthTitle).\nAdd a booking or try a different month.")
                .font(AppTypography.bodySmall)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Selected Day Bookings

    private func selectedDayBookings(_ vm: CalendarViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedDayTitle(vm))
                .font(AppTypography.heading3)
                .foregroundStyle(AppColors.textPrimary)

            if vm.selectedDayBookings.isEmpty {
                Text("No bookings on this day")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(vm.selectedDayBookings, id: \.objectID) { booking in
                    let platform = booking.platform ?? "Direct"
                    CalendarBookingCard(
                        booking: booking,
                        propertyName: vm.propertyName(for: booking),
                        platformColor: CalendarViewModel.platformColor(for: platform),
                        platformTintedBg: CalendarViewModel.platformTintedBg(for: platform)
                    )
                }
            }
        }
    }

    private func selectedDayTitle(_ vm: CalendarViewModel) -> String {
        guard let day = vm.selectedDay else { return "" }
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: vm.displayedMonth)
        comps.day = day
        guard let date = cal.date(from: comps) else { return "Day \(day)" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Bookings List

    private func bookingsList(_ vm: CalendarViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Check-ins")
                    .font(AppTypography.heading3)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button { showBookingsList = true } label: {
                    Text("View all \u{2192}")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.teal600)
                }
            }

            if vm.upcomingBookings.isEmpty {
                Text("No upcoming check-ins for this filter.")
                    .font(AppTypography.bodySmall)
                    .foregroundStyle(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                ForEach(vm.upcomingBookings, id: \.objectID) { booking in
                    let platform = booking.platform ?? "Direct"
                    CalendarBookingCard(
                        booking: booking,
                        propertyName: vm.propertyName(for: booking),
                        platformColor: CalendarViewModel.platformColor(for: platform),
                        platformTintedBg: CalendarViewModel.platformTintedBg(for: platform)
                    )
                }
            }
        }
    }
}

// MARK: - Filter Pill

private struct CalendarFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? AppColors.teal600 : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? .white : .white.opacity(0.2))
                .clipShape(Capsule())
        }
    }
}
