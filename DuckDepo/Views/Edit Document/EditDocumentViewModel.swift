//
//  AddNewDocumentController.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI

extension EditDocumentView {
    class ViewModel: ObservableObject {
        
        enum DocumentType {
            case new
            case existing(Document)
        }
                        
        private let db: DataBase = DataBase.shared
        
        @Published var document: Document = Document()
        
        @Published var shouldCloseView: Bool = false
        
        var inputOption: InputOption = InputOption()
        var type: DocumentType
                
        var view: EditDocumentView?
        
        init(type: DocumentType) {
            self.type = type
            if case .existing(let document) = type {
                updateViewWith(document: document)
            }
        }
        
        //MARK: -Data Manipulation
        private func saveDocument() {
            switch type {
            case .new:
                db.save(document)
            case .existing(_):
                db.update(document)
            }
            shouldCloseView = true
        }
        
        func updateViewWith(document: Document) {
            self.document = document
        }
        
        func isShared() -> Bool {
            db.isShared(document)
        }
        
        func delete() {
            db.delete(document)
            shouldCloseView = true
        }
                                
        //MARK: - Name & Folder
        var viewTitle: LocalizedStringKey {
            switch type {
            case .new:
                return "add_new_doc"
            case .existing(let document):
                return "edit \(document.name)"
            }
        }

        //MARK: State
        @Published var selectedFolder: Int = 0
        
        //MARK: Functions

        
        //MARK: - Photo Section
        //MARK: State
        @Published var showingImageViewer: Bool = false
        @Published var imageViewerImage: UIImage?
        
        //MARK: Functions
        
        
        //MARK: - Add Button
        var saveButtonTitle: String {
            switch type {
            case .new:
                return "add_new_doc".localized()
            case .existing(_):
                return "save_changes".localized()
            }
        }
        //MARK: State
        @Published var addButtonisDisabled: Bool = true
        //MARK: Functions
        func addNewDocumentButtonAction() {
                saveDocument()
        }
        
        
    }
}

// MARK: -  PhotosSectionViewDelegate
extension EditDocumentView.ViewModel: PhotosSectionViewDelegate {
    
    func delete(photo: UIImage) {
        if let index = document.photos.firstIndex(of: photo) {
            withAnimation {
                _ = document.photos.remove(at: index)
            }
        }
    }
    
    func select(photo: UIImage) {
        imageViewerImage = photo
        showingImageViewer = true
    }
    
    func photoPicked(didPickPhoto photo: UIImage) {
        document.photos.append(photo)
    }
    
    func cameraPicker(didPickPhotos photos: [UIImage]) {
        photos.forEach { photo in
            document.photos.append(photo)
        }
    }
}


// MARK: - SectionsViewDelegate
extension EditDocumentView.ViewModel: SectionViewDelegate {
    func valueChanged(for field: Field, newValue: String) {
        for i in 0..<document.sections.count {
            if let index = document.sections[i].fields.firstIndex(of: field) {
                document.sections[i].fields[index].value = newValue
            }
        }
    }
    
    func delete(_ section: DocSection) {
        withAnimation {
            document.sections.removeAll(where: { $0 == section })
        }
    }
    
    func addNewFieldWith(name: String, in section: DocSection) {
        let newField = Field(title: name)
        guard let sectionIndex = document.sections.firstIndex(of: section) else { return }
        withAnimation {
            document.sections[sectionIndex].fields.append(newField)
        }
    }
    
    func fieldIsDuplicate(_ name: String, in section: DocSection) -> Bool {
        if let index = document.sections.firstIndex(of: section) {
            for field in document.sections[index].fields {
                if field.title == name {
                    return true
                }
            }
        }
        return false
    }
    
    func delete(_ field: Field, in section: DocSection) {
        if let sectionIndex = document.sections.firstIndex(of: section) {
            withAnimation {
                document.sections[sectionIndex].fields.removeAll(where: { $0 == field })
            }
        }
    }
    
}


// MARK: -AddSectionMenuDelegate
extension EditDocumentView.ViewModel: AddSectionMenuDelegate {
    
    func addNewSection(_ name: String) {
        let section = DocSection(name: name)
        withAnimation {
            document.sections.append(section)
        }
    }
    
    func sectionIsDuplicate(_ name: String) -> Bool {
        for section in document.sections {
            if section.name == name {
                return true
            }
        }
        return false
    }
    
}
