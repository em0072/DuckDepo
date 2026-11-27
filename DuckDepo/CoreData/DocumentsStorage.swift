//
//  DataBase Documents.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import CloudKit
import Combine
import CoreData

/// Publishes the document list. List items don't include photos; load a full
/// document with `DataBase.fullDocument(with:)` when it's opened.
final class DocumentsStorage: NSObject {

    let documents = CurrentValueSubject<[Document], Never>([])

    private let database: DataBase
    private let fetchedResultsController: NSFetchedResultsController<DDDocument>
    private var storeObserver: NSObjectProtocol?

    init(database: DataBase = .shared) {
        self.database = database
        let fetchRequest = DDDocument.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DDDocument.documentTypeOrder, ascending: true),
                                        NSSortDescriptor(keyPath: \DDDocument.order, ascending: true)]
        fetchRequest.relationshipKeyPathsForPrefetching = ["sections", "sections.fields", "photoRecords"]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: database.context,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        super.init()
        fetchedResultsController.delegate = self
        performFetch()
        // The store may load later than this object is created (device was locked).
        storeObserver = NotificationCenter.default.addObserver(forName: .persistentStoresDidLoad, object: nil, queue: .main) { [weak self] _ in
            self?.performFetch()
        }
    }

    deinit {
        if let storeObserver {
            NotificationCenter.default.removeObserver(storeObserver)
        }
    }

    private func performFetch() {
        do {
            try fetchedResultsController.performFetch()
            publish()
        } catch {
            database.logger.error("Fetching documents failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func publish() {
        documents.value = (fetchedResultsController.fetchedObjects ?? []).map { $0.convert(includePhotos: false) }
    }
}

extension DocumentsStorage: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        publish()
    }
}

extension DataBase {

    // MARK: - Sharing

    func isShared(_ document: DDDocument) -> Bool {
        persistenceController.isShared(object: document)
    }

    func isShared(_ document: Document) -> Bool {
        guard let fetchedDoc = fetchFromDB(document) else { return false }
        return persistenceController.isShared(object: fetchedDoc)
    }

    func share(document: DDDocument, completion: @escaping (CKShare?, CKContainer?, Error?) -> Void) {
        let share = persistenceController.fetchShare(for: document)
        persistenceController.container.share([document], to: share) { _, share, container, error in
            if let actualShare = share {
                document.managedObjectContext?.performAndWait {
                    actualShare[CKShare.SystemFieldKey.title] = document.name
                }
            }
            completion(share, container, error)
        }
    }

    func canEdit(_ document: DDDocument) -> Bool {
        persistenceController.canEdit(object: document)
    }

    func canDelete(_ document: DDDocument) -> Bool {
        persistenceController.canDelete(object: document)
    }

    // MARK: - CRUD

    @discardableResult
    func save(_ document: Document) -> Bool {
        _ = DDDocument(viewContext: context, object: document, order: fetchDocumentCount())
        return saveOrRollBack()
    }

    /// Adds many documents in one save, after the existing ones. A document already stored (by ID) is
    /// left alone. Returns how many were added, or nil if the save failed (then none were).
    @discardableResult
    func add(_ documents: [Document]) -> Int? {
        guard !documents.isEmpty else { return 0 }
        let request = DDDocument.fetchRequest()
        request.predicate = NSPredicate(format: "identifier IN %@", documents.map(\.id))
        let stored = Set(((try? context.fetch(request)) ?? []).compactMap(\.identifier))
        let new = documents.filter { !stored.contains($0.id) }
        guard !new.isEmpty else { return 0 }
        let first = fetchDocumentCount()
        for (offset, document) in new.enumerated() {
            _ = DDDocument(viewContext: context, object: document, order: first + offset)
        }
        return saveOrRollBack() ? new.count : nil
    }

    enum PhotosAddition: Equatable {
        case saved
        /// The document's photos take too much memory to add to in the share extension.
        case tooLarge
        case failed
    }

    /// In the share extension, adding pages reads a copy of the document's photos (the one version 2.6
    /// reads, which has to be rewritten); past this it could run out of memory.
    static let maximumPhotoBytesToAddTo = 30_000_000

    /// Adds photos after a document's own, leaving out ones it already has. Only the photos change, and the
    /// others aren't decoded: this runs in the share extension, whose copy of the rest may be out of date
    /// (it doesn't sync) and which has little memory.
    @discardableResult
    func addPhotos(_ photos: [DocumentPhoto], toDocumentWith id: UUID,
                   maximumExistingBytes: Int = maximumPhotoBytesToAddTo) -> PhotosAddition {
        readLatestStoredData()
        guard let stored = DDDocument.fetchDocument(with: id, viewContext: context) else { return .failed }
        guard (stored.photoData?.count ?? 0) <= maximumExistingBytes else {
            context.refresh(stored, mergeChanges: false)
            return .tooLarge
        }
        if stored.appendPhotos(photos) > 0 {
            stored.updatedAt = Date()
        }
        guard saveOrRollBack() else { return .failed }
        // Lets go of the photo data just read.
        context.refresh(stored, mergeChanges: false)
        return .saved
    }

    /// Every document without photos.
    func allDocuments() -> [Document] {
        ((try? context.fetch(DDDocument.fetchRequest())) ?? []).map { $0.convert(includePhotos: false) }
    }

    func fetchFromDB(_ document: Document) -> DDDocument? {
        DDDocument.fetchDocument(with: document.id, viewContext: context)
    }

    /// The document with its photos, as currently stored.
    func fullDocument(with id: UUID) -> Document? {
        DDDocument.fetchDocument(with: id, viewContext: context)?.convert(includePhotos: true)
    }

    @discardableResult
    func update(_ document: Document) -> Bool {
        guard let stored = DDDocument.fetchDocument(with: document.id, viewContext: context) else { return false }
        for section in stored.getSections() {
            for field in section.getAllFields() {
                context.delete(field)
            }
            context.delete(section)
        }
        stored.name = document.name
        stored.updateType(newType: document.documentType)
        stored.documentDescription = document.description
        stored.updatedAt = Date()
        stored.expiresAt = document.expiryDate
        stored.setPhotos(document.photos)
        for (index, section) in document.sections.enumerated() {
            stored.addToSections(DDSection(viewContext: context, object: section, order: index, document: stored))
        }
        return saveOrRollBack()
    }

    func fetchDocumentCount() -> Int {
        fetchCount(for: DDDocument.self)
    }

    @discardableResult
    func delete(_ document: Document) -> Bool {
        guard let stored = DDDocument.fetchDocument(with: document.id, viewContext: context) else { return false }
        context.delete(stored)
        return save()
    }
}
