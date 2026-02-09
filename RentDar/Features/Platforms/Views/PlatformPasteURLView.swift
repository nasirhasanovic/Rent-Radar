import SwiftUI

struct PlatformPasteURLView: View {
    @Bindable var viewModel: ConnectPlatformViewModel
    @FocusState private var isURLFieldFocused: Bool
    @State private var showValidation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Step indicator
                    StepIndicator(currentStep: viewModel.currentStep)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Paste your calendar link")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)

                        Text("Paste the iCal URL you copied from \(viewModel.selectedPlatform.rawValue)")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    // URL Input Card
                    urlInputCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // Sync Settings Card
                    syncSettingsCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // What syncs card
                    whatSyncsCard
                        .padding(.horizontal, 20)

                    Spacer(minLength: 100)
                }
            }

            // Connect button
            VStack {
            Spacer()

            Button {
                viewModel.nextStep()
            } label: {
                Text("Connect & Sync Now")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: viewModel.isValidURL
                                ? [AppColors.teal600, Color(hex: "0D7C6E")]
                                : [Color(hex: "9CA3AF"), Color(hex: "6B7280")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: viewModel.isValidURL ? AppColors.teal600.opacity(0.3) : .clear, radius: 12, y: 4)
            }
            .disabled(!viewModel.isValidURL)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        }
    }

    // MARK: - URL Input Card

    private var urlInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CALENDAR URL")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.teal500)
                .tracking(0.5)

            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.teal500)

                TextField("Paste your iCal URL here...", text: $viewModel.calendarURL, axis: .vertical)
                    .font(.system(size: 12).monospaced())
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(3)
                    .focused($isURLFieldFocused)
                    .onChange(of: viewModel.calendarURL) { _, _ in
                        viewModel.validateURL()
                        if !viewModel.calendarURL.isEmpty {
                            withAnimation(.spring(response: 0.3)) {
                                showValidation = true
                            }
                        }
                    }

                if !viewModel.calendarURL.isEmpty {
                    Button {
                        viewModel.calendarURL = ""
                        showValidation = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            .padding(12)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.border, lineWidth: 1)
            )

            // Validation message
            if showValidation && !viewModel.calendarURL.isEmpty {
                HStack(spacing: 6) {
                    if viewModel.isValidURL {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.success)
                        Text("Valid \(viewModel.selectedPlatform.rawValue) calendar link detected")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColors.success)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.error)
                        Text("This doesn't look like a valid \(viewModel.selectedPlatform.rawValue) URL")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AppColors.error)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.isValidURL && showValidation ? AppColors.teal500 : AppColors.border, lineWidth: viewModel.isValidURL && showValidation ? 2 : 1)
        )
        .animation(.spring(response: 0.3), value: viewModel.isValidURL)
    }

    // MARK: - Sync Settings Card

    private var syncSettingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sync Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            // Frequency
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync frequency")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("How often to check for updates")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                Menu {
                    Button("15 min") { viewModel.syncFrequency = 15 }
                    Button("30 min") { viewModel.syncFrequency = 30 }
                    Button("1 hour") { viewModel.syncFrequency = 60 }
                    Button("3 hours") { viewModel.syncFrequency = 180 }
                } label: {
                    Text(syncFrequencyText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.teal500)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.tintedTeal)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppColors.teal300, lineWidth: 1)
                        )
                }
            }

            Divider()
                .background(AppColors.border)

            // Conflict alerts toggle
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Conflict alerts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Notify on double-bookings")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer()

                Toggle("", isOn: $viewModel.conflictAlertsEnabled)
                    .tint(AppColors.teal500)
                    .labelsHidden()
            }
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private var syncFrequencyText: String {
        switch viewModel.syncFrequency {
        case 15: return String(localized: "15 min")
        case 30: return String(localized: "30 min")
        case 60: return String(localized: "1 hour")
        case 180: return String(localized: "3 hours")
        default: return String(localized: "\(viewModel.syncFrequency) min")
        }
    }

    // MARK: - What Syncs Card

    private var whatSyncsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What syncs from \(viewModel.selectedPlatform.rawValue)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            FlowLayout(spacing: 8) {
                SyncBadge(text: "Booking dates", included: true)
                SyncBadge(text: "Guest names", included: true)
                SyncBadge(text: "Blocked dates", included: true)
                SyncBadge(text: "Pricing", included: false)
                SyncBadge(text: "Reviews", included: false)
            }
        }
        .padding(16)
        .background(AppColors.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Sync Badge

private struct SyncBadge: View {
    let text: String
    let included: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: included ? "checkmark" : "xmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(included ? AppColors.teal500 : AppColors.error)

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(included ? AppColors.teal500 : AppColors.error)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(included ? AppColors.tintedTeal : Color(hex: "FEF2F2"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}
