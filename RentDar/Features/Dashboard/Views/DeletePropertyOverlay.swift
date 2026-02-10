import SwiftUI

struct DeletePropertyOverlay: View {
    let property: PropertyEntity
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @State private var isPresented = false

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(isPresented ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismissAndCancel() }

            // Centered card
            VStack(spacing: 0) {
                Spacer().frame(height: 24)

                // Red trash icon
                Circle()
                    .fill(AppColors.error.opacity(0.1))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "trash.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppColors.error)
                    )

                Spacer().frame(height: 16)

                Text("Delete Property?")
                    .font(AppTypography.heading2)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer().frame(height: 8)

                (Text("Are you sure you want to delete ")
                    .foregroundStyle(AppColors.textTertiary)
                 + Text(property.displayName)
                    .foregroundStyle(AppColors.textPrimary)
                    .bold()
                 + Text("?")
                    .foregroundStyle(AppColors.textTertiary))
                    .font(AppTypography.bodySmall)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 4)

                Text("This will permanently remove all bookings,\nincome, and expense records.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 16)

                // Stats row
                HStack(spacing: 0) {
                    DeleteStatItem(label: "Bookings", value: "0")
                    DeleteStatItem(label: "Income", value: "$0")
                    DeleteStatItem(label: "Expenses", value: "$0")
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 20)

                DangerButton(title: String(localized: "Yes, Delete Property")) {
                    onConfirm()
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 12)

                SecondaryButton(title: String(localized: "Cancel")) {
                    dismissAndCancel()
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 24)
            }
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
            .scaleEffect(isPresented ? 1 : 0.85)
            .opacity(isPresented ? 1 : 0)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
        .onAppear { isPresented = true }
    }

    private func dismissAndCancel() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onCancel()
        }
    }
}

// MARK: - Delete Stat Item

private struct DeleteStatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTypography.body)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.error)

            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
