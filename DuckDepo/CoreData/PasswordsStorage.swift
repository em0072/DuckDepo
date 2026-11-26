//
//  PasswordsDataBase.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Combine
import CoreData
import Foundation

/// Password records live in Core Data; their values live in the keychain.
///
/// List items are published without values. Read a value with `value(for:)` only when it's needed.
final class PasswordsStorage: NSObject {

    let passwords = CurrentValueSubject<[Password], Never>([])

    private let database: DataBase
    private let keychain: KeychainStoring
    private let identityStore: CredentialIdentityStoreController?
    private var fetchedResultsController: NSFetchedResultsController<DDPassword>?
    private var storeObserver: NSObjectProtocol?

    private var context: NSManagedObjectContext {
        database.context
    }

    init(database: DataBase = .shared,
         keychain: KeychainStoring = Keychain.shared,
         identityStore: CredentialIdentityStoreController? = .shared) {
        self.database = database
        self.keychain = keychain
        self.identityStore = identityStore
        super.init()
    }

    deinit {
        if let storeObserver {
            NotificationCenter.default.removeObserver(storeObserver)
        }
    }

    /// Starts publishing `passwords`. Only list screens need this.
    func startObserving() {
        guard fetchedResultsController == nil else { return }
        let request = DDPassword.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true,
                                                    selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        fetchedResultsController = controller
        performFetch()
        storeObserver = NotificationCenter.default.addObserver(forName: .persistentStoresDidLoad, object: nil, queue: .main) { [weak self] _ in
            self?.performFetch()
        }
    }

    private func performFetch() {
        guard let fetchedResultsController else { return }
        do {
            try fetchedResultsController.performFetch()
            publish()
        } catch {
            database.logger.error("Fetching passwords failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func publish() {
        passwords.value = (fetchedResultsController?.fetchedObjects ?? []).compactMap { $0.convert() }
    }

    // MARK: - CRUD

    func fetch(with id: UUID) -> DDPassword? {
        let request = DDPassword.fetchRequest()
        request.predicate = DDPassword.predicate(for: id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    func value(for id: UUID) -> String {
        keychain.string(forKey: id.uuidString) ?? ""
    }

    /// Inserts or updates the record and its keychain value. Returns `false` if nothing was saved.
    @discardableResult
    func save(_ password: Password) -> Bool {
        let object: DDPassword
        if let existing = fetch(with: password.id) {
            object = existing
        } else {
            object = DDPassword(context: context)
            object.id = password.id
        }
        object.update(name: password.name, login: password.login, website: password.website)
        guard keychain.set(password.value, forKey: password.id.uuidString) else {
            context.rollback()
            return false
        }
        guard database.save() else {
            context.rollback()
            return false
        }
        identityStore?.refresh(context: context)
        return true
    }

    func delete(_ password: Password) {
        guard let object = fetch(with: password.id) else { return }
        context.delete(object)
        if database.save() {
            keychain.delete(password.id.uuidString)
            identityStore?.refresh(context: context)
        }
    }

    func count() -> Int {
        database.fetchCount(for: DDPassword.self)
    }
}

extension PasswordsStorage: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        publish()
    }
}
