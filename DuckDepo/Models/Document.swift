//
//  File.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import CryptoKit
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

struct Document: Identifiable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var documentType: DocumentType
    var photos: [DocumentPhoto]
    var sections: [DocSection]
    var folder: String?
    var order: Int?
    /// Set by the store. Nil for documents created before version 2.7.
    var createdAt: Date?
    var updatedAt: Date?

    init(id: UUID = UUID(), name: String = "", description: String = "",
         documentType: DocumentType = .identification, photos: [DocumentPhoto] = [],
         sections: [DocSection] = [], folder: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.documentType = documentType
        self.photos = photos
        self.sections = sections
        self.folder = folder
    }

    /// The day the document expires (midnight UTC), from its expiry date field.
    var expiryDate: Date? {
        sections.lazy.flatMap(\.fields)
            .first { $0.fieldKey == .expiryDate && $0.type == .date && !$0.value.isEmpty }
            .flatMap { FieldDate.utcDate(from: $0.value) }
    }

    /// Sections that have at least one filled-in field.
    var sectionsWithValues: [DocSection] {
        sections.compactMap { section in
            var section = section
            section.fields = section.fields.filter { !$0.value.isEmpty }
            return section.fields.isEmpty ? nil : section
        }
    }

    static var test: Document {
        let photos = ["duck", "screen1", "screen2"].compactMap { UIImage(named: $0) }.compactMap(DocumentPhoto.init(image:))
        let sections = [DocSection(name: "Document Info", fields: [Field(title: "Number", value: "12312414", type: .string),
                                                                   Field(title: "Series", value: "12", type: .string),
                                                                   Field(title: "Issue Date", value: "02.02.2022", type: .string),
                                                                   Field(title: "Expiration Date", value: "01.02.2032", type: .string)])]
        return Document(name: "Passport", description: "Evgeny Bobcat", documentType: .identification, photos: photos, sections: sections, folder: nil)
    }
}

/// A stored photo. Holds the JPEG data exactly as saved so editing a document never re-encodes it.
struct DocumentPhoto: Identifiable, Hashable {
    /// Longest side of newly added photos, in pixels. Large enough to read small print.
    static let maxPixelSize: CGFloat = 2560
    static let compressionQuality: CGFloat = 0.8
    /// Longest side of list thumbnails, in pixels.
    static let thumbnailPixelSize: CGFloat = 400

    /// Derived from the image bytes, so the same photo has the same ID on every device. That lets two
    /// devices that convert the same old photos to photo records recognise the copies as duplicates.
    let id: UUID
    let data: Data
    let image: UIImage

    init?(data: Data) {
        guard let image = UIImage(data: data) else { return nil }
        self.id = Self.identifier(for: data)
        self.data = data
        self.image = image
    }

    static func identifier(for data: Data) -> UUID {
        var bytes = Array(SHA256.hash(data: data).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x80 // version 8: custom (RFC 9562)
        bytes[8] = (bytes[8] & 0x3F) | 0x80 // RFC 4122 variant
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    /// A small JPEG for lists, made without decoding the full image.
    func makeThumbnailData() -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.thumbnailPixelSize,
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, thumbnail, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    /// Encodes a new photo once: scaled down to `maxPixelSize` and compressed as JPEG.
    init?(image: UIImage) {
        let scaled = image.scaledDown(toMaxPixelSize: Self.maxPixelSize)
        guard let data = scaled.jpegData(compressionQuality: Self.compressionQuality) else { return nil }
        self.init(data: data)
    }

    static func == (lhs: DocumentPhoto, rhs: DocumentPhoto) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
