//
//  SettingsViewModel.swift
//  DuckDepo
//

import AuthenticationServices
import Combine
import Foundation
import SwiftUI

/// Cheap to create: the counts load in `start()`, the system's state in `refreshSystemState()`.
@Observable
final class SettingsViewModel {

    private(set) var documentCount = 0
    /// Saved passwords and passkeys together: each is something you sign in with.
    var passwordCount: Int { savedPasswordCount + passkeyCount }
    private var savedPasswordCount = 0
    /// Passkeys live in the keychain, so they're recounted whenever the screen shows (AutoFill may have added one).
    private var passkeyCount = 0
    /// Documents that have expired or expire soon.
    private(set) var renewalCount = 0

    var clipboardLifetime: ClipboardLifetime {
        didSet { defaults.clipboardLifetime = clipboardLifetime.rawValue }
    }

    private(set) var areRemindersEnabled: Bool
    var reminderSchedule: ReminderSchedule {
        didSet { reminders.setSchedule(reminderSchedule) }
    }
    /// Reminders are on here but notifications are off in Settings.
    private(set) var areNotificationsBlocked = false

    /// Nil until known.
    private(set) var isAutoFillEnabled: Bool?

    @ObservationIgnored private let database: DataBase
    @ObservationIgnored private let defaults: DefaultsController
    @ObservationIgnored private let reminders: ExpiryReminders
    @ObservationIgnored private let passkeyStorage: PasskeyStorage
    @ObservationIgnored private var storage: DocumentsStorage?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(database: DataBase = .shared, defaults: DefaultsController = .shared, reminders: ExpiryReminders = .shared,
         passkeyStorage: PasskeyStorage = PasskeyStorage()) {
        self.database = database
        self.defaults = defaults
        self.reminders = reminders
        self.passkeyStorage = passkeyStorage
        clipboardLifetime = ClipboardLifetime(rawValue: defaults.clipboardLifetime) ?? .default
        areRemindersEnabled = reminders.isEnabled
        reminderSchedule = reminders.schedule
    }

    /// Starts counting documents and passwords. Safe to call more than once.
    func start() {
        guard storage == nil else { return }
        let storage = DocumentsStorage(database: database)
        self.storage = storage
        storage.documents
            .sink { [weak self] documents in
                self?.update(with: documents)
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: database.context)
            .sink { [weak self] _ in
                self?.countPasswords()
            }
            .store(in: &cancellables)
        passkeyStorage.changes
            .sink { [weak self] _ in
                self?.countPasskeys()
            }
            .store(in: &cancellables)
        countPasswords()
        countPasskeys()
        animatesChanges = true
    }

    /// Counts tick over when they change, but not when the screen first fills them in.
    @ObservationIgnored private var animatesChanges = false

    private func change(_ body: () -> Void) {
        if animatesChanges {
            withAnimation {
                body()
            }
        } else {
            body()
        }
    }

    private func countPasskeys() {
        let count = passkeyStorage.count()
        guard count != passkeyCount else { return }
        change { passkeyCount = count }
    }

    private func update(with documents: [Document]) {
        let renewal = documents.filter { document in
            switch document.expiryStatus {
            case .expired, .expiresSoon: true
            case .valid, nil: false
            }
        }.count
        guard documents.count != documentCount || renewal != renewalCount else { return }
        change {
            documentCount = documents.count
            renewalCount = renewal
        }
    }

    private func countPasswords() {
        let count = database.fetchCount(for: DDPassword.self)
        guard count != savedPasswordCount else { return }
        change { savedPasswordCount = count }
    }

    // MARK: - Reminders

    func setRemindersEnabled(_ isOn: Bool) async {
        if isOn {
            let granted = await reminders.enable()
            await MainActor.run {
                withAnimation {
                    areRemindersEnabled = granted
                    areNotificationsBlocked = !granted
                }
            }
        } else {
            reminders.disable()
            withAnimation {
                areRemindersEnabled = false
                areNotificationsBlocked = false
            }
        }
    }

    // MARK: - System state

    /// AutoFill and notification permissions can change in Settings while the app is in the background,
    /// and passkeys can be added through AutoFill or arrive from other devices.
    func refreshSystemState() async {
        let autoFill = await ASCredentialIdentityStore.shared.state().isEnabled
        let blocked = reminders.isEnabled ? !(await reminders.isAuthorized()) : false
        let passkeys = passkeyStorage.count()
        await MainActor.run {
            withAnimation {
                isAutoFillEnabled = autoFill
                areNotificationsBlocked = blocked
                passkeyCount = passkeys
            }
        }
    }

    func openAutoFillSettings() {
        Task {
            try? await ASSettingsHelper.openCredentialProviderAppSettings()
        }
    }

    // MARK: - About

    var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(version) (\(build))"
    }

    // MARK: - Reset

    func deleteEverything() {
        database.deleteEverything()
        PhotoTextIndex.shared.removeAll()
        PasswordHealthMonitor.shared.reset()
        countPasswords()
        countPasskeys()
    }
}
