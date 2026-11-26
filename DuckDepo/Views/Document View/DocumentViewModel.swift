//
//  NewDocumentViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import Foundation
import PDFKit

/// Cheap to create: SwiftUI may build and discard several instances; the one on screen loads in `load()`.
@Observable
final class DocumentViewModel {

    @ObservationIgnored private let db: DataBase
    @ObservationIgnored private var isLoaded = false

    var document: Document

    var showShareOptions = false
    var showShareSheetView = false
    var showEditDocumentView = false
    var shouldDismissView = false

    @ObservationIgnored var itemsToShare = [Any]()

    init(document: Document, database: DataBase = .shared) {
        db = database
        self.document = document
    }

    /// `document` usually comes from the list, which doesn't load photos, so read the full document once.
    func load() {
        guard !isLoaded else { return }
        isLoaded = true
        reload()
    }

    /// Reads the document again, for when it changed (edited, or synced from another device).
    func reload() {
        if let full = db.fullDocument(with: document.id) {
            document = full
        }
    }

    var editDocumentViewModel: EditDocumentViewModel {
        EditDocumentViewModel(type: .existing(document)) { [weak self] document in
            guard let self else { return }
            guard let document else {
                shouldDismissView = true
                return
            }
            self.document = db.fullDocument(with: document.id) ?? document
        }
    }

    func shareButtonPressed() {
        if document.photos.isEmpty {
            shareTextButtonPressed()
        } else {
            showShareOptions = true
        }
    }

    func sharePhotosAndTextButtonPressed() {
        share(items: [makePhotosPDF().dataRepresentation() as Any, makeShareText()])
    }

    func sharePhotosButtonPressed() {
        share(items: [makePhotosPDF().dataRepresentation() as Any])
    }

    func shareTextButtonPressed() {
        share(items: [makeShareText()])
    }

    private func makePhotosPDF() -> PDFDocument {
        let pdfDocument = PDFDocument()
        for (index, photo) in document.photos.enumerated() {
            if let page = PDFPage(image: photo.image) {
                pdfDocument.insert(page, at: index)
            }
        }
        return pdfDocument
    }

    private func makeShareText() -> String {
        var text = "dv_share_details_title".localized() + document.name + "\n\n"
        for section in document.sectionsWithValues {
            text += section.displayName + ":\n"
            for field in section.fields {
                text += "\(field.displayTitle): \(field.displayValue)\n"
            }
            text += "\n"
        }
        text += "dv_share_caption".localized() + "\nhttps://DuckDepo.com"
        return text
    }

    private func share(items: [Any]) {
        itemsToShare = items
        showShareSheetView = true
    }

    func onShareSheetDismiss() {
        itemsToShare.removeAll()
    }

    func editButtonPressed() {
        showEditDocumentView = true
    }

    func editAllowed() -> Bool {
        true
    }
}
