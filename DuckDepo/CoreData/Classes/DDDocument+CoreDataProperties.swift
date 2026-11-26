//
//  DDDocument+CoreDataProperties.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//
//

import CoreData
import Foundation
import os

extension DDDocument {

    static let entityName = "DDDocument"

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDDocument> {
        NSFetchRequest<DDDocument>(entityName: DDDocument.entityName)
    }

    @NSManaged public var identifier: UUID?
    @NSManaged public var order: Int16
    @NSManaged public var name: String?
    @NSManaged public var documentDescription: String?
    @NSManaged public var documentType: String?
    @NSManaged public var sections: Set<DDSection>?
    @NSManaged public var documentTypeOrder: Int16
    /// Nil for documents created before version 2.7.
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    /// From the expiry date field, so documents can be sorted and reminded about without decoding fields.
    @NSManaged public var expiresAt: Date?

    /// The photos as their own records (2.7+). See "Photos" below for how they relate to `photoData`.
    @NSManaged public var photoRecords: Set<DDPhoto>?
    /// An archived `NSArray` of JPEG `NSData`, one per photo: the only photo storage before 2.7, which
    /// is still what 2.6 reads. Kept as a copy of `photoRecords` so devices that can't update keep working.
    @NSManaged public var photoData: Data?
    /// `legacyPhotosKey(for:)` of the `photoData` that `photoRecords` were last matched with. When it
    /// differs, `photoData` was changed by version 2.6 (or never converted) and is converted again.
    @NSManaged public var legacyPhotosKey: String?
}

// MARK: Generated accessors for sections
extension DDDocument {

    @objc(addSectionsObject:)
    @NSManaged public func addToSections(_ value: DDSection)

    @objc(removeSectionsObject:)
    @NSManaged public func removeFromSections(_ value: DDSection)

    @objc(addSections:)
    @NSManaged public func addToSections(_ values: NSSet)

    @objc(removeSections:)
    @NSManaged public func removeFromSections(_ values: NSSet)
}

extension DDDocument: Comparable {
    public static func < (lhs: DDDocument, rhs: DDDocument) -> Bool {
        lhs.order < rhs.order
    }
}

// MARK: - Photos

extension DDDocument {

    private static let logger = Logger(subsystem: "DuckDepo", category: "Photos")

    /// Photo records in order, one per photo: when two devices converted the same photo, only the copy
    /// `DDPhoto.survivor(of:)` picks is used (the others are deleted by `removeDuplicatePhotoRecords`).
    func photoRecordList() -> [DDPhoto] {
        let copies = Dictionary(grouping: photoRecords ?? []) { $0.identifier }
        return copies.values.compactMap(DDPhoto.survivor(of:)).sorted { $0.order < $1.order }
    }

    /// The photos from the records. Falls back to `photoData` while it is newer (not converted yet, or
    /// changed by version 2.6) and while the records haven't arrived from iCloud yet.
    func photos() -> [DocumentPhoto] {
        let items = photoDataItems()
        let records = photoRecordList()
        guard legacyPhotosKey == Self.legacyPhotosKey(for: items), !records.isEmpty else {
            return items.compactMap(DocumentPhoto.init(data:))
        }
        return records.compactMap { $0.imageData.flatMap(DocumentPhoto.init(data:)) }
    }

    /// The first photo's thumbnail, for lists.
    func firstThumbnailData() -> Data? {
        photoRecordList().first?.thumbnailData
    }

    /// Saves the photos as records and as the `photoData` copy that version 2.6 reads. Photos are never
    /// re-encoded, and unchanged photos are not written again (or uploaded to iCloud).
    func setPhotos(_ photos: [DocumentPhoto]) {
        syncPhotoRecords(with: photos)
        let items = photos.map(\.data)
        if items != photoDataItems() {
            photoData = Self.archive(items)
        }
        let key = Self.legacyPhotosKey(for: items)
        if legacyPhotosKey != key {
            legacyPhotosKey = key
        }
    }

    /// Converts `photoData` to records if it was never converted or version 2.6 changed it since.
    /// Returns whether anything changed.
    @discardableResult
    func convertLegacyPhotosIfNeeded() -> Bool {
        let items = photoDataItems()
        let key = Self.legacyPhotosKey(for: items)
        guard key != legacyPhotosKey else { return false }
        syncPhotoRecords(with: items.compactMap(DocumentPhoto.init(data:)))
        legacyPhotosKey = key
        return true
    }

    /// Deletes extra copies of a photo, made when two devices converted the same old photos at once.
    /// Every device keeps the same copy, so they never delete each other's survivor.
    @discardableResult
    func removeDuplicatePhotoRecords() -> Int {
        var removed = 0
        for copies in Dictionary(grouping: photoRecords ?? [], by: \.identifier).values where copies.count > 1 {
            let survivor = DDPhoto.survivor(of: copies)
            for copy in copies where copy !== survivor {
                managedObjectContext?.delete(copy)
                removed += 1
            }
        }
        return removed
    }

    /// Makes the records match `photos`: keeps existing records (reordering them if needed), adds new
    /// ones and deletes the rest.
    private func syncPhotoRecords(with photos: [DocumentPhoto]) {
        guard let context = managedObjectContext else { return }
        let records = photoRecordList()
        var existing = Dictionary(records.compactMap { record in record.identifier.map { ($0, record) } },
                                  uniquingKeysWith: { first, _ in first })
        for (index, photo) in photos.enumerated() {
            if let record = existing.removeValue(forKey: photo.id) {
                if record.order != Int16(clamping: index) {
                    record.order = Int16(clamping: index)
                }
            } else {
                _ = DDPhoto(context: context, photo: photo, order: index, document: self)
            }
        }
        for record in existing.values {
            context.delete(record)
        }
        for record in photoRecords ?? [] where record.identifier == nil {
            context.delete(record)
        }
    }

    /// The stored JPEG data of each photo in `photoData`, in order.
    func photoDataItems() -> [Data] {
        guard let photoData else { return [] }
        do {
            let items = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: NSData.self, from: photoData) ?? []
            return items.map { $0 as Data }
        } catch {
            Self.logger.error("Unarchiving photos failed: \(String(describing: error), privacy: .public)")
            return []
        }
    }

    /// Identifies a `photoData` value by its photos, not its archive bytes (which could differ between OS versions).
    static func legacyPhotosKey(for items: [Data]) -> String? {
        items.isEmpty ? nil : items.map { DocumentPhoto.identifier(for: $0).uuidString }.joined(separator: ",")
    }

    private static func archive(_ items: [Data]) -> Data? {
        guard !items.isEmpty else { return nil }
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: items.map { $0 as NSData } as NSArray,
                                                    requiringSecureCoding: true)
        } catch {
            logger.error("Archiving photos failed: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    func getSections() -> [DDSection] {
        Array(sections ?? []).sorted()
    }
}

// MARK: Generated accessors for photoRecords
extension DDDocument {

    @objc(addPhotoRecordsObject:)
    @NSManaged public func addToPhotoRecords(_ value: DDPhoto)

    @objc(removePhotoRecordsObject:)
    @NSManaged public func removeFromPhotoRecords(_ value: DDPhoto)
}

// MARK: - Conversion

extension DDDocument {

    convenience init(viewContext: NSManagedObjectContext, object: Document, order: Int) {
        self.init(context: viewContext)
        identifier = object.id
        name = object.name
        documentDescription = object.description
        updateType(newType: object.documentType)
        self.order = Int16(clamping: order)
        let now = Date()
        createdAt = now
        updatedAt = now
        expiresAt = object.expiryDate
        setPhotos(object.photos)
        for (index, section) in object.sections.enumerated() {
            addToSections(DDSection(viewContext: viewContext, object: section, order: index, document: self))
        }
    }

    /// Decoding photos is expensive, so lists convert without them.
    func convert(includePhotos: Bool) -> Document {
        let documentType = DocumentType(rawValue: self.documentType ?? "") ?? .other
        var document = Document(id: identifier ?? UUID(),
                                name: name ?? "",
                                description: documentDescription ?? "",
                                documentType: documentType,
                                photos: includePhotos ? photos() : [],
                                sections: getSections().map { $0.convert() })
        document.order = Int(order)
        document.createdAt = createdAt
        document.updatedAt = updatedAt
        // From the records even when 2.6 changed `photoData` since: checking that means reading every
        // document's photos. The migration updates the records at the next launch.
        if let first = photoRecordList().first, let id = first.identifier, let data = first.thumbnailData {
            document.thumbnail = Document.Thumbnail(id: id, data: data)
        }
        return document
    }

    func updateType(newType: DocumentType) {
        documentType = newType.rawValue
        documentTypeOrder = Int16(newType.typeOrder)
    }

    /// Recomputes `expiresAt` from the fields; returns whether it changed.
    @discardableResult
    func refreshExpiryDate() -> Bool {
        let expiry = convert(includePhotos: false).expiryDate
        guard expiresAt != expiry else { return false }
        expiresAt = expiry
        return true
    }

    static func fetchDocument(with id: UUID, viewContext: NSManagedObjectContext) -> DDDocument? {
        var fetchedDocument: DDDocument?
        viewContext.performAndWait {
            let fetchRequest = DDDocument.fetchRequest()
            fetchRequest.predicate = DDDocument.predicate(for: id)
            fetchRequest.fetchLimit = 1
            fetchedDocument = (try? viewContext.fetch(fetchRequest))?.first
        }
        return fetchedDocument
    }

    static func predicate(for id: UUID) -> NSPredicate {
        NSPredicate(format: "identifier = %@", id as CVarArg)
    }
}

extension DDDocument: Identifiable, CoreDataCountable {
}
