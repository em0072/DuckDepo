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
        /// A new document filled in from a scan, to review before saving.
        case scanned(ScanDraft)
    }

    @ObservationIgnored private let db: DataBase
    private var originalDocument: Document
    @ObservationIgnored private let onDismiss: ((Document?) -> Void)?
    @ObservationIgnored private var isLoaded = false
    /// The values a scan filled in, and how sure it was of each.
    @ObservationIgnored private let scannedValues: [Field.ID: (value: String, confidence: ScanConfidence)]

    let type: Mode
    /// Whether "Belongs To" shows, and a scan gets a suggestion. Off in the share extension while the
    /// app is locked: nothing stored shows there before Face ID.
    let showsPeople: Bool

    var document: Document
    private(set) var shouldCloseView = false
    var saveFailed = false

    var isShowingPhotoViewer = false
    var viewerPhotoID: DocumentPhoto.ID?
    /// For a scan: whose it probably is, from the name on it.
    private(set) var suggestedPersonID: Person.ID?

    /// - Parameter personID: Whose a new document is to begin with (the person the list shows).
    init(type: Mode, database: DataBase = .shared, personID: Person.ID? = nil, showsPeople: Bool = true,
         onDismiss: ((Document?) -> Void)? = nil) {
        self.type = type
        self.db = database
        self.showsPeople = showsPeople
        self.onDismiss = onDismiss
        var scannedValues: [Field.ID: (value: String, confidence: ScanConfidence)] = [:]
        switch type {
        case .new:
            let initial = Document(personID: personID)
            document = initial
            originalDocument = initial
        case .existing(let document):
            self.document = document
            originalDocument = document
        case .scanned(let draft):
            var scanned = draft.document
            scanned.personID = personID
            document = scanned
            // Compared with an empty document, so closing asks before throwing the scan away.
            originalDocument = Document(id: draft.document.id)
            for field in draft.document.sections.flatMap(\.fields) {
                if let confidence = draft.confidence[field.id] {
                    scannedValues[field.id] = (field.value, confidence)
                }
            }
        }
        self.scannedValues = scannedValues
    }

    /// How a field's value got there from a scan. Nil once the user changes it: then it's theirs.
    func scanConfidence(for field: Field) -> ScanConfidence? {
        guard let scanned = scannedValues[field.id], scanned.value == field.value else { return nil }
        return scanned.confidence
    }

    /// For a scanned document: whether the scan found nothing to fill in. Nil for other documents.
    var scanFoundNothing: Bool? {
        guard case .scanned(let draft) = type else { return nil }
        return draft.isEmpty
    }

    /// Shows the suggestion until another person is picked.
    var isPersonSuggested: Bool {
        suggestedPersonID != nil && document.personID == suggestedPersonID
    }

    /// For an existing document, edits start from the stored version (with photos), not the caller's copy.
    /// A scan gets the person it probably belongs to. Runs once, before anything is edited.
    func load() {
        guard !isLoaded else { return }
        isLoaded = true
        switch type {
        case .existing(let document):
            guard let stored = db.fullDocument(with: document.id) else { return }
            self.document = stored
            originalDocument = stored
        case .scanned:
            guard showsPeople else { return }
            if let suggestion = PersonSuggestion.person(for: document, in: db) {
                suggestedPersonID = suggestion
                document.personID = suggestion
            }
        case .new:
            break
        }
    }

    var isNew: Bool {
        if case .existing = type { return false }
        return true
    }

    var hasChanges: Bool {
        document != originalDocument
    }

    var canSave: Bool {
        !document.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var viewTitle: LocalizedStringKey {
        switch type {
        case .new, .scanned: return "add_new_doc"
        case .existing(let document): return "edit \(document.name)"
        }
    }

    // MARK: - Actions

    func save() {
        guard canSave else { return }
        // Whose it is only when changed here: the copy loaded may be older than a change made meanwhile
        // (on another device, say).
        let saved = isNew ? db.save(document) : db.update(document, includingPerson: document.personID != originalDocument.personID)
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
