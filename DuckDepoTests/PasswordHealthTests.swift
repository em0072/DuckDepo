//
//  PasswordHealthTests.swift
//  DuckDepoTests
//

import Foundation
import Testing
@testable import DuckDepo

struct PasswordStrengthTests {

    @Test(arguments: ["password", "123456", "P@ssw0rd123!", "Qwerty1", "Dragon2020", "iloveyou", "пароль", "gfhjkm",
                      "Summer2024!", "1q2w3e4r", "Jessica1988",
                      // A list entry with its own digits plus a character; "1" for "l".
                      "1q2w3e4r!", "Trustno1!", "1qazxsw2!", "Footba11", "We1come1", "He11o2024"])
    func commonPasswordsAreCommon(_ password: String) {
        #expect(PasswordStrength.weakness(of: password) == .common)
    }

    @Test(arguments: ["x7#K", "Zk3$pQ", "v9!Lr2m", "我的密码"])
    func shortPasswordsAreShort(_ password: String) {
        #expect(PasswordStrength.weakness(of: password) == .short)
    }

    @Test(arguments: ["mypassword99", "aaaaaaaaaaaa", "summer2024dragon", "abcdefgh1234", "98765432", "qwertyasdfgh",
                      // Shifted digits, keyboard walks, repeated chunks, a list word with many digits.
                      "!@#$%^&*()", "1q2w3e4r5t6y", "1qaz2wsx3edc", "zaq1zaq1", "abababab", "blahblahblah",
                      "1a1a1a1a1a", "password12345678"])
    func patternsAreEasyToGuess(_ password: String) {
        #expect(PasswordStrength.weakness(of: password) == .predictable)
    }

    @Test(arguments: ["correct horse battery staple", "kfjdqpwzm", "Tr0ub4dor&3", "jA9$kL2#", "Ящерица-Ромашка-71",
                      // Scripts without capitals.
                      "שלוםעולםשלוםעולםשלום", "كلمةالمرورطويلةجدا", "我的密码非常安全而且很长很长很长", "わたしのひみつのあいことばです",
                      "비밀번호는아주길고안전합니다",
                      // One list word lost among many random characters isn't "commonly used".
                      "4829175036love9183746502", "93@1!7#test#2*8&4"])
    func goodPasswordsAreFine(_ password: String) {
        #expect(PasswordStrength.weakness(of: password) == nil)
    }

    @Test func generatedPasswordsAreFine() {
        var generator = SeededGenerator(seed: 7)
        for length in [12, 16] {
            for _ in 0..<500 {
                let password = PasswordGenerator.sharedInstance.generatePassword(includeNumbers: true, includeCapitals: true,
                                                                                 includeSymbols: true, length: length, using: &generator)
                #expect(PasswordStrength.weakness(of: password) == nil, "\(password)")
            }
        }
    }

    @Test func onlyTheStartOfAVeryLongPasswordIsJudged() {
        #expect(PasswordStrength.weakness(of: String(repeating: "a", count: 5000)) == .predictable)
        var generator = SeededGenerator(seed: 3)
        let long = PasswordGenerator.sharedInstance.generatePassword(includeNumbers: true, includeCapitals: true,
                                                                     includeSymbols: true, length: 5000, using: &generator)
        #expect(PasswordStrength.weakness(of: long) == nil)
    }

    @Test func anEmptyPasswordIsNotJudged() {
        #expect(PasswordStrength.weakness(of: "") == nil)
    }
}

struct PasswordHealthReportTests {

    private func entry(_ name: String, _ value: String) -> PasswordHealth.Entry {
        PasswordHealth.Entry(password: Password(name: name, value: value, oneTimeCode: "otpauth://totp/x?secret=ABC"), value: value)
    }

    private func hidden(_ value: String, _ issues: Set<String>) -> PasswordsStorage.HiddenWarnings {
        PasswordsStorage.HiddenWarnings(valueHash: PwnedPasswords.hash(of: value), issues: issues)
    }

    @Test func eachPasswordIsListedUnderItsWorstIssue() {
        let shared = "Same-Pass-91!xQ"
        let entries = [entry("Mail", shared), entry("Bank", shared), entry("Forum", "password"), entry("Shop", "kfjdqpwzm#R7"),
                       entry("Wiki", "x7#K"), entry("Blog", "x7#K")]
        let report = PasswordHealth.evaluate(entries, leaked: [PwnedPasswords.hash(of: "password")])

        #expect(report.leaked.map(\.password.name) == ["Forum"])
        #expect(report.leaked.first?.issues == [.leaked, .weak(.common)])
        // Passwords that share a value are together, each group in name order.
        let groups = report.reused.map(\.reuseGroup)
        #expect(Set(report.reused.prefix(2).map(\.reuseGroup)).count == 1)
        #expect(Set(report.reused.suffix(2).map(\.reuseGroup)).count == 1)
        #expect(groups.first != groups.last)
        #expect(report.reused.map(\.password.name).sorted() == ["Bank", "Blog", "Mail", "Wiki"])
        #expect(report.reused.first { $0.password.name == "Bank" }?.issues == [.reused(accounts: 2)])
        #expect(report.weak.isEmpty)
        #expect(report.toFixCount == 5)
        #expect(report.item(for: entries[3].password.id) == nil)
    }

    @Test func aHiddenWarningStaysHiddenOnlyForItsValueAndIssues() {
        let shared = "Same-Pass-91!xQ"
        let entries = [entry("Bank", shared), entry("Mail", shared)]
        let mail = entries[1].password.id

        let hiddenReport = PasswordHealth.evaluate(entries, hidden: [mail: hidden(shared, ["reused"])])
        #expect(hiddenReport.items.map(\.password.name) == ["Bank"])
        // Still counted for the other account's reuse.
        #expect(hiddenReport.items.first?.issues == [.reused(accounts: 2)])
        #expect(hiddenReport.hiddenItems.map(\.password.name) == ["Mail"])
        #expect(hiddenReport.toFixCount == 1)

        // A leak found later shows it again.
        let leaked = PasswordHealth.evaluate(entries, leaked: [PwnedPasswords.hash(of: shared)], hidden: [mail: hidden(shared, ["reused"])])
        #expect(!leaked.isHidden(mail))
        #expect(leaked.toFixCount == 2)

        // So does a value changed anywhere else (the marker is for the old one).
        let changed = PasswordHealth.evaluate(entries, hidden: [mail: hidden("old value", ["reused"])])
        #expect(!changed.isHidden(mail))
    }

    @Test func hidingMovesAPasswordAtOnce() {
        let entries = [entry("Mail", "x7#K"), entry("Bank", "x7#K")]
        let report = PasswordHealth.evaluate(entries)
        let hidden = report.settingHidden(true, for: entries[0].password.id)
        #expect(hidden.items.map(\.password.name) == ["Bank"])
        #expect(hidden.hiddenItems.map(\.password.name) == ["Mail"])
        #expect(hidden.settingHidden(false, for: entries[0].password.id) == report)
    }

    @Test func theReportHoldsNoSecrets() {
        let item = entry("Bank", "password")
        #expect(item.password.value.isEmpty)
        #expect(item.password.oneTimeCode.isEmpty)
        #expect(item.hash == PwnedPasswords.hash(of: "password"))
    }
}

/// Answers from a fixed list of leaked hashes, and counts what it was asked. Prefixes in `failing` fail,
/// a moment after the others answer.
private final class StubLeakChecker: LeakChecking, @unchecked Sendable {
    var leaked: Set<String> = []
    var fails = false
    var failing: Set<String> = []
    private(set) var prefixes: [String] = []
    private let lock = NSLock()

    func leakedSuffixes(forPrefix prefix: String) async throws -> Set<String> {
        lock.withLock { prefixes.append(prefix) }
        if fails {
            throw URLError(.notConnectedToInternet)
        }
        if failing.contains(prefix) {
            try await Task.sleep(for: .milliseconds(100))
            throw URLError(.timedOut)
        }
        return Set(leaked.filter { $0.hasPrefix(prefix) }.map { String($0.dropFirst(5)) })
    }

    func reset() {
        lock.withLock { prefixes = [] }
    }
}

struct PwnedPasswordsTests {

    @Test func hashesAreUppercaseSHA1() {
        #expect(PwnedPasswords.hash(of: "password") == "5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8")
        #expect(PasswordsStorage.valueHash(of: "password") == PwnedPasswords.hash(of: "password"))
    }

    @Test func paddingEntriesAreNotLeaks() throws {
        let body = "1E4C9B93F3F0682250B6CF8331B7EE68FD8:9659365\r\n0018a45c4d1def81644b54ab7f969b88d65:0\r\n\r\n"
        #expect(try PwnedPasswords.leakedSuffixes(in: body) == ["1E4C9B93F3F0682250B6CF8331B7EE68FD8"])
    }

    @Test(arguments: ["", "\r\n", "<html><body>Blocked by your network</body></html>", "abc:12",
                      "1E4C9B93F3F0682250B6CF8331B7EE68FD8:many"])
    func anythingButAHashListIsAFailure(_ body: String) {
        #expect(throws: URLError.self) {
            try PwnedPasswords.leakedSuffixes(in: body)
        }
    }

    @Test func theRequestCarriesOnlyThePrefix() throws {
        let request = try PwnedPasswords.request(forPrefix: "5BAA6")
        #expect(request.url?.absoluteString == "https://api.pwnedpasswords.com/range/5BAA6")
        #expect(request.httpBody == nil)
        #expect(request.value(forHTTPHeaderField: "Add-Padding") == "true")
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "DuckDepo")
        // The same for every user: not the device's language.
        #expect(request.value(forHTTPHeaderField: "Accept-Language") == "en")
        #expect(throws: URLError.self) { try PwnedPasswords.request(forPrefix: "5BAA61E4") }
        #expect(throws: URLError.self) { try PwnedPasswords.request(forPrefix: "5BAA/") }
    }

    @Test func eachPrefixIsAskedOnce() async throws {
        let checker = StubLeakChecker()
        let leaked = PwnedPasswords.hash(of: "password")
        checker.leaked = [leaked]
        let hashes: Set<String> = [leaked, "5BAA6" + String(repeating: "0", count: 35), PwnedPasswords.hash(of: "kfjdqpwzm#R7")]
        #expect(try await checker.leakedHashes(among: hashes) == [leaked])
        #expect(checker.prefixes.count == 2)
        #expect(checker.prefixes.allSatisfy { $0.count == 5 })
    }

    @Test func answersArriveBeforeAFailureEndsTheLookup() async {
        let checker = StubLeakChecker()
        let slow = PwnedPasswords.hash(of: "password")
        let quick = PwnedPasswords.hash(of: "kfjdqpwzm#R7")
        checker.leaked = [quick]
        checker.failing = [String(slow.prefix(5))]
        var answered = Set<String>()
        var leaked = Set<String>()
        await #expect(throws: URLError.self) {
            try await checker.lookUp([slow, quick]) { checked, found in
                answered.formUnion(checked)
                leaked.formUnion(found)
            }
        }
        #expect(answered == [quick])
        #expect(leaked == [quick])
    }
}

struct LeakCheckCacheTests {

    private let leaked = PwnedPasswords.hash(of: "password")
    private let safe = PwnedPasswords.hash(of: "kfjdqpwzm#R7")

    @Test func aLeakIsKeptAndSafeIsLookedUpAgainAfterAWeek() {
        let cache = LeakCheckCache(fileURL: nil, keychain: InMemoryKeychain())
        let now = Date()
        cache.store(checked: [leaked, safe], leaked: [leaked], now: now)
        #expect(cache.isLeaked(leaked, now: now) == true)
        #expect(cache.isLeaked(safe, now: now) == false)
        #expect(cache.isLeaked(PwnedPasswords.hash(of: "other"), now: now) == nil)

        let later = now.addingTimeInterval(LeakCheckCache.maximumAge + 1)
        #expect(cache.isLeaked(leaked, now: later) == true)
        #expect(cache.isLeaked(safe, now: later) == nil)
        // A result dated after now (the clock was set ahead) is looked up again.
        #expect(cache.isLeaked(safe, now: now.addingTimeInterval(-60)) == nil)
    }

    @Test func theFileHoldsNoHashesAndForgetsWhatsGone() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let url = folder.appendingPathComponent("leaks.json")
        defer { try? FileManager.default.removeItem(at: folder) }
        let keychain = InMemoryKeychain()
        let now = Date()
        let cache = LeakCheckCache(fileURL: url, keychain: keychain)
        cache.store(checked: [leaked, safe], leaked: [leaked], now: now)
        cache.save(keeping: [leaked, safe], now: now)

        let file = try String(contentsOf: url, encoding: .utf8)
        #expect(!file.contains(leaked.prefix(5)))
        #expect(!file.contains(safe.prefix(5)))
        let reopened = LeakCheckCache(fileURL: url, keychain: keychain)
        #expect(reopened.isLeaked(leaked, now: now) == true)
        // Without the key, the file is no use.
        #expect(LeakCheckCache(fileURL: url, keychain: InMemoryKeychain()).isLeaked(leaked, now: now) == nil)

        // A password that's gone (or has a new value) is forgotten.
        reopened.save(keeping: [safe], now: now)
        #expect(LeakCheckCache(fileURL: url, keychain: keychain).isLeaked(leaked, now: now) == nil)

        reopened.removeAll()
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(keychain.items.isEmpty)
        #expect(reopened.isLeaked(safe, now: now) == nil)
    }
}

@MainActor
@Suite(.serialized)
struct PasswordHealthMonitorTests {

    private let database = TestStack.makeDatabase()
    private let keychain = InMemoryKeychain()
    private let checker = StubLeakChecker()
    private let cache = LeakCheckCache(fileURL: nil, keychain: InMemoryKeychain())

    /// Without waiting for the delay.
    private func refreshNow(_ monitor: PasswordHealthMonitor) async {
        monitor.refresh(immediately: true)
        await monitor.waitForRefresh()
    }

    private func makeStorage() -> PasswordsStorage {
        PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
    }

    private func makeMonitor(checksLeaks: Bool) -> PasswordHealthMonitor {
        let defaults = DefaultsController(defaults: TestStack.makeDefaults(), legacyDefaults: nil)
        defaults.checksLeakedPasswords = checksLeaks
        let keychain = keychain
        let database = database
        return PasswordHealthMonitor(makeStorage: { PasswordsStorage(database: database, keychain: keychain, identityStore: nil) },
                                     keychain: keychain, leakChecker: checker, leakCache: cache, defaults: defaults)
    }

    @Test func nothingGoesOnlineUntilTheLeakCheckIsOn() async {
        let storage = makeStorage()
        storage.save(Password(name: "Forum", value: "password"))
        storage.save(Password(name: "Shop", value: "kfjdqpwzm#R7"))
        checker.leaked = [PwnedPasswords.hash(of: "kfjdqpwzm#R7")]

        let monitor = makeMonitor(checksLeaks: false)
        #expect(!monitor.isLoaded)
        monitor.start()
        await refreshNow(monitor)
        #expect(monitor.isLoaded)
        #expect(checker.prefixes.isEmpty)
        #expect(monitor.leakCheck == .off)
        #expect(monitor.report.items.map(\.password.name) == ["Forum"])

        monitor.checksLeakedPasswords = true
        await monitor.waitForRefresh()
        #expect(monitor.leakCheck == .checked)
        #expect(monitor.report.leaked.map(\.password.name) == ["Shop"])
        #expect(monitor.report.toFixCount == 2)

        // Looked up already: not asked again.
        let asked = checker.prefixes.count
        await refreshNow(monitor)
        #expect(checker.prefixes.count == asked)
        #expect(monitor.report.leaked.map(\.password.name) == ["Shop"])

        // Off forgets what was found.
        monitor.checksLeakedPasswords = false
        await monitor.waitForRefresh()
        #expect(monitor.leakCheck == .off)
        #expect(monitor.report.leaked.isEmpty)
        #expect(cache.isLeaked(PwnedPasswords.hash(of: "kfjdqpwzm#R7")) == nil)
    }

    @Test func aFailedLookupKeepsWhatItFound() async {
        let storage = makeStorage()
        storage.save(Password(name: "Forum", value: "password"))
        storage.save(Password(name: "Shop", value: "kfjdqpwzm#R7"))
        checker.leaked = [PwnedPasswords.hash(of: "kfjdqpwzm#R7")]
        checker.failing = [String(PwnedPasswords.hash(of: "password").prefix(5))]

        let monitor = makeMonitor(checksLeaks: true)
        monitor.start()
        await refreshNow(monitor)
        #expect(monitor.leakCheck == .failed)
        // Found on the device, and found before the failure.
        #expect(monitor.report.weak.map(\.password.name) == ["Forum"])
        #expect(monitor.report.leaked.map(\.password.name) == ["Shop"])

        // Next time only what's missing is asked.
        checker.failing = []
        checker.reset()
        await refreshNow(monitor)
        #expect(checker.prefixes == [String(PwnedPasswords.hash(of: "password").prefix(5))])
        #expect(monitor.leakCheck == .checked)
    }

    @Test func aNewValueUpdatesTheReportOnItsOwn() async {
        let storage = makeStorage()
        var password = Password(name: "Forum", value: "kfjdqpwzm#R7")
        storage.save(password)
        let monitor = makeMonitor(checksLeaks: false)
        monitor.start()
        await refreshNow(monitor)
        #expect(monitor.report.toFixCount == 0)

        // Only the value changes, so Core Data publishes nothing; the save's notification is enough.
        password.value = "letmein"
        storage.save(password)
        await monitor.waitForRefresh()
        #expect(monitor.report.weak.map(\.password.name) == ["Forum"])
    }

    @Test func hiddenWarningsLastWhileTheValueAndIssuesStayTheSame() async throws {
        let storage = makeStorage()
        var password = Password(name: "Forum", value: "password")
        storage.save(password)
        let monitor = makeMonitor(checksLeaks: false)
        monitor.start()
        await refreshNow(monitor)

        monitor.setWarningsHidden(true, for: password.id)
        // At once, before the next pass.
        #expect(monitor.report.isHidden(password.id))
        await monitor.waitForRefresh()
        #expect(monitor.report.isHidden(password.id))
        #expect(monitor.report.toFixCount == 0)

        // Saving the same value keeps it hidden; a new value shows the warnings again.
        storage.save(password)
        await refreshNow(monitor)
        #expect(monitor.report.isHidden(password.id))
        password.value = "letmein"
        storage.save(password)
        await refreshNow(monitor)
        #expect(!monitor.report.isHidden(password.id))
        #expect(monitor.report.toFixCount == 1)

        // A leak found after hiding shows it again.
        monitor.setWarningsHidden(true, for: password.id)
        await monitor.waitForRefresh()
        #expect(monitor.report.isHidden(password.id))
        checker.leaked = [PwnedPasswords.hash(of: "letmein")]
        monitor.checksLeakedPasswords = true
        await monitor.waitForRefresh()
        #expect(!monitor.report.isHidden(password.id))
        #expect(monitor.report.leaked.map(\.password.name) == ["Forum"])

        monitor.setWarningsHidden(true, for: password.id)
        storage.delete(password)
        #expect(keychain.string(forKey: PasswordsStorage.hiddenWarningKey(for: password.id)) == nil)
    }

    @Test func resetForgetsLeakResults() async {
        makeStorage().save(Password(name: "Shop", value: "kfjdqpwzm#R7"))
        checker.leaked = [PwnedPasswords.hash(of: "kfjdqpwzm#R7")]
        let monitor = makeMonitor(checksLeaks: true)
        monitor.start()
        await refreshNow(monitor)
        #expect(cache.isLeaked(PwnedPasswords.hash(of: "kfjdqpwzm#R7")) == true)
        monitor.reset()
        #expect(cache.isLeaked(PwnedPasswords.hash(of: "kfjdqpwzm#R7")) == nil)
        await monitor.waitForRefresh()
    }
}
