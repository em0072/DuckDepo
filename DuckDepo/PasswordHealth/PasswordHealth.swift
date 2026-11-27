//
//  PasswordHealth.swift
//  DuckDepo
//

import Foundation

/// What's wrong with the saved passwords: leaked, reused, easy to guess. Holds no password values: reuse is
/// found by hash, and the passwords it lists are list items.
struct PasswordHealth: Equatable {

    enum Issue: Hashable {
        case leaked
        /// The same password is used for this many accounts, this one included.
        case reused(accounts: Int)
        case weak(PasswordStrength.Weakness)

        /// What a hidden warning records: the kind of issue, not its details (a reuse count that changes
        /// doesn't show it again).
        var kind: String {
            switch self {
            case .leaked: "leaked"
            case .reused: "reused"
            case .weak: "weak"
            }
        }
    }

    struct Item: Identifiable, Equatable {
        /// Without its value.
        let password: Password
        /// Most serious first.
        let issues: [Issue]
        /// Passwords that share a value share a group, so the screen can list them together.
        let reuseGroup: Int?

        var id: Password.ID { password.id }
        var isLeaked: Bool { issues.contains(.leaked) }
        var isReused: Bool { reuseGroup != nil }
    }

    /// What the report is made from: a password without its value, and what's known about the value.
    struct Entry {
        let password: Password
        /// The value's SHA-1 (`PwnedPasswords.hash(of:)`).
        let hash: String
        let weakness: PasswordStrength.Weakness?
    }

    /// Passwords with something to fix whose warnings are shown, by name.
    private(set) var items: [Item] = []
    /// Passwords with something to fix whose warnings the user hid, by name.
    private(set) var hiddenItems: [Item] = []

    static let empty = PasswordHealth()

    /// How many passwords need fixing (not counting hidden ones).
    var toFixCount: Int { items.count }

    /// Each password once, under its most serious issue.
    var leaked: [Item] { items.filter(\.isLeaked) }
    /// Passwords that share a value together; `items` are in name order already.
    var reused: [Item] {
        let reused = items.filter { !$0.isLeaked && $0.isReused }
        return Dictionary(grouping: reused) { $0.reuseGroup ?? 0 }
            .sorted { $0.key < $1.key }
            .flatMap(\.value)
    }
    var weak: [Item] { items.filter { !$0.isLeaked && !$0.isReused } }

    func item(for id: Password.ID) -> Item? {
        items.first { $0.id == id } ?? hiddenItems.first { $0.id == id }
    }

    func isHidden(_ id: Password.ID) -> Bool {
        hiddenItems.contains { $0.id == id }
    }

    /// The same report with one password's warnings hidden or shown, so the screens can move it at once;
    /// the next pass confirms it.
    func settingHidden(_ isHidden: Bool, for id: Password.ID) -> PasswordHealth {
        var health = self
        if isHidden, let index = health.items.firstIndex(where: { $0.id == id }) {
            health.hiddenItems.append(health.items.remove(at: index))
        } else if !isHidden, let index = health.hiddenItems.firstIndex(where: { $0.id == id }) {
            health.items.append(health.hiddenItems.remove(at: index))
        }
        health.items.sort(by: Self.inNameOrder)
        health.hiddenItems.sort(by: Self.inNameOrder)
        return health
    }

    private static func inNameOrder(_ lhs: Item, _ rhs: Item) -> Bool {
        lhs.password.name.localizedStandardCompare(rhs.password.name) == .orderedAscending
    }

    /// `leaked` are hashes known to have leaked; `hidden` is what the user hid. A password stays hidden only
    /// while it has the value it had then and no issue it didn't have then.
    static func evaluate(_ entries: [Entry], leaked: Set<String> = [],
                         hidden: [Password.ID: PasswordsStorage.HiddenWarnings] = [:]) -> PasswordHealth {
        let sharing = Dictionary(grouping: entries, by: \.hash).filter { $0.value.count > 1 }
        let groups = Dictionary(uniqueKeysWithValues: sharing.keys.sorted().enumerated().map { ($1, $0) })
        var health = PasswordHealth()
        for entry in entries.sorted(by: { $0.password.name.localizedStandardCompare($1.password.name) == .orderedAscending }) {
            var issues: [Issue] = []
            if leaked.contains(entry.hash) {
                issues.append(.leaked)
            }
            if let accounts = sharing[entry.hash]?.count {
                issues.append(.reused(accounts: accounts))
            }
            if let weakness = entry.weakness {
                issues.append(.weak(weakness))
            }
            guard !issues.isEmpty else { continue }
            let item = Item(password: entry.password, issues: issues, reuseGroup: groups[entry.hash])
            if let marker = hidden[entry.password.id], marker.valueHash == entry.hash,
               Set(issues.map(\.kind)).isSubset(of: marker.issues) {
                health.hiddenItems.append(item)
            } else {
                health.items.append(item)
            }
        }
        return health
    }
}

extension PasswordHealth.Entry {

    /// Reads what the report needs from a value, then forgets it.
    init(password: Password, value: String) {
        var listItem = password
        listItem.value = ""
        listItem.oneTimeCode = ""
        self.init(password: listItem, hash: PwnedPasswords.hash(of: value), weakness: PasswordStrength.weakness(of: value))
    }
}
