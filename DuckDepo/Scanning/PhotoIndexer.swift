//
//  PhotoIndexer.swift
//  DuckDepo
//

import Combine
import CoreData
import UIKit

/// Reads the text of document photos that aren't in the `PhotoTextIndex` yet, one at a time, in the
/// background, and drops the text of photos that are gone. Runs again whenever documents change,
/// here or through iCloud.
@MainActor
final class PhotoIndexer {

    static let shared = PhotoIndexer(database: .shared, index: .shared)

    private let database: DataBase
    private let index: PhotoTextIndex
    private var storage: DocumentsStorage?
    private var subscription: AnyCancellable?
    private var isIndexing = false
    private var needsAnotherPass = false

    init(database: DataBase, index: PhotoTextIndex) {
        self.database = database
        self.index = index
    }

    /// Starts watching documents. Safe to call more than once.
    func start() {
        guard storage == nil else { return }
        let storage = DocumentsStorage(database: database)
        self.storage = storage
        subscription = storage.documents
            // Wait for edits and synced batches to settle; reading photos is slow work.
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.run() }
            }
    }

    /// Brings the index up to date. A call while a pass is running makes it go round once more.
    func run() async {
        guard !isIndexing else {
            needsAnotherPass = true
            return
        }
        isIndexing = true
        repeat {
            needsAnotherPass = false
            await indexMissingPhotos()
        } while needsAnotherPass
        isIndexing = false
    }

    /// One pass: forgets photos that are gone, then reads the ones not read yet.
    func indexMissingPhotos() async {
        let existing = await photoKeys()
        var changed = index.removeEntries(notIn: existing)
        let missing = existing.subtracting(index.keys)
        for key in missing {
            guard let data = await imageData(for: key), let image = UIImage(data: data) else { continue }
            let lines = await DocumentReader.lines(in: image)
            // Stored even when empty, so a photo without text isn't read again.
            index.set(lines.joined(separator: "\n"), for: key)
            changed = true
        }
        if changed {
            index.save()
            NotificationCenter.default.post(name: .photoTextIndexDidChange, object: nil)
        }
    }

    // MARK: - Store

    /// Every document photo, without loading any image data.
    private func photoKeys() async -> Set<PhotoTextIndex.Key> {
        await withCheckedContinuation { continuation in
            database.persistenceController.performBackgroundTask { context in
                let request = NSFetchRequest<NSDictionary>(entityName: DDPhoto.entityName)
                request.resultType = .dictionaryResultType
                request.propertiesToFetch = ["identifier", "document.identifier"]
                request.predicate = NSPredicate(format: "identifier != nil AND document.identifier != nil")
                let rows = (try? context.fetch(request)) ?? []
                let keys = rows.compactMap { row -> PhotoTextIndex.Key? in
                    guard let photoID = row["identifier"] as? UUID,
                          let documentID = row["document.identifier"] as? UUID else { return nil }
                    return PhotoTextIndex.Key(documentID: documentID, photoID: photoID)
                }
                continuation.resume(returning: Set(keys))
            }
        }
    }

    private func imageData(for key: PhotoTextIndex.Key) async -> Data? {
        await withCheckedContinuation { continuation in
            database.persistenceController.performBackgroundTask { context in
                let request = DDPhoto.fetchRequest()
                request.predicate = NSPredicate(format: "identifier == %@ AND document.identifier == %@",
                                                key.photoID as CVarArg, key.documentID as CVarArg)
                request.fetchLimit = 1
                let data = (try? context.fetch(request))?.first?.imageData
                continuation.resume(returning: data)
            }
        }
    }
}
