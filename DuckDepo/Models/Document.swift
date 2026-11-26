//
//  File.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import Foundation
import UIKit

struct Document: Identifiable, Hashable {
    var id: UUID
    var name: String
    var description: String
    var documentType: DocumentType
    var photos: [DocumentPhoto]
    var sections: [DocSection]
    var folder: String?
    var order: Int?

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

    let id: UUID
    let data: Data
    let image: UIImage

    init?(data: Data) {
        guard let image = UIImage(data: data) else { return nil }
        self.id = UUID()
        self.data = data
        self.image = image
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
