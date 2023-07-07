//
//  NewDocumentViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import Foundation
import PDFKit

class DocumentViewModel: ObservableObject {

    private var db = DataBase.shared
    @Published var document: Document
    
    @Published var showShareActionSheet = false
    @Published var showShareSheetView = false
    @Published var showEditDocumentView = false
    @Published var showingImageViewer = false
    @Published var shouldDismissView = false
    
    @Published var selectedPhoto: UIImage? {
        didSet {
            if selectedPhoto != nil {
                showingImageViewer = true
            } else {
                showingImageViewer = false
            }
        }
    }
    
    var itemsToShare = [Any]()

    
    init(document: Document) {
        self.document = document
    }
    
    var editDocumentViewModel: EditDocumentViewModel {
        let viewModel = EditDocumentViewModel(type: .existing(document)) { [weak self] document in
            guard let self else { return }
            guard let document else {
                shouldDismissView = true
                return
            }
            self.document = document
        }
        return viewModel
    }

    func shareButtonPressed() {
        if document.photos.isEmpty {
            shareTextButtonPressed()
        } else {
            showShareActionSheet = true
        }
    }
    
    func sharePhotosAndTextButtonPressed() {
        share(items: [constractSharePhotosPdf().dataRepresentation() as Any, constractShareText()])
    }

    func sharePhotosButtonPressed() {
        share(items: [constractSharePhotosPdf().dataRepresentation() as Any])
    }
    
    func shareTextButtonPressed() {
        share(items: [constractShareText()])
    }
    
    private func constractSharePhotosPdf() -> PDFDocument {
        let images = document.photos
        let pdfDocument = PDFDocument()
        for (i, image) in images.enumerated() {
            if let pdfPage = PDFPage(image: image) {
                pdfDocument.insert(pdfPage, at: i)
            }
        }
        return pdfDocument
    }
    
    private func constractShareText() -> String {
        var documentString: String = ""
        let docName = document.name
        documentString.append("dv_share_details_title".localized())
        documentString.append(docName)
        documentString.append("\n\n")
        
        for section in document.sections {
            documentString.append(section.name)
            documentString.append(":")
            documentString.append("\n")
            for field in section.fields {
                documentString.append(field.title)
                documentString.append(": ")
                documentString.append(field.value)
                documentString.append("\n")
            }
            documentString.append("\n")
        }
        documentString.append("dv_share_caption".localized())
        documentString.append("\n")
        documentString.append("https://DuckDepo.com")
        return documentString
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
//        db.canEdit()
        return true
    }
    
    
}
