import SwiftUI
import CoreData

struct EditProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    var settings = AppSettings.shared
    var onDismiss: () -> Void

    @State private var fullName: String = ""
    @State private var phone: String = ""
    @State private var businessName: String = ""
    @State private var location: String = ""
    @State private var editingField: EditField? = nil
    @State private var showDeleteConfirmation = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PropertyEntity.createdAt, ascending: false)],
        animation: .default
    )
    private var properties: FetchedResults<PropertyEntity>

    private enum EditField: Hashable {
        case name, phone, business, location
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            formSection
        }
        .background(AppColors.background)
        .onAppear {
            loadProfile()
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Handle delete account
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack(spacing: 10) {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Text("Edit Profile")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button(action: saveProfile) {
                    Text("Save")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "2DD4A8"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)

            // Avatar
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "0D9488"), Color(hex: "2DD4A8")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(settings.userInitial.uppercased())
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundStyle(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: 2.5)
                        )

                    // Camera button
                    Circle()
                        .fill(Color(hex: "0D9488"))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "0A3D3D"), lineWidth: 2)
                        )
                }

                Text("Change Photo")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: "0A3D3D"), Color(hex: "0D7C6E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Form

    private var formSection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Full Name
                ProfileFormField(
                    label: "Full Name",
                    icon: "person.fill",
                    value: $fullName,
                    isEditing: editingField == .name,
                    isEditable: true,
                    onTap: { editingField = .name }
                )

                // Email (read-only)
                ProfileFormField(
                    label: "Email Address",
                    icon: "envelope.fill",
                    staticValue: settings.userEmail.isEmpty ? "user@example.com" : settings.userEmail,
                    footnote: "Verified · Cannot be changed"
                )

                // Phone
                ProfileFormField(
                    label: "Phone Number",
                    icon: "phone.fill",
                    value: $phone,
                    isEditing: editingField == .phone,
                    isEditable: true,
                    onTap: { editingField = .phone }
                )

                // Business Name
                ProfileFormField(
                    label: "Business Name",
                    icon: "building.2.fill",
                    value: $businessName,
                    isEditing: editingField == .business,
                    isEditable: true,
                    onTap: { editingField = .business }
                )

                // Location
                ProfileFormField(
                    label: "Location",
                    icon: "mappin.circle.fill",
                    value: $location,
                    isEditing: editingField == .location,
                    isEditable: true,
                    onTap: { editingField = .location }
                )

                // Properties (read-only)
                PropertiesCountField(count: properties.count)

                // Delete Account
                Button {
                    showDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 13))
                        Text("Delete Account")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(AppColors.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.tintedRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Actions

    private func loadProfile() {
        fullName = settings.userName
        phone = settings.userPhone
        businessName = settings.businessName
        location = settings.userLocation
    }

    private func saveProfile() {
        settings.userName = fullName
        settings.userPhone = phone
        settings.businessName = businessName
        settings.userLocation = location
        onDismiss()
    }
}

// MARK: - Form Field

private struct ProfileFormField: View {
    let label: String
    let icon: String
    var value: Binding<String>?
    var staticValue: String?
    var footnote: String?
    var isEditing: Bool = false
    var isEditable: Bool = false
    var onTap: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B7280"))
                .kerning(0.5)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(isEditing ? AppColors.teal500 : Color(hex: "9CA3AF"))
                    .frame(width: 16)

                if let value = value, isEditable {
                    TextField("", text: value)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                        .focused($isFocused)
                        .onTapGesture {
                            onTap?()
                            isFocused = true
                        }
                } else {
                    Text(staticValue ?? value?.wrappedValue ?? "")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isEditable {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundStyle(isEditing ? AppColors.teal500 : Color(hex: "9CA3AF"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEditing ? AppColors.teal500 : Color(hex: "E5E7EB"), lineWidth: 1.5)
            )

            if let footnote {
                Text(footnote)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "9CA3AF"))
            }
        }
    }
}

// MARK: - Properties Count Field

private struct PropertiesCountField: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PROPERTIES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "6B7280"))
                .kerning(0.5)

            HStack(spacing: 10) {
                Image(systemName: "house.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.teal500)
                    .frame(width: 16)

                Text("\(count) \(count == 1 ? String(localized: "Property") : String(localized: "Properties"))")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.teal500)

                Spacer()

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.success)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.tintedTeal)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "D1FAE5"), lineWidth: 1.5)
            )
        }
    }
}

#Preview {
    EditProfileView(onDismiss: {})
}
