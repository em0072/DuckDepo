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
    /// An archived `NSArray` of JPEG `NSData`, one per photo. Kept in this format so older app versions can read it.
    @NSManaged public var photoData: Data?
    @NSManaged public var sections: Set<DDSection>?
    @NSManaged public var documentTypeOrder: Int16
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

    /// The stored JPEG data of each photo, in order.
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

    func photos() -> [DocumentPhoto] {
        photoDataItems().compactMap(DocumentPhoto.init(data:))
    }

    /// Stores the photos' existing JPEG data as is. Photos are never re-encoded, and nothing is
    /// written (or uploaded to iCloud) when the photos didn't change.
    func setPhotos(_ photos: [DocumentPhoto]) {
        let items = photos.map(\.data)
        guard items != photoDataItems() else { return }
        guard !items.isEmpty else {
            photoData = nil
            return
        }
        do {
            photoData = try NSKeyedArchiver.archivedData(withRootObject: items.map { $0 as NSData } as NSArray,
                                                         requiringSecureCoding: true)
        } catch {
            Self.logger.error("Archiving photos failed: \(String(describing: error), privacy: .public)")
        }
    }

    func getSections() -> [DDSection] {
        Array(sections ?? []).sorted()
    }
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
        return document
    }

    func updateType(newType: DocumentType) {
        documentType = newType.rawValue
        documentTypeOrder = Int16(newType.typeOrder)
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
