import SwiftUI
import CoreData
import PhotosUI

@Observable
final class AddPropertyViewModel {
    // Step tracking
    var currentStep = 1
    let totalSteps = 3

    // Step 1: Basic Information
    var propertyName = ""
    var propertyType: PropertyType = .shortTerm
    var address = ""
    var city = ""
    var state = ""

    // Step 2: Property Details
    var bookingSource: BookingSource = .airbnb
    var nightlyRate = ""
    var bedrooms = 2
    var bathrooms = 1
    var maxGuests = 4
    var propertyDescription = ""

    // Step 3: Photos
    var selectedIllustrationIndex: Int? = 0
    var selectedImage: UIImage?
    var selectedPhotoItem: PhotosPickerItem? {
        didSet { loadImage() }
    }

    // State
    var isCompleted = false
    var savedProperty: PropertyEntity?

    var isStep1Valid: Bool {
        !propertyName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isStep2Valid: Bool {
        !nightlyRate.isEmpty && (Double(nightlyRate) ?? 0) > 0
    }

    var nightlyRateValue: Double {
        Double(nightlyRate) ?? 0
    }

    func nextStep() {
        guard currentStep < totalSteps else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentStep += 1
        }
    }

    func previousStep() {
        guard currentStep > 1 else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            currentStep -= 1
        }
    }

    func incrementBedrooms() { bedrooms = min(bedrooms + 1, 20) }
    func decrementBedrooms() { bedrooms = max(bedrooms - 1, 0) }
    func incrementBathrooms() { bathrooms = min(bathrooms + 1, 20) }
    func decrementBathrooms() { bathrooms = max(bathrooms - 1, 0) }
    func incrementGuests() { maxGuests = min(maxGuests + 1, 50) }
    func decrementGuests() { maxGuests = max(maxGuests - 1, 1) }

    func saveProperty(context: NSManagedObjectContext) {
        let entity = PropertyEntity(context: context)
        entity.id = UUID()
        entity.name = propertyName.trimmingCharacters(in: .whitespaces)
        entity.propertyType = propertyType.rawValue
        entity.address = address
        entity.city = city
        entity.state = state
        entity.bookingSource = bookingSource.rawValue
        entity.nightlyRate = nightlyRateValue
        entity.bedrooms = Int16(bedrooms)
        entity.bathrooms = Int16(bathrooms)
        entity.maxGuests = Int16(maxGuests)
        entity.propertyDescription = propertyDescription
        entity.illustrationIndex = Int16(selectedIllustrationIndex ?? -1)
        entity.createdAt = Date()

        if let image = selectedImage {
            entity.coverImageName = Self.saveImageToDisk(image)
        }

        do {
            try context.save()
            savedProperty = entity
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isCompleted = true
            }
        } catch {
            print("Failed to save property: \(error)")
        }
    }

    func reset() {
        currentStep = 1
        propertyName = ""
        propertyType = .shortTerm
        address = ""
        city = ""
        state = ""
        bookingSource = .airbnb
        nightlyRate = ""
        bedrooms = 2
        bathrooms = 1
        maxGuests = 4
        propertyDescription = ""
        selectedIllustrationIndex = 0
        selectedImage = nil
        selectedPhotoItem = nil
        isCompleted = false
        savedProperty = nil
    }

    // MARK: - Image Handling

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

    static func saveImageToDisk(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let url = Self.imagesDirectory.appendingPathComponent(fileName)
        do {
            try FileManager.default.createDirectory(at: Self.imagesDirectory, withIntermediateDirectories: true)
            try data.write(to: url)
            return fileName
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }

    static var imagesDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PropertyImages")
    }
}
