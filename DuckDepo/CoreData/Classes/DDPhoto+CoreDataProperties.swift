//
//  DDPhoto+CoreDataProperties.swift
//  DuckDepo
//

import CoreData
import Foundation

/// One photo of a document, synced as its own record (version 2.7 and later).
extension DDPhoto {

    static let entityName = "DDPhoto"

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DDPhoto> {
        NSFetchRequest<DDPhoto>(entityName: DDPhoto.entityName)
    }

    /// Derived from the image bytes (`DocumentPhoto.identifier(for:)`). Two records of the same
    /// document with the same identifier are copies of one photo.
    @NSManaged public var identifier: UUID?
    /// Random per record. Decides which copy survives de-duplication, the same way on every device.
    @NSManaged public var instanceID: UUID?
    @NSManaged public var order: Int16
    @NSManaged public var imageData: Data?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var createdAt: Date?
    @NSManaged public var document: DDDocument?
}

extension DDPhoto {

    convenience init(context: NSManagedObjectContext, photo: DocumentPhoto, order: Int, document: DDDocument) {
        self.init(context: context)
        identifier = photo.id
        instanceID = UUID()
        self.order = Int16(clamping: order)
        imageData = photo.data
        thumbnailData = photo.makeThumbnailData()
        createdAt = Date()
        self.document = document
    }

    /// Among copies of the same photo, the one every device keeps.
    static func survivor(of copies: [DDPhoto]) -> DDPhoto? {
        copies.min { ($0.instanceID?.uuidString ?? "") < ($1.instanceID?.uuidString ?? "") }
    }
}
