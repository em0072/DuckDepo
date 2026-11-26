//
//  AddNewDocumentController.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI

final class EditDocumentViewModel: ObservableObject {

    enum Mode {
        case new
        case existing(Document)
    }

    private let db: DataBase
    private let originalDocument: Document
    private let onDismiss: ((Document?) -> Void)?

    let type: Mode
    let inputOption = InputOption()

    @Published var document: Document
    @Published private(set) var shouldCloseView = false
    @Published var saveFailed = false

    @Published var showingImageViewer = false
    @Published var imageViewerPhoto: DocumentPhoto?

    /// For an existing document, edits start from the stored version (with photos), not the caller's copy.
    init(type: Mode, database: DataBase = .shared, onDismiss: ((Document?) -> Void)? = nil) {
        self.type = type
        self.db = database
        self.onDismiss = onDismiss
        let initial: Document
        switch type {
        case .new:
            initial = Document()
        case .existing(let document):
            initial = database.fullDocument(with: document.id) ?? document
        }
        document = initial
        originalDocument = initial
    }

    var isNew: Bool {
        if case .new = type { return true }
        return false
    }

    var hasChanges: Bool {
        document != originalDocument
    }

    var canSave: Bool {
        !document.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var viewTitle: LocalizedStringKey {
        switch type {
        case .new: return "add_new_doc"
        case .existing(let document): return "edit \(document.name)"
        }
    }

    var saveButtonTitle: String {
        isNew ? "add_new_doc".localized() : "save_changes".localized()
    }

    // MARK: - Actions

    func save() {
        guard canSave else { return }
        let saved = isNew ? db.save(document) : db.update(document)
        guard saved else {
            saveFailed = true
            return
        }
        onDismiss?(document)
        shouldCloseView = true
    }

    func delete() {
        db.delete(document)
        onDismiss?(nil)
        shouldCloseView = true
    }

    func isShared() -> Bool {
        db.isShared(document)
    }

    private func sectionIndex(_ id: UUID) -> Int? {
        document.sections.firstIndex { $0.id == id }
    }
}

// MARK: - PhotosSectionViewDelegate

extension EditDocumentViewModel: PhotosSectionViewDelegate {

    func select(photo: DocumentPhoto) {
        imageViewerPhoto = photo
        showingImageViewer = true
    }

    func add(photos: [DocumentPhoto]) {
        withAnimation {
            document.photos.append(contentsOf: photos)
        }
    }

    func delete(photo: DocumentPhoto) {
        withAnimation {
            document.photos.removeAll { $0.id == photo.id }
        }
    }
}

// MARK: - SectionViewDelegate

extension EditDocumentViewModel: SectionViewDelegate {

    func deleteSection(_ sectionID: UUID) {
        withAnimation {
            document.sections.removeAll { $0.id == sectionID }
        }
    }

    func addField(named name: String, toSection sectionID: UUID) {
        guard let index = sectionIndex(sectionID) else { return }
        withAnimation {
            document.sections[index].fields.append(Field(title: name))
        }
    }

    func deleteField(_ fieldID: UUID, inSection sectionID: UUID) {
        guard let index = sectionIndex(sectionID) else { return }
        withAnimation {
            document.sections[index].fields.removeAll { $0.id == fieldID }
        }
    }

    func fieldIsDuplicate(_ name: String, inSection sectionID: UUID) -> Bool {
        guard let index = sectionIndex(sectionID) else { return false }
        return document.sections[index].fields.contains { $0.title == name }
    }
}

// MARK: - AddSectionMenuDelegate

extension EditDocumentViewModel: AddSectionMenuDelegate {

    func addNewSection(_ name: String) {
        withAnimation {
            document.sections.append(DocSection(name: name))
        }
    }

    func sectionIsDuplicate(_ name: String) -> Bool {
        document.sections.contains { $0.name == name }
    }
}
