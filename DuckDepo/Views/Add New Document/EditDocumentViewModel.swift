//
//  AddNewDocumentController.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI
import CoreData

protocol EditDocumentViewModelDelegate {
    var isPresented: Bool { get set }
    func showAlert(title: String, message: String)
}

extension EditDocumentView {
    class ViewModel: NSObject, ObservableObject {
        
        enum DocumentType {
            case new
            case existing(Document)
        }
        

        
        var viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext
        private let folderController: NSFetchedResultsController<DDFolder>
        
        @Published var folders = [DDFolder]()
        @Published var document = Document()
        var type: DocumentType = .new
                
        var view: EditDocumentViewModelDelegate?
                
        override init() {
            folderController = NSFetchedResultsController(fetchRequest: DDFolder.fetchRequest(), managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
            super.init()
            folderController.delegate = self
            fetchFolders()
            
        }
        
        func fetchFolders() {
            do {
                try folderController.performFetch()
                folders = folderController.fetchedObjects ?? []
            } catch {
                print("failed to fetch items!")
            }
        }
        
        //MARK: -Data Manipulation
        private func saveDocument() {
            switch type {
            case .new:
                let folderToSave = folders[selectedFolder]
                let order = folderToSave.getDocuments().count
                _ = DDDocument(viewContext: viewContext, object: document, order: order, folder: folderToSave)
            case .existing(_):
                if let fetchedDDDocument = DDDocument.fetchDocument(with: document.id, viewContext: viewContext) {
                    let folderToSave = folders[selectedFolder]
                    fetchedDDDocument.update(with: document, and: folderToSave, viewContext: viewContext)
                }
            }
            save()
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
            if let fetchedDDDocument = DDDocument.fetchDocument(with: document.id, viewContext: viewContext) {
                viewContext.delete(fetchedDDDocument)
                save()
                view?.isPresented = false
            }
        }
        
        func save() {
            do {
                try viewContext.save()
                view?.isPresented = false
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }

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
            if folders[selectedFolder].getDocuments().map({ $0.name }).contains(document.name), case .new = type {
                view?.showAlert(title: "Duplicate", message: "The document with this name already exsists. Please choose a different name.")
            } else {
                saveDocument()
            }
        }
        
    }
}

// MARK: -PhotosSectionViewDelegate
extension EditDocumentView.ViewModel: PhotosSectionViewDelegate {
    func select(photo: UIImage, at index: Int?) {
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

// MARK: -NSFetchedResultsControllerDelegate
extension EditDocumentView.ViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let folders = controller.fetchedObjects as? [DDFolder]
        else { return }
        
        self.folders = folders
    }
}
