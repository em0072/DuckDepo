//
//  CredentialTransfer.swift
//  DuckDepo
//

import AuthenticationServices
import os
import UIKit

/// Reads everything for an export and saves what an import brings. Core Data is used on the main
/// thread; keychain reads and writes, which add up for a large vault, run off it.
@MainActor
struct CredentialTransfer {

    var database: DataBase = .shared
    var keychain: KeychainStoring = Keychain.shared
    var identityStore: CredentialIdentityStoreController? = .shared

    /// Passwords saved per batch: stopping midway leaves at most one batch's secrets without records.
    static let batchSize = 100

    private var passwords: PasswordsStorage {
        PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
    }

    private var passkeys: PasskeyStorage {
        PasskeyStorage(keychain: keychain)
    }

    // MARK: - Export

    /// Everything DuckDepo holds, photos aside, and how many items that is.
    func exportedData(formatVersion: ASExportedCredentialData.FormatVersion) async -> (data: ASExportedCredentialData, count: Int) {
        let records = passwords.allRecords()
        let documents = database.allDocuments()
        let keychain = keychain
        return await Task.detached {
            let data = CredentialExchange.exportedData(passwords: PasswordsStorage.withSecrets(records, keychain: keychain),
                                                       passkeys: PasskeyStorage(keychain: keychain).allWithKeys(),
                                                       documents: documents, formatVersion: formatVersion)
            return (data, data.accounts.reduce(0) { $0 + $1.items.count })
        }.value
    }

    // MARK: - Import

    func plan(for incoming: CredentialImport) -> ImportPlan {
        let keychain = keychain
        return ImportPlan(incoming, savedPasswords: passwords.allRecords(),
                          savedSecrets: { id in
                              (keychain.string(forKey: id.uuidString),
                               keychain.string(forKey: PasswordsStorage.oneTimeCodeKey(for: id)) ?? "")
                          },
                          savedPasskeyIDs: Set(passkeys.all().map(\.credentialID)),
                          savedDocuments: incoming.documents.isEmpty ? [] : database.allDocuments())
    }

    struct Result {
        let count: Int
        /// False when some items couldn't be saved. Importing again adds only those.
        let isComplete: Bool
    }

    func perform(_ plan: ImportPlan, progress: (Double) -> Void = { _ in }) async -> Result {
        let storage = passwords
        let keychain = keychain
        let total = Double(max(1, plan.codesForSaved.count + plan.passwords.count + plan.passkeys.count + plan.documents.count))
        var done = 0
        var count = 0
        var isComplete = true
        func advance(_ items: Int) {
            done += items
            progress(Double(done) / total)
        }

        let codes = await Task.detached { PasswordsStorage.addCodes(plan.codesForSaved, keychain: keychain) }.value
        count += codes.written
        isComplete = isComplete && codes.failed == 0
        advance(plan.codesForSaved.count)

        for batch in plan.passwords.batches(of: Self.batchSize) {
            let stored = storage.storedIDs(among: batch.map(\.id))
            let new = batch.filter { !stored.contains($0.id) }
            let written = await Task.detached { PasswordsStorage.writeSecrets(of: new, keychain: keychain) }.value
            if storage.insertRecords(for: written) {
                count += written.count
                isComplete = isComplete && written.count == new.count
            } else {
                isComplete = false
            }
            advance(batch.count)
        }

        let addedPasskeys = passkeys.add(plan.passkeys)
        count += addedPasskeys.added
        isComplete = isComplete && addedPasskeys.failed == 0
        advance(plan.passkeys.count)

        for batch in plan.documents.batches(of: Self.batchSize) {
            if let added = database.add(batch) {
                count += added
            } else {
                isComplete = false
            }
            advance(batch.count)
        }

        identityStore?.refresh(context: database.context, keychain: keychain)
        return Result(count: count, isComplete: isComplete)
    }
}

private extension Array {
    func batches(of size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}

private let logger = Logger(subsystem: "DuckDepo", category: "Transfer")

/// Receives what another password manager sends (the system opens the app with a user activity) and
/// asks before saving it. The sheet shows under the lock screen, so the app must be unlocked first.
@MainActor
@Observable
final class CredentialImporter {

    /// Shown as a sheet until imported or dismissed.
    var plan: ImportPlan?
    private(set) var isImporting = false
    private(set) var progress = 0.0
    var failure: String?
    var isShowingDone = false
    private(set) var doneMessage = ""

    /// The newest import; an older one that finishes reading later is dropped.
    @ObservationIgnored private var latestToken: UUID?
    /// A newer import that arrived while one was being saved.
    @ObservationIgnored private var nextPlan: ImportPlan?

    private enum ImportError: LocalizedError {
        case storeUnavailable

        var errorDescription: String? {
            "import_store_unavailable".localized()
        }
    }

    func receive(_ activity: NSUserActivity) {
        let value = activity.userInfo?[ASCredentialImportToken]
        guard let token = (value as? UUID) ?? (value as? String).flatMap(UUID.init(uuidString:)) else {
            logger.error("The import activity had no token")
            return
        }
        latestToken = token
        Task {
            await receive(token: token)
        }
    }

    private func receive(token: UUID) async {
        do {
            let data = try await ASCredentialImportManager().importCredentials(token: token)
            let incoming = CredentialImport(data)
            try await Self.waitForStore()
            guard latestToken == token else { return }
            let plan = CredentialTransfer().plan(for: incoming)
            if isImporting {
                nextPlan = plan
            } else {
                self.plan = plan
            }
        } catch {
            guard latestToken == token else { return }
            logger.error("Receiving an import failed: \(String(describing: error), privacy: .public)")
            failure = error.localizedDescription
        }
    }

    /// Opened by the import, the app may still be loading its store (it waits for the device to unlock).
    private static func waitForStore() async throws {
        let persistence = PersistenceController.shared
        let deadline = ContinuousClock.now + .seconds(60)
        while !persistence.isLoaded {
            guard persistence.loadError == nil, ContinuousClock.now < deadline else { throw ImportError.storeUnavailable }
            try await Task.sleep(for: .milliseconds(200))
        }
    }

    /// Saves the plan on screen, once: further taps while it saves do nothing.
    func perform(_ plan: ImportPlan) {
        guard !isImporting, self.plan?.id == plan.id else { return }
        isImporting = true
        progress = 0
        Task {
            let result = await CredentialTransfer().perform(plan) { [weak self] value in
                self?.progress = value
            }
            isImporting = false
            self.plan = nil
            if result.isComplete {
                doneMessage = String(format: "import_done %lld".localized(), result.count)
                isShowingDone = true
            } else {
                failure = "import_incomplete".localized()
            }
            if let nextPlan {
                self.nextPlan = nil
                self.plan = nextPlan
            }
        }
    }
}

/// Sends everything to another password manager the user picks in the system's sheet.
@MainActor
@Observable
final class CredentialExporter {

    private(set) var isExporting = false
    var failure: String?
    var isShowingDone = false
    private(set) var doneMessage = ""

    func export() async {
        guard !isExporting, let window = UIApplication.shared.foregroundKeyWindow else { return }
        isExporting = true
        defer { isExporting = false }
        // Every secret is read below, so check it's the device's owner, even with the app lock off. Before
        // the system's sheet: a prompt asked while that sheet is up shows behind it.
        switch await UserVerification.verify(reason: "export_verify_reason".localized()) {
        case .verified:
            break
        case .unavailable:
            // Without a passcode nothing can confirm it's the owner, and passkeys' keys would leave too.
            failure = "export_needs_passcode".localized()
            return
        case .failed:
            return
        }
        do {
            let manager = ASCredentialExportManager(presentationAnchor: window)
            // The system explains what an export means and lets the user pick the app.
            let options = try await manager.requestExport(for: nil)
            let export = await CredentialTransfer().exportedData(formatVersion: options.formatVersion)
            try await manager.exportCredentials(export.data)
            doneMessage = String(format: "export_done %lld".localized(), export.count)
            isShowingDone = true
        } catch {
            guard !Self.isCancellation(error) else { return }
            logger.error("Exporting failed: \(String(describing: error), privacy: .public)")
            failure = error.localizedDescription
        }
    }

    private static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let error = error as? ASAuthorizationError, error.code == .canceled { return true }
        return false
    }
}

extension UIApplication {
    /// The window to present system sheets from.
    var foregroundKeyWindow: UIWindow? {
        connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow
    }
}
