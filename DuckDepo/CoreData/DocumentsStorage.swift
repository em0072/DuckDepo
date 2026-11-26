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
        fetchRequest.relationshipKeyPathsForPrefetching = ["sections", "sections.fields"]
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
        return save()
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
        return save()
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
