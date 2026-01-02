import SwiftUI

struct PropertyMenuOverlay: View {
    let property: PropertyEntity
    var onEdit: () -> Void
    var onViewBookings: () -> Void
    var onDelete: () -> Void
    var onCancel: () -> Void

    @State private var isPresented = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dimmed backdrop
            Color.black.opacity(isPresented ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismissAndCancel() }

            // Bottom sheet
            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(AppColors.border)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                // Header: image/illustration + property info
                HStack(spacing: 12) {
                    if let coverImage = property.coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: property.illustrationGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.3))
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(property.displayName)
                            .font(AppTypography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.textPrimary)

                        Text(property.shortAddress)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 20)

                Divider()

                // Menu items
                PropertyMenuItem(icon: "pencil", title: "Edit Property", color: AppColors.textPrimary) {
                    dismissAndRun(onEdit)
                }

                PropertyMenuItem(icon: "calendar", title: "View Bookings", color: AppColors.textPrimary) {
                    dismissAndRun(onViewBookings)
                }

                PropertyMenuItem(icon: "trash", title: "Delete Property", color: AppColors.error) {
                    dismissAndRun(onDelete)
                }

                // Cancel button
                Button {
                    dismissAndCancel()
                } label: {
                    Text("Cancel")
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppSpacing.buttonHeight)
                }
                .padding(.bottom, 8)
            }
            .background(AppColors.surface)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 24,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 24
                )
            )
            .offset(y: isPresented ? 0 : 400)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
        .onAppear { isPresented = true }
    }

    private func dismissAndCancel() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onCancel()
        }
    }

    private func dismissAndRun(_ action: @escaping () -> Void) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            action()
        }
    }
}

// MARK: - Menu Item

private struct PropertyMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(color)

                Spacer()
            }
            .padding(.horizontal, AppSpacing.screenPadding)
            .frame(height: 52)
        }
    }
}
