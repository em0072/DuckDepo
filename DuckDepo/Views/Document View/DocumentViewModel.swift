//
//  NewDocumentViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import Foundation
import PDFKit

final class DocumentViewModel: ObservableObject {

    private let db: DataBase

    @Published var document: Document

    @Published var showShareOptions = false
    @Published var showShareSheetView = false
    @Published var showEditDocumentView = false
    @Published var showingImageViewer = false
    @Published var shouldDismissView = false

    @Published var selectedPhoto: DocumentPhoto? {
        didSet {
            showingImageViewer = selectedPhoto != nil
        }
    }

    var itemsToShare = [Any]()

    /// `document` usually comes from the list, which doesn't load photos, so read the full document here.
    init(document: Document, database: DataBase = .shared) {
        db = database
        self.document = database.fullDocument(with: document.id) ?? document
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
            text += section.name + ":\n"
            for field in section.fields {
                text += "\(field.title): \(field.value)\n"
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
