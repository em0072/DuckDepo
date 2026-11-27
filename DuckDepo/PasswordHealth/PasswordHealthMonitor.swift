//
//  PasswordHealthMonitor.swift
//  DuckDepo
//

import Combine
import Foundation
import SwiftUI

/// Keeps the password health report current for Settings, Passwords and each password's screen.
///
/// - Values are read from the keychain off the main thread and dropped once hashed and judged; the report
///   holds no values.
/// - One pass runs at a time. A refresh while one runs asks for another pass after it, so passes never
///   overlap and none is thrown away half done.
/// - With the leak check on, hashes not known from `LeakCheckCache` go to `LeakChecking`, five characters
///   of each. Each answer is kept as it arrives, so a failed or interrupted lookup loses nothing it found.
@Observable
final class PasswordHealthMonitor {

    enum LeakCheck: Equatable {
        case off
        case checking
        case checked
        /// The last lookup failed (offline, say): passwords not looked up yet may be missing from the report.
        case failed
    }

    static let shared = PasswordHealthMonitor()

    private(set) var report = PasswordHealth.empty
    private(set) var leakCheck = LeakCheck.off
    /// The passwords have been read at least once since `start()`. Until then the report is empty, which
    /// mustn't read as "no issues".
    private(set) var isLoaded = false
    /// Every password, without values: what a screen opened from the report shows, even once the password
    /// has left the report.
    private(set) var passwords: [Password] = []

    var checksLeakedPasswords: Bool {
        didSet {
            guard checksLeakedPasswords != oldValue else { return }
            defaults.checksLeakedPasswords = checksLeakedPasswords
            if !checksLeakedPasswords {
                stopLeakCheck()
                leakCache.removeAll()
            }
            refresh(immediately: true)
        }
    }

    var showsInPasswords: Bool {
        didSet { defaults.showsPasswordHealthInPasswords = showsInPasswords }
    }

    @ObservationIgnored private let makeStorage: () -> PasswordsStorage
    @ObservationIgnored private let keychain: KeychainStoring
    @ObservationIgnored private let leakChecker: LeakChecking
    @ObservationIgnored private let leakCache: LeakCheckCache
    @ObservationIgnored private let defaults: DefaultsController
    @ObservationIgnored private var storage: PasswordsStorage?
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    /// A refresh waiting out its delay.
    @ObservationIgnored private var scheduled: Task<Void, Never>?
    /// The passes running now, one after another.
    @ObservationIgnored private var passes: Task<Void, Never>?
    @ObservationIgnored private var needsPass = false
    @ObservationIgnored private var leakLookup: Task<Void, Error>?
    /// Changes when the leak check is turned off or everything is deleted: a lookup started before then
    /// records nothing after.
    @ObservationIgnored private var leakGeneration = 0

    init(makeStorage: @escaping () -> PasswordsStorage = { PasswordsStorage() },
         keychain: KeychainStoring = Keychain.shared,
         leakChecker: LeakChecking = PwnedPasswords(),
         leakCache: LeakCheckCache = .shared,
         defaults: DefaultsController = .shared) {
        self.makeStorage = makeStorage
        self.keychain = keychain
        self.leakChecker = leakChecker
        self.leakCache = leakCache
        self.defaults = defaults
        checksLeakedPasswords = defaults.checksLeakedPasswords
        showsInPasswords = defaults.showsPasswordHealthInPasswords
    }

    /// Starts watching the passwords, or once started, looks again: a screen showing the report calls it
    /// when it appears, since values and hidden warnings changed on another device change only the keychain.
    func start() {
        guard storage == nil else {
            refresh()
            return
        }
        let storage = makeStorage()
        self.storage = storage
        storage.startObserving()
        storage.passwords
            .sink { [weak self] passwords in
                self?.passwords = passwords
                self?.refresh()
            }
            .store(in: &cancellables)
        // Only this keychain's: tests run several stores at once.
        NotificationCenter.default.publisher(for: PasswordsStorage.didChange, object: keychain)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    /// Works the report out again, a moment from now: changes come in bursts while syncing. Also call it
    /// when coming back to the app.
    func refresh(immediately: Bool = false) {
        guard storage != nil else { return }
        scheduled?.cancel()
        scheduled = Task { @MainActor [weak self] in
            if !immediately {
                try? await Task.sleep(for: .milliseconds(250))
            }
            guard !Task.isCancelled else { return }
            self?.requestPass()
        }
    }

    /// Waits for the refreshes asked for so far, and the passes they start, to finish (tests).
    func waitForRefresh() async {
        await scheduled?.value
        await passes?.value
    }

    func issues(for id: Password.ID) -> [PasswordHealth.Issue] {
        report.item(for: id)?.issues ?? []
    }

    func password(with id: Password.ID) -> Password? {
        passwords.first { $0.id == id }
    }

    /// Hides the warnings the password has now, for its current value, or shows them again. Moves it in the
    /// report at once; the next pass confirms it.
    @MainActor
    func setWarningsHidden(_ isHidden: Bool, for id: Password.ID) {
        start()
        guard let storage else { return }
        if isHidden {
            guard let item = report.item(for: id),
                  storage.hideWarnings(Set(item.issues.map(\.kind)), for: id) else { return }
        } else {
            storage.showWarnings(for: id)
        }
        setReport(report.settingHidden(isHidden, for: id))
        refresh(immediately: true)
    }

    /// After Delete All Data.
    func reset() {
        stopLeakCheck()
        leakCache.removeAll()
        refresh(immediately: true)
    }

    private func stopLeakCheck() {
        leakGeneration += 1
        leakLookup?.cancel()
        leakLookup = nil
    }

    // MARK: - Passes

    @MainActor
    private func requestPass() {
        needsPass = true
        guard passes == nil else { return }
        passes = Task { @MainActor [weak self] in
            while let self, self.needsPass {
                self.needsPass = false
                await self.pass()
            }
            self?.passes = nil
        }
    }

    @MainActor
    private func pass() async {
        let passwords = self.passwords
        let keychain = self.keychain
        let (entries, hidden) = await Task.detached(priority: .utility) {
            let entries = passwords.compactMap { password -> PasswordHealth.Entry? in
                guard let value = keychain.string(forKey: password.id.uuidString), !value.isEmpty else { return nil }
                return PasswordHealth.Entry(password: password, value: value)
            }
            return (entries, PasswordsStorage.hiddenWarnings(among: passwords.map(\.id), keychain: keychain))
        }.value

        let hashes = Set(entries.map(\.hash))
        guard checksLeakedPasswords else {
            setReport(.evaluate(entries, hidden: hidden))
            setLeakCheck(.off)
            return
        }
        let known = hashes.reduce(into: [String: Bool]()) { $0[$1] = leakCache.isLeaked($1) }
        setReport(.evaluate(entries, leaked: Set(known.filter(\.value).keys), hidden: hidden))
        let unknown = hashes.subtracting(known.keys)
        guard !unknown.isEmpty else {
            leakCache.save(keeping: hashes)
            setLeakCheck(.checked)
            return
        }

        setLeakCheck(.checking)
        let generation = leakGeneration
        let lookup = Task { @MainActor [leakChecker, leakCache] in
            try await leakChecker.lookUp(unknown) { checked, leaked in
                // Turned off or deleted meanwhile: keep nothing.
                guard generation == self.leakGeneration else { return }
                leakCache.store(checked: checked, leaked: leaked)
            }
        }
        leakLookup = lookup
        let result = await lookup.result
        guard generation == leakGeneration, checksLeakedPasswords else { return }
        leakLookup = nil
        leakCache.save(keeping: hashes)
        // What's known now, whether or not every lookup succeeded.
        setReport(.evaluate(entries, leaked: hashes.filter { leakCache.isLeaked($0) == true }, hidden: hidden))
        switch result {
        case .success: setLeakCheck(.checked)
        case .failure: setLeakCheck(.failed)
        }
    }

    @MainActor
    private func setReport(_ newReport: PasswordHealth) {
        guard newReport != report || !isLoaded else { return }
        withAnimation {
            report = newReport
            isLoaded = true
        }
    }

    @MainActor
    private func setLeakCheck(_ state: LeakCheck) {
        guard state != leakCheck else { return }
        withAnimation {
            leakCheck = state
        }
    }
}
