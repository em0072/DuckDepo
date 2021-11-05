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
        
        @Published var folders = [DDFolder]()
        @Published var document = Document()
        var type: DocumentType = .new
                
        var view: EditDocumentView?
        
        init() {
            folders = db.fetchFolder()
        }
        
        //MARK: -Data Manipulation
        private func saveDocument() {
            switch type {
            case .new:
                db.save(document, in: folders[selectedFolder])
            case .existing(_):
                db.update(document, in: folders[selectedFolder])
            }
            view?.isPresented = false
        }
        
        func updateViewWith(document: Document) {
            self.type = .existing(document)
            self.document = document
            let docFolder = document.folder
            for (i, folder)  in folders.enumerated() {
                if folder.name == docFolder {
                    selectedFolder = i
                }
            }
        }
        
        func delete() {
            db.delete(document)
            view?.isPresented = false
        }
                        
        
        //MARK: -Name & Folder
        //MARK: State
        @Published var selectedFolder: Int = 0
        
        //MARK: Functions
        
        
        //MARK: -Photo Section
        //MARK: State
        @Published var showingImageViewer: Bool = false
        @Published var imageViewerImage: Image?
        
        //MARK: Functions
        
        
        //MARK: -Add Button
        //MARK: State
        @Published var addButtonisDisabled: Bool = true
        //MARK: Functions
        func addNewDocumentButtonAction() {
            if folders[selectedFolder].fetchDocuments().map({ $0.name }).contains(document.name), case .new = type {
                view?.showAlert(title: "Duplicate", message: "The document with this name already exsists. Please choose a different name.")
            } else {
                saveDocument()
            }
        }
        
    }
}

// MARK: -PhotosSectionViewDelegate
extension EditDocumentView.ViewModel: PhotosSectionViewDelegate {
    
    func delete(photo: UIImage) {
        if let index = document.photos.firstIndex(of: photo) {
            withAnimation {
                document.photos.remove(at: index)
            }
        }
    }
    
    func select(photo: UIImage) {
        imageViewerImage = Image(uiImage: photo)
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


// MARK: -SectionsViewDelegate
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

//// MARK: -NSFetchedResultsControllerDelegate
//extension EditDocumentView.ViewModel: NSFetchedResultsControllerDelegate {
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        guard let folders = controller.fetchedObjects as? [DDFolder]
//        else { return }
//
//        self.folders = folders
//    }
//}
