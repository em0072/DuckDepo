//
//  SettingsViewModel.swift
//  DuckDepo
//

import AuthenticationServices
import Combine
import Foundation

/// Cheap to create: the counts load in `start()`, the system's state in `refreshSystemState()`.
@Observable
final class SettingsViewModel {

    private(set) var documentCount = 0
    private(set) var passwordCount = 0
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
    @ObservationIgnored private var storage: DocumentsStorage?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(database: DataBase = .shared, defaults: DefaultsController = .shared, reminders: ExpiryReminders = .shared) {
        self.database = database
        self.defaults = defaults
        self.reminders = reminders
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
        countPasswords()
    }

    private func update(with documents: [Document]) {
        documentCount = documents.count
        renewalCount = documents.filter { document in
            switch document.expiryStatus {
            case .expired, .expiresSoon: true
            case .valid, nil: false
            }
        }.count
    }

    private func countPasswords() {
        passwordCount = database.fetchCount(for: DDPassword.self)
    }

    // MARK: - Reminders

    func setRemindersEnabled(_ isOn: Bool) async {
        if isOn {
            let granted = await reminders.enable()
            await MainActor.run {
                areRemindersEnabled = granted
                areNotificationsBlocked = !granted
            }
        } else {
            reminders.disable()
            areRemindersEnabled = false
            areNotificationsBlocked = false
        }
    }

    // MARK: - System state

    /// AutoFill and notification permissions can change in Settings while the app is in the background.
    func refreshSystemState() async {
        let autoFill = await ASCredentialIdentityStore.shared.state().isEnabled
        let blocked = reminders.isEnabled ? !(await reminders.isAuthorized()) : false
        await MainActor.run {
            isAutoFillEnabled = autoFill
            areNotificationsBlocked = blocked
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
        countPasswords()
    }
}
