//
//  Persistence.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import CoreData
import CloudKit
import os
#if !AUTOFILL_EXTENSION
import UIKit
#endif

extension Notification.Name {
    /// Posted on the main queue once the persistent store has been loaded (it can be deferred while the device is locked).
    static let persistentStoresDidLoad = Notification.Name("DuckDepo.persistentStoresDidLoad")
}

/// Owns the Core Data stack shared by the app and the AutoFill extension.
///
/// - The store lives in the App Group container so both processes read the same data.
/// - Only the app mirrors the store to CloudKit. The extension opens the same file without
///   CloudKit; its writes are recorded in persistent history and exported the next time the app runs.
final class PersistenceController {

    enum Role {
        case app
        case autoFill
        case inMemory

        static var current: Role {
            #if AUTOFILL_EXTENSION
            return .autoFill
            #else
            return .app
            #endif
        }

        var transactionAuthor: String {
            switch self {
            case .app: return "app"
            case .autoFill: return "autofill"
            case .inMemory: return "tests"
            }
        }
    }

    static let cloudKitContainerIdentifier = "iCloud.DuckDepo"

    static let shared = PersistenceController(role: .current)

    /// Loaded once per process. Several containers built from separately loaded copies of the
    /// same model make Core Data unable to map `DDDocument` etc. to a single entity.
    static let model: NSManagedObjectModel = {
        guard let url = Bundle(for: DDDocument.self).url(forResource: "DuckDepo", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("DuckDepo.momd is missing from the bundle")
        }
        return model
    }()

    /// Where the store lived before it moved to the App Group container (app sandbox only).
    static var legacyStoreURL: URL {
        NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("private.sqlite")
    }

    // MARK: - Public properties

    let role: Role
    let container: NSPersistentCloudKitContainer

    var context: NSManagedObjectContext {
        container.viewContext
    }

    private(set) var isLoaded = false
    private(set) var loadError: Error?

    /// Store for records other iCloud users share with this user. Sharing isn't set up yet.
    var sharedPersistentStore: NSPersistentStore? {
        nil
    }

    // MARK: - Private properties

    private let logger = Logger(subsystem: "DuckDepo", category: "Persistence")
    private var protectedDataObserver: NSObjectProtocol?
    private var remoteChangeObserver: NSObjectProtocol?
    private var historyToken: NSPersistentHistoryToken?

    /// Serial queue for persistent-history processing.
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    // MARK: - Init

    init(role: Role) {
        self.role = role
        container = NSPersistentCloudKitContainer(name: "DuckDepo", managedObjectModel: Self.model)

        let description = NSPersistentStoreDescription(url: Self.storeURL(for: role))
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        if role != .inMemory {
            description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        }
        if role == .app {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: Self.cloudKitContainerIdentifier)
        } else {
            description.cloudKitContainerOptions = nil
        }
        container.persistentStoreDescriptions = [description]

        let viewContext = container.viewContext
        viewContext.name = "viewContext"
        viewContext.transactionAuthor = role.transactionAuthor
        // Unsaved edits in the UI win over a concurrent CloudKit import of the same property.
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext.automaticallyMergesChangesFromParent = true

        loadStoreWhenPossible()
    }

    deinit {
        [protectedDataObserver, remoteChangeObserver].compactMap { $0 }.forEach(NotificationCenter.default.removeObserver)
    }

    // MARK: - Saving

    @discardableResult
    func saveContext() -> Bool {
        guard context.hasChanges else { return true }
        do {
            try context.save()
            return true
        } catch {
            logger.error("Save failed: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    func performBackgroundTask(block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }

    // MARK: - Loading

    private static func storeURL(for role: Role) -> URL {
        if role == .inMemory {
            return URL(fileURLWithPath: "/dev/null")
        }
        guard let groupURL = AppGroup.containerURL else {
            return legacyStoreURL
        }
        let directory = groupURL.appendingPathComponent("Library/Application Support/DuckDepo", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("private.sqlite")
    }

    private var storeURL: URL? {
        container.persistentStoreDescriptions.first?.url
    }

    private var isStoreInAppGroup: Bool {
        guard let storeURL, let groupURL = AppGroup.containerURL else { return false }
        return storeURL.path.hasPrefix(groupURL.path)
    }

    private func loadStoreWhenPossible() {
        #if !AUTOFILL_EXTENSION
        // The store is protected with `.complete`, so it can't be opened while the device is locked
        // (e.g. a background CloudKit push). Wait for the user to unlock instead of crashing.
        if role == .app, Thread.isMainThread, !UIApplication.shared.isProtectedDataAvailable {
            logger.notice("Protected data unavailable, deferring store load")
            if protectedDataObserver == nil {
                protectedDataObserver = NotificationCenter.default.addObserver(
                    forName: UIApplication.protectedDataDidBecomeAvailableNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    self?.loadStoreWhenPossible()
                }
            }
            return
        }
        #endif
        if let protectedDataObserver {
            NotificationCenter.default.removeObserver(protectedDataObserver)
            self.protectedDataObserver = nil
        }
        guard !isLoaded else { return }

        if role == .app {
            moveLegacyStoreIfNeeded()
        }
        container.loadPersistentStores { [weak self] _, error in
            self?.didLoadStore(error: error)
        }
    }

    private func didLoadStore(error: Error?) {
        if let error {
            loadError = error
            logger.error("Failed to load store: \(String(describing: error), privacy: .public)")
            return
        }
        isLoaded = true
        loadError = nil
        // `/dev/null` stores (tests) don't support query generations.
        if role != .inMemory {
            do {
                try context.setQueryGenerationFrom(.current)
            } catch {
                logger.error("Failed to pin the view context generation: \(String(describing: error), privacy: .public)")
            }
        }
        if role == .app {
            if isStoreInAppGroup {
                DefaultsController.shared.isSharedStoreReady = true
            }
            startMergingChangesFromOtherProcesses()
            #if DEBUG
            initializeCloudKitSchemaIfRequested()
            #endif
        }
        let post = { NotificationCenter.default.post(name: .persistentStoresDidLoad, object: self) }
        Thread.isMainThread ? post() : DispatchQueue.main.async(execute: post)
    }

    /// Before 2.7 the store lived in the app's own sandbox, so the AutoFill extension could not open it.
    /// Copy it into the App Group container once. If the copy fails, keep using the old location.
    private func moveLegacyStoreIfNeeded() {
        guard let description = container.persistentStoreDescriptions.first,
              let newURL = description.url,
              isStoreInAppGroup else { return }
        let legacyURL = Self.legacyStoreURL
        let fileManager = FileManager.default
        let coordinator = container.persistentStoreCoordinator

        if DefaultsController.shared.isSharedStoreReady {
            // Already moved. Remove a leftover copy if an earlier cleanup failed.
            if fileManager.fileExists(atPath: legacyURL.path) {
                try? coordinator.destroyPersistentStore(at: legacyURL, type: .sqlite)
            }
            return
        }
        guard fileManager.fileExists(atPath: legacyURL.path) else { return }

        do {
            if fileManager.fileExists(atPath: newURL.path) {
                // Nothing else writes here before the move is finished (the extension waits for
                // `isSharedStoreReady`), so the old store is the source of truth.
                try coordinator.destroyPersistentStore(at: newURL, type: .sqlite)
            }
            try coordinator.replacePersistentStore(
                at: newURL,
                destinationOptions: [NSPersistentStoreFileProtectionKey: FileProtectionType.complete],
                withPersistentStoreFrom: legacyURL,
                type: .sqlite
            )
            logger.notice("Moved the store into the App Group container")
        } catch {
            logger.error("Could not move the store into the App Group container: \(String(describing: error), privacy: .public)")
            description.url = legacyURL
            return
        }
        do {
            try coordinator.destroyPersistentStore(at: legacyURL, type: .sqlite)
        } catch {
            logger.error("Could not remove the old store: \(String(describing: error), privacy: .public)")
        }
    }

    #if DEBUG
    /// Run once with the `-InitializeCloudKitSchema` launch argument after changing the model,
    /// then deploy the schema to Production in the CloudKit Console.
    private func initializeCloudKitSchemaIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-InitializeCloudKitSchema") else { return }
        do {
            try container.initializeCloudKitSchema(options: [])
            logger.notice("CloudKit schema initialized")
        } catch {
            logger.error("CloudKit schema initialization failed: \(String(describing: error), privacy: .public)")
        }
    }
    #endif
}

// MARK: - Changes written by the AutoFill extension

extension PersistenceController {

    /// CloudKit imports are merged into the view context automatically, but writes from
    /// another process (the AutoFill extension) are only visible through persistent history.
    private func startMergingChangesFromOtherProcesses() {
        guard remoteChangeObserver == nil else { return }
        historyToken = DefaultsController.shared.historyToken(for: role.transactionAuthor)
            ?? container.persistentStoreCoordinator.currentPersistentHistoryToken(fromStores: nil)
        remoteChangeObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: nil
        ) { [weak self] _ in
            self?.mergeChangesFromOtherProcesses()
        }
    }

    /// Also called when the app becomes active, because a suspended app can miss the remote-change notification.
    func mergeChangesFromOtherProcesses() {
        guard role == .app, isLoaded else { return }
        historyQueue.addOperation { [weak self] in
            self?.processHistory()
        }
    }

    private func processHistory() {
        let taskContext = container.newBackgroundContext()
        var transactions: [NSPersistentHistoryTransaction] = []
        taskContext.performAndWait {
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: historyToken)
            if let fetchRequest = NSPersistentHistoryTransaction.fetchRequest {
                fetchRequest.predicate = NSPredicate(format: "author == %@", Role.autoFill.transactionAuthor)
                request.fetchRequest = fetchRequest
            }
            do {
                let result = try taskContext.execute(request) as? NSPersistentHistoryResult
                transactions = result?.result as? [NSPersistentHistoryTransaction] ?? []
            } catch {
                logger.error("Reading persistent history failed: \(String(describing: error), privacy: .public)")
            }
        }
        guard let lastToken = transactions.last?.token else { return }

        let viewContext = context
        viewContext.perform {
            for transaction in transactions {
                viewContext.mergeChanges(fromContextDidSave: transaction.objectIDNotification())
            }
        }
        historyToken = lastToken
        DefaultsController.shared.setHistoryToken(lastToken, for: role.transactionAuthor)
    }
}

// MARK: - Sharing

extension PersistenceController {

    func isShared(object: NSManagedObject) -> Bool {
        isShared(objectID: object.objectID)
    }

    func isShared(objectID: NSManagedObjectID) -> Bool {
        guard let persistentStore = objectID.persistentStore else { return false }
        if let sharedPersistentStore, persistentStore == sharedPersistentStore {
            return true
        }
        do {
            return try container.fetchShares(matching: [objectID])[objectID] != nil
        } catch {
            logger.error("Failed to fetch share for \(objectID): \(String(describing: error), privacy: .public)")
            return false
        }
    }

    func fetchRemoteShare(for object: NSManagedObject, completion: @escaping (CKShare?) -> Void) {
        guard let shareURL = fetchShare(for: object)?.url else {
            completion(nil)
            return
        }
        let operation = CKFetchShareMetadataOperation(shareURLs: [shareURL])
        operation.perShareMetadataResultBlock = { [logger] _, result in
            switch result {
            case .failure(let error):
                logger.error("CKFetchShareMetadataOperation failed: \(String(describing: error), privacy: .public)")
                completion(nil)
            case .success(let shareMeta):
                completion(shareMeta.share)
            }
        }
        CKContainer(identifier: Self.cloudKitContainerIdentifier).add(operation)
    }

    func fetchShare(for object: NSManagedObject) -> CKShare? {
        let shares = try? shares(matching: [object.objectID])
        return shares?[object.objectID]
    }

    func shares(matching objectIDs: [NSManagedObjectID]) throws -> [NSManagedObjectID: CKShare] {
        try container.fetchShares(matching: objectIDs)
    }

    func canEdit(object: NSManagedObject) -> Bool {
        container.canUpdateRecord(forManagedObjectWith: object.objectID)
    }

    func canDelete(object: NSManagedObject) -> Bool {
        container.canDeleteRecord(forManagedObjectWith: object.objectID)
    }
}
