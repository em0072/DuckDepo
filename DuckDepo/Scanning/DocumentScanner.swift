//
//  DocumentScanner.swift
//  DuckDepo
//

import UIKit

/// A new document filled in from a scan, for the editor to show before anything is saved.
struct ScanDraft: Identifiable {
    var document: Document
    /// How sure the scan is of each field it filled in.
    var confidence: [Field.ID: ScanConfidence]
    /// Nothing could be read: the document has only its photos.
    var isEmpty: Bool

    var id: Document.ID { document.id }
}

/// Turns photos of a document into a prefilled draft, entirely on the device:
/// text recognition, then exact parsers (passport and ID-card zones, EU driving licences, VINs), then the
/// on-device language model for whatever is still empty.
enum DocumentScanner {

    /// Pages read for text. A scan may have more photos; they're all kept.
    static let maximumPagesRead = 4

    static func draft(from images: [UIImage], today: Date = .now) async -> ScanDraft {
        async let photos = Task.detached(priority: .userInitiated) {
            images.compactMap(DocumentPhoto.init(image:))
        }.value
        var lines: [String] = []
        for image in images.prefix(maximumPagesRead) {
            lines += await DocumentReader.lines(in: image)
        }
        let reading = await reading(from: lines, today: today)
        return makeDraft(from: reading, photos: await photos)
    }

    /// For photos already made (shared from another app), so they aren't compressed again.
    static func draft(from photos: [DocumentPhoto], today: Date = .now) async -> ScanDraft {
        var lines: [String] = []
        for photo in photos.prefix(maximumPagesRead) {
            // A decoded page only while it's read: `image` is a new one each time.
            lines += await DocumentReader.lines(in: photo.image)
        }
        let reading = await reading(from: lines, today: today)
        return makeDraft(from: reading, photos: photos)
    }

    static func reading(from lines: [String], today: Date = .now, useModel: Bool = true) async -> ScanReading {
        var reading = ScanReading()
        if let mrz = MRZParser.parse(lines: lines, today: today) {
            reading.add(mrz)
        }
        if let licence = DrivingLicenceParser.parse(lines: lines, today: today) {
            reading.add(licence)
        }
        if let vin = vin(in: lines) {
            reading.add(vin: vin)
        }
        let text = lines.joined(separator: "\n")
        if useModel, let model = await ModelExtractor.extract(from: text) {
            reading.add(model, text: text)
        }
        return reading
    }

    // MARK: - Draft

    static func makeDraft(from reading: ScanReading, photos: [DocumentPhoto]) -> ScanDraft {
        var confidence: [Field.ID: ScanConfidence] = [:]
        var sections: [DocSection] = []
        for sectionKey in [SectionKey.documentInfo, .owner, .vehicle] where sectionKey.fields.contains(where: { reading.values[$0] != nil }) {
            var section = sectionKey.makeSection()
            for index in section.fields.indices {
                guard let key = section.fields[index].fieldKey, let value = reading.values[key] else { continue }
                section.fields[index].value = value.text
                confidence[section.fields[index].id] = value.confidence
            }
            sections.append(section)
        }
        let document = Document(name: title(for: reading),
                                description: reading.holderName?.text ?? "",
                                documentType: documentType(for: reading),
                                photos: photos,
                                sections: sections)
        return ScanDraft(document: document, confidence: confidence, isEmpty: reading.isEmpty)
    }

    private static func title(for reading: ScanReading) -> String {
        switch reading.kind {
        case .passport: String(localized: "scan_kind_passport")
        case .idCard: String(localized: "scan_kind_id_card")
        case .drivingLicence: String(localized: "scan_kind_driving_licence")
        case .visa: String(localized: "scan_kind_visa")
        case nil: reading.modelTitle ?? ""
        }
    }

    private static func documentType(for reading: ScanReading) -> DocumentType {
        switch reading.kind {
        case .passport, .idCard: .identification
        case .drivingLicence: .transport
        case .visa: .government
        case nil: reading.modelCategory ?? (reading.values[.vin] != nil ? .transport : .other)
        }
    }

    // MARK: - VIN

    /// A vehicle identification number standing on its own: 17 characters, no I, O or Q.
    nonisolated(unsafe) private static let vinPattern = /(?:^|[^A-Z0-9])([A-HJ-NPR-Z0-9]{17})(?![A-Z0-9])/

    static func vin(in lines: [String]) -> String? {
        for line in lines {
            for match in line.uppercased().matches(of: vinPattern) {
                let candidate = String(match.output.1)
                // Real VINs mix letters and digits.
                if candidate.contains(where: \.isLetter), candidate.filter(\.isNumber).count >= 5 {
                    return candidate
                }
            }
        }
        return nil
    }
}
