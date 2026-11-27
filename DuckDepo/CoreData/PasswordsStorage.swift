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

    /// The `otpauth://` link of the password's one-time codes, or empty.
    func oneTimeCode(for id: UUID) -> String {
        keychain.string(forKey: Self.oneTimeCodeKey(for: id)) ?? ""
    }

    /// Next to the password's own keychain item, so it syncs through iCloud Keychain the same way.
    static func oneTimeCodeKey(for id: UUID) -> String {
        id.uuidString + ".otp"
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
        guard keychain.set(password.value, forKey: password.id.uuidString), saveOneTimeCode(of: password) else {
            context.rollback()
            return false
        }
        guard database.save() else {
            context.rollback()
            return false
        }
        identityStore?.refresh(context: context, keychain: keychain)
        return true
    }

    // MARK: - Import and export
    //
    // An import writes secrets with the static functions below (keychain only, so they can run off the
    // main thread), then stores the records on the main thread.

    /// Adds many passwords at once with one AutoFill refresh. Passwords already stored (by ID) are left
    /// alone, and so is a password whose value can't be written. Returns how many were added, or nil if
    /// the save failed (then nothing was).
    func add(_ passwords: [Password]) -> Int? {
        let stored = storedIDs(among: passwords.map(\.id))
        let new = passwords.filter { !stored.contains($0.id) }
        let written = Self.writeSecrets(of: new, keychain: keychain)
        guard insertRecords(for: written) else { return nil }
        if !written.isEmpty {
            identityStore?.refresh(context: context, keychain: keychain)
        }
        return written.count
    }

    /// The IDs among these that are already stored.
    func storedIDs(among ids: [UUID]) -> Set<UUID> {
        guard !ids.isEmpty else { return [] }
        let request = DDPassword.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids)
        return Set(((try? context.fetch(request)) ?? []).compactMap(\.id))
    }

    /// Writes the values and codes of new passwords and returns the ones written; a password whose
    /// secrets can't all be written has none left behind.
    static func writeSecrets(of passwords: [Password], keychain: KeychainStoring) -> [Password] {
        passwords.filter { password in
            let codeKey = oneTimeCodeKey(for: password.id)
            let isWritten = keychain.set(password.value, forKey: password.id.uuidString)
                && (password.oneTimeCode.isEmpty || keychain.set(password.oneTimeCode, forKey: codeKey))
            if !isWritten {
                keychain.delete(password.id.uuidString)
                keychain.delete(codeKey)
            }
            return isWritten
        }
    }

    /// Stores the records of passwords whose secrets are written, in one save. If the save fails, nothing
    /// is stored and their secrets are removed.
    func insertRecords(for passwords: [Password]) -> Bool {
        guard !passwords.isEmpty else { return true }
        for password in passwords {
            let object = DDPassword(context: context)
            object.id = password.id
            object.update(name: password.name, login: password.login, website: password.website)
        }
        guard database.save() else {
            context.rollback()
            for password in passwords {
                keychain.delete(password.id.uuidString)
                keychain.delete(Self.oneTimeCodeKey(for: password.id))
            }
            return false
        }
        return true
    }

    /// Gives saved passwords codes they still don't have, checking again now (one may have arrived from
    /// another device meanwhile). Nothing here depends on Core Data, so nothing is undone later.
    static func addCodes(_ codes: [UUID: String], keychain: KeychainStoring) -> (written: Int, failed: Int) {
        var written = 0
        var failed = 0
        for (id, code) in codes {
            let key = oneTimeCodeKey(for: id)
            guard (keychain.string(forKey: key) ?? "").isEmpty else { continue }
            if keychain.set(code, forKey: key) {
                written += 1
            } else {
                failed += 1
            }
        }
        return (written, failed)
    }

    /// Every password, without values: what an export reads secrets for.
    func allRecords() -> [Password] {
        ((try? context.fetch(DDPassword.fetchRequest())) ?? []).compactMap { $0.convert() }
    }

    /// These passwords with their values and codes. Keychain only.
    static func withSecrets(_ passwords: [Password], keychain: KeychainStoring) -> [Password] {
        passwords.map { password in
            var password = password
            password.value = keychain.string(forKey: password.id.uuidString) ?? ""
            password.oneTimeCode = keychain.string(forKey: oneTimeCodeKey(for: password.id)) ?? ""
            return password
        }
    }

    func delete(_ password: Password) {
        guard let object = fetch(with: password.id) else { return }
        context.delete(object)
        if database.save() {
            keychain.delete(password.id.uuidString)
            keychain.delete(Self.oneTimeCodeKey(for: password.id))
            identityStore?.refresh(context: context, keychain: keychain)
        }
    }

    private func saveOneTimeCode(of password: Password) -> Bool {
        let key = Self.oneTimeCodeKey(for: password.id)
        if password.oneTimeCode.isEmpty {
            keychain.delete(key)
            return true
        }
        return keychain.set(password.oneTimeCode, forKey: key)
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
