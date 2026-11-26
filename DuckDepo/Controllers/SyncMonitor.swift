//
//  SyncMonitor.swift
//  DuckDepo
//

import CloudKit
import CoreData
import Foundation
import Observation

/// Reports iCloud account status and the outcome of CloudKit sync, for display in Settings.
@Observable
final class SyncMonitor {

    enum AccountStatus: Equatable {
        case checking
        case available
        case noAccount
        case restricted
        case temporarilyUnavailable
        case unknown
    }

    static let shared = SyncMonitor()

    private(set) var accountStatus: AccountStatus = .checking
    private var hasRunningEvents = false
    private var hasDownloadEvents = false
    private var isActivityVisible = false

    // Without an iCloud account, CloudKit's setup starts and then waits for one indefinitely, so its
    // events only count while an account is available.

    var isSyncing: Bool {
        accountStatus == .available && hasRunningEvents
    }

    /// True while CloudKit is setting up or downloading changes.
    var isDownloading: Bool {
        accountStatus == .available && hasDownloadEvents
    }

    /// `isSyncing`, but only once a sync has lasted long enough to be worth showing. The export after
    /// each edit and the routine check on every launch finish well under a second and would just flicker.
    var showsActivity: Bool {
        accountStatus == .available && isActivityVisible
    }
    private(set) var lastSyncDate: Date?
    private(set) var lastErrorDescription: String?

    @ObservationIgnored private let container: CKContainer
    @ObservationIgnored private var runningEvents: [UUID: NSPersistentCloudKitContainer.EventType] = [:]
    @ObservationIgnored private var activityUpdate: DispatchWorkItem?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    init(containerIdentifier: String = PersistenceController.cloudKitContainerIdentifier) {
        container = CKContainer(identifier: containerIdentifier)
        observers.append(NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else { return }
            self?.handle(event)
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: .CKAccountChanged, object: nil, queue: .main
        ) { [weak self] _ in
            self?.refreshAccountStatus()
        })
        refreshAccountStatus()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func refreshAccountStatus() {
        container.accountStatus { [weak self] status, _ in
            DispatchQueue.main.async {
                self?.accountStatus = Self.map(status)
            }
        }
    }

    private func handle(_ event: NSPersistentCloudKitContainer.Event) {
        if event.endDate == nil {
            runningEvents[event.identifier] = event.type
        } else {
            runningEvents[event.identifier] = nil
            if event.succeeded {
                if event.type != .setup {
                    lastSyncDate = event.endDate
                }
                lastErrorDescription = nil
            } else if let error = event.error {
                lastErrorDescription = Self.describe(error)
            }
        }
        hasRunningEvents = !runningEvents.isEmpty
        hasDownloadEvents = runningEvents.values.contains { $0 == .setup || $0 == .import }
        scheduleActivityUpdate()
    }

    private func scheduleActivityUpdate() {
        activityUpdate?.cancel()
        activityUpdate = nil
        guard hasRunningEvents != isActivityVisible else { return }
        // Show after a sync has run for a second; hide after a short pause, so the gap between
        // two download batches doesn't make the indicator blink.
        let delay: TimeInterval = hasRunningEvents ? 1 : 0.6
        let update = DispatchWorkItem { [weak self] in
            guard let self else { return }
            isActivityVisible = hasRunningEvents
        }
        activityUpdate = update
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: update)
    }

    private static func map(_ status: CKAccountStatus) -> AccountStatus {
        switch status {
        case .available: return .available
        case .noAccount: return .noAccount
        case .restricted: return .restricted
        case .temporarilyUnavailable: return .temporarilyUnavailable
        case .couldNotDetermine: return .unknown
        @unknown default: return .unknown
        }
    }

    static func describe(_ error: Error) -> String {
        guard let ckError = error as? CKError else { return error.localizedDescription }
        switch ckError.code {
        case .quotaExceeded:
            return "icloud_error_quota".localized()
        case .notAuthenticated:
            return "icloud_error_not_signed_in".localized()
        case .networkUnavailable, .networkFailure:
            return "icloud_error_network".localized()
        default:
            return ckError.localizedDescription
        }
    }
}
