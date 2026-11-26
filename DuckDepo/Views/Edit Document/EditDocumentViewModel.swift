//
//  AddNewDocumentController.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI

/// Cheap to create: SwiftUI may build and discard several instances; the one on screen loads in `load()`.
@Observable
final class EditDocumentViewModel {

    enum Mode {
        case new
        case existing(Document)
    }

    @ObservationIgnored private let db: DataBase
    private var originalDocument: Document
    @ObservationIgnored private let onDismiss: ((Document?) -> Void)?
    @ObservationIgnored private var isLoaded = false

    let type: Mode

    var document: Document
    private(set) var shouldCloseView = false
    var saveFailed = false

    var isShowingPhotoViewer = false
    var viewerPhotoID: DocumentPhoto.ID?

    init(type: Mode, database: DataBase = .shared, onDismiss: ((Document?) -> Void)? = nil) {
        self.type = type
        self.db = database
        self.onDismiss = onDismiss
        let initial: Document
        switch type {
        case .new:
            initial = Document()
        case .existing(let document):
            initial = document
        }
        document = initial
        originalDocument = initial
    }

    /// For an existing document, edits start from the stored version (with photos), not the caller's copy.
    /// Runs once, before anything is edited.
    func load() {
        guard !isLoaded else { return }
        isLoaded = true
        guard case .existing(let document) = type, let stored = db.fullDocument(with: document.id) else { return }
        self.document = stored
        originalDocument = stored
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
        viewerPhotoID = photo.id
        isShowingPhotoViewer = true
    }

    func add(photos: [DocumentPhoto]) {
        // A photo's ID comes from its bytes; adding the same picture twice would be one photo twice.
        var seen = Set(document.photos.map(\.id))
        let newPhotos = photos.filter { seen.insert($0.id).inserted }
        withAnimation {
            document.photos.append(contentsOf: newPhotos)
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

    func addField(_ field: Field, toSection sectionID: UUID) {
        guard let index = sectionIndex(sectionID) else { return }
        withAnimation {
            document.sections[index].fields.append(field)
        }
    }

    func deleteField(_ fieldID: UUID, inSection sectionID: UUID) {
        guard let index = sectionIndex(sectionID) else { return }
        withAnimation {
            document.sections[index].fields.removeAll { $0.id == fieldID }
        }
    }

    func fieldIsDuplicate(named name: String, inSection sectionID: UUID) -> Bool {
        guard let index = sectionIndex(sectionID) else { return false }
        return document.sections[index].fields.contains { Self.sameName($0.displayTitle, name) || Self.sameName($0.title, name) }
    }
}

// MARK: - AddSectionMenuDelegate

extension EditDocumentViewModel: AddSectionMenuDelegate {

    func addNewSection(_ section: DocSection) {
        withAnimation {
            document.sections.append(section)
        }
    }

    func sectionIsDuplicate(named name: String) -> Bool {
        document.sections.contains { Self.sameName($0.displayName, name) || Self.sameName($0.name, name) }
    }

    /// Predefined sections the document doesn't have yet.
    var availableSections: [SectionKey] {
        let present = Set(document.sections.compactMap(\.sectionKey))
        return SectionKey.allCases.filter { !present.contains($0) }
    }

    private static func sameName(_ lhs: String, _ rhs: String) -> Bool {
        lhs.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(rhs.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }
}
