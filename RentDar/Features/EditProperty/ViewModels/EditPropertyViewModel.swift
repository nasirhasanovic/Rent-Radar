import SwiftUI
import CoreData
import PhotosUI

@Observable
final class EditPropertyViewModel {
    // Form fields
    var propertyName: String
    var propertyType: PropertyType
    var address: String
    var city: String
    var state: String
    var nightlyRate: String
    var bedrooms: Int
    var bathrooms: Int
    var maxGuests: Int
    var selectedIllustrationIndex: Int?

    // Photo
    var selectedImage: UIImage?
    var selectedPhotoItem: PhotosPickerItem? {
        didSet { loadImage() }
    }
    private var existingCoverImageName: String?

    // Core Data reference
    private let propertyObjectID: NSManagedObjectID

    // Validation
    var isFormValid: Bool {
        !propertyName.trimmingCharacters(in: .whitespaces).isEmpty
            && !nightlyRate.isEmpty
            && (Double(nightlyRate) ?? 0) > 0
    }

    var nightlyRateValue: Double {
        Double(nightlyRate) ?? 0
    }

    init(property: PropertyEntity) {
        self.propertyObjectID = property.objectID
        self.propertyName = property.name ?? ""
        self.propertyType = property.type
        self.address = property.address ?? ""
        self.city = property.city ?? ""
        self.state = property.state ?? ""
        self.nightlyRate = property.nightlyRate > 0 ? String(Int(property.nightlyRate)) : ""
        self.bedrooms = Int(property.bedrooms)
        self.bathrooms = Int(property.bathrooms)
        self.maxGuests = Int(property.maxGuests)
        self.selectedIllustrationIndex = Int(property.illustrationIndex) >= 0
            ? Int(property.illustrationIndex) : nil
        self.existingCoverImageName = property.coverImageName
        self.selectedImage = property.coverImage
    }

    var hasCoverImage: Bool {
        selectedImage != nil
    }

    // MARK: - Steppers

    func incrementBedrooms() { bedrooms = min(bedrooms + 1, 20) }
    func decrementBedrooms() { bedrooms = max(bedrooms - 1, 0) }
    func incrementBathrooms() { bathrooms = min(bathrooms + 1, 20) }
    func decrementBathrooms() { bathrooms = max(bathrooms - 1, 0) }
    func incrementGuests() { maxGuests = min(maxGuests + 1, 50) }
    func decrementGuests() { maxGuests = max(maxGuests - 1, 1) }

    // MARK: - Save

    func saveChanges(context: NSManagedObjectContext) {
        guard let entity = try? context.existingObject(with: propertyObjectID) as? PropertyEntity else {
            return
        }

        entity.name = propertyName.trimmingCharacters(in: .whitespaces)
        entity.propertyType = propertyType.rawValue
        entity.address = address
        entity.city = city
        entity.state = state
        entity.nightlyRate = nightlyRateValue
        entity.bedrooms = Int16(bedrooms)
        entity.bathrooms = Int16(bathrooms)
        entity.maxGuests = Int16(maxGuests)
        entity.illustrationIndex = Int16(selectedIllustrationIndex ?? -1)

        // Handle image changes
        if let image = selectedImage, selectedPhotoItem != nil {
            // New photo was picked
            entity.coverImageName = AddPropertyViewModel.saveImageToDisk(image)
        } else if selectedImage == nil && existingCoverImageName != nil {
            // Photo was removed
            entity.coverImageName = nil
        }

        do {
            try context.save()
        } catch {
            print("Failed to save property changes: \(error)")
        }
    }

    // MARK: - Image Handling

    func removeImage() {
        selectedImage = nil
        selectedPhotoItem = nil
        existingCoverImageName = nil
        if selectedIllustrationIndex == nil {
            selectedIllustrationIndex = 0
        }
    }

    private func loadImage() {
        guard let item = selectedPhotoItem else { return }
        Task { @MainActor in
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
                selectedIllustrationIndex = nil
            }
        }
    }
}
