//
//  NewDocumentViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import Foundation
import PDFKit
import SwiftUI

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

    /// The list's copy changed. When only the star or whose it is did, those are copied over; anything
    /// else reads the document again, photos and all.
    func listItemChanged(from old: Document, to new: Document) {
        var unchanged = old
        unchanged.isFavorite = new.isFavorite
        unchanged.personID = new.personID
        guard unchanged == new else {
            reload()
            return
        }
        document.isFavorite = new.isFavorite
        document.personID = new.personID
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
            let updated = db.fullDocument(with: document.id) ?? document
            withAnimation {
                self.document = updated
            }
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

    /// Shown at once; the list follows from the store.
    func toggleFavorite() {
        let isFavorite = !document.isFavorite
        guard db.setFavorite(isFavorite, forDocumentWith: document.id) else { return }
        document.isFavorite = isFavorite
    }

    func setPerson(_ personID: Person.ID?) {
        guard db.setPerson(personID, forDocumentWith: document.id) else { return }
        document.personID = personID
    }

    func editAllowed() -> Bool {
        true
    }
}
