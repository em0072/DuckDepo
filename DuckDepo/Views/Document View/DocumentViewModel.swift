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

    func sharePhotosAndTextButtonPressed() {
        share(items: [makePhotosPDF().dataRepresentation() as Any, document.plainText])
    }

    func sharePhotosButtonPressed() {
        share(items: [makePhotosPDF().dataRepresentation() as Any])
    }

    /// Every field at once, like the copy buttons: local only, and gone after the clipboard lifetime.
    func copyAllButtonPressed() {
        ClipboardController.shared.copy(string: document.plainText)
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
