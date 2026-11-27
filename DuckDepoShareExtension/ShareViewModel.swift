//
//  ShareViewModel.swift
//  DuckDepoShareExtension
//

import Foundation
import os
import UIKit

/// Turns what was shared into pages, then saves them as a new document (read and filled in like a scan)
/// or adds them to one the user picks. Writes go to the shared store; the app merges and syncs them.
@MainActor
@Observable
final class ShareViewModel {

    enum Stage {
        case loading
        /// The app hasn't moved its data to the shared container yet (first launch of this version).
        case appNotOpened
        case nothingToSave
        case choosing
        case reading
    }

    /// Fewer than the app takes: an extension has little memory.
    static let maximumPages = PageImport.maximumSharedPages

    private(set) var stage = Stage.loading
    private(set) var photos: [DocumentPhoto] = []
    /// Some pages were left out.
    private(set) var isTruncated = false

    /// The scan's editor, shown while set.
    var editor: EditDocumentViewModel?
    var isPicking = false
    private(set) var documents: [Document] = []
    var query = ""
    /// The pages are being added to a document: nothing else can be picked.
    private(set) var isSaving = false
    var failure: String?

    @ObservationIgnored private let providers: [NSItemProvider]
    @ObservationIgnored private let complete: () -> Void
    @ObservationIgnored let cancel: () -> Void
    @ObservationIgnored private var didSave = false
    @ObservationIgnored private var isFinished = false
    @ObservationIgnored private var isAuthenticating = false
    @ObservationIgnored private var backgroundedAt: Date?
    @ObservationIgnored private let logger = Logger(subsystem: "DuckDepo", category: "Share")

    init(providers: [NSItemProvider], complete: @escaping () -> Void, cancel: @escaping () -> Void) {
        self.providers = providers
        self.complete = complete
        self.cancel = cancel
    }

    func start() async {
        guard stage == .loading else { return }
        guard DefaultsController.shared.isSharedStoreReady else {
            stage = .appNotOpened
            return
        }
        // Ready by the time the user picks "New Document".
        ModelExtractor.prewarm()
        let result = await PageImport.photos(from: providers, limit: Self.maximumPages)
        photos = result.photos
        isTruncated = result.isTruncated
        stage = photos.isEmpty ? .nothingToSave : .choosing
    }

    // MARK: - New document

    /// Reads the pages and opens the editor with what it found, as after a scan.
    func newDocument() async {
        guard stage == .choosing, isStoreAvailable() else { return }
        stage = .reading
        let draft = await DocumentScanner.draft(from: photos)
        stage = .choosing
        editor = EditDocumentViewModel(type: .scanned(draft)) { [weak self] saved in
            if saved != nil {
                self?.didSave = true
            }
        }
    }

    /// The editor was closed: saved, the share is done; discarded, the user can choose again.
    func editorDismissed() {
        editor = nil
        if didSave {
            finish()
        }
    }

    // MARK: - Existing document

    /// Lists the documents, after Face ID when the app is locked: the list shows their names.
    func chooseExisting() async {
        guard stage == .choosing, isStoreAvailable() else { return }
        let lock = BiometricController.shared
        if lock.isLockRequired {
            isAuthenticating = true
            let unlocked = await withCheckedContinuation { continuation in
                lock.authenticate { continuation.resume(returning: $0) }
            }
            isAuthenticating = false
            guard unlocked else { return }
        }
        // Changes the app made since the extension started.
        DataBase.shared.readLatestStoredData()
        documents = DataBase.shared.allDocuments().sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        isPicking = true
    }

    var filteredDocuments: [Document] {
        documents.filter { DocumentSearch.matches($0, query: query) }
    }

    func add(to document: Document) {
        // A second tap while the share closes would add the pages again, or to another document.
        guard !isSaving, !isFinished else { return }
        isSaving = true
        switch DataBase.shared.addPhotos(photos, toDocumentWith: document.id) {
        case .saved:
            finish()
        case .tooLarge:
            isSaving = false
            failure = "share_document_too_large".localized()
        case .failed:
            isSaving = false
            failure = "share_save_failed".localized()
        }
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        complete()
    }

    // MARK: - Host app

    /// The documents list is covered while the app it was shared from isn't active (its app-switcher
    /// snapshot), when the lock is on, as the app covers its own.
    var shouldCoverContent: Bool {
        isPicking && BiometricController.shared.isLockRequired && !isAuthenticating
    }

    /// The documents list closes once the app it was shared from has been in the background for the
    /// lock's "ask after" time: opening it again asks for Face ID.
    func hostDidEnterBackground() {
        let lock = BiometricController.shared
        guard isPicking, lock.isLockRequired else { return }
        if lock.biometricDelay == .none {
            closeDocuments()
        } else if backgroundedAt == nil {
            backgroundedAt = .now
        }
    }

    func hostDidBecomeActive() {
        defer { backgroundedAt = nil }
        if let backgroundedAt, Date.now.timeIntervalSince(backgroundedAt) >= BiometricController.shared.biometricDelay.seconds {
            closeDocuments()
        }
    }

    private func closeDocuments() {
        isPicking = false
        documents = []
        query = ""
    }

    private func isStoreAvailable() -> Bool {
        let persistence = PersistenceController.shared
        guard persistence.isLoaded else {
            logger.error("The store isn't loaded: \(String(describing: persistence.loadError), privacy: .public)")
            failure = "share_store_unavailable".localized()
            return false
        }
        return true
    }
}
