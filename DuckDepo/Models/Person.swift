//
//  Person.swift
//  DuckDepo
//

import Foundation

/// Someone documents and passwords belong to, such as a family member. Each document and password
/// belongs to one person or to no one.
///
/// Stored as `DDFolder`, an entity the model has had (unused) since version 1, so its iCloud record type
/// already existed.
struct Person: Identifiable, Hashable {
    var id: UUID
    var name: String
    var color: PersonColor
    /// Position among people: in the filter rows and in Settings.
    var order: Int

    init(id: UUID = UUID(), name: String = "", color: PersonColor = .blue, order: Int = 0) {
        self.id = id
        self.name = name
        self.color = color
        self.order = order
    }

    /// Up to two characters: the first of the first and of the last word ("Anna Maria Lee" is "AL"),
    /// or empty for an empty name.
    var initials: String {
        let words = name.split { $0.isWhitespace || $0 == "-" }
        guard let first = words.first?.first else { return "" }
        guard words.count > 1, let last = words.last?.first else { return String(first).uppercased() }
        return (String(first) + String(last)).uppercased()
    }

    /// The first word of the name, for tight places such as list rows.
    var shortName: String {
        name.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? name
    }

    /// Whether `query` is part of the name, ignoring case and diacritics.
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return !query.isEmpty && name.localizedStandardContains(query)
    }
}

/// A person's color. Raw values are stored and synced and must not change.
enum PersonColor: String, CaseIterable, Identifiable {
    case blue, green, orange, pink, purple, red, teal, indigo, brown, gray

    var id: String { rawValue }

    /// The first color nobody uses yet, so a new person stands out from the others.
    static func unused(among used: [PersonColor]) -> PersonColor {
        let counts = Dictionary(used.map { ($0, 1) }, uniquingKeysWith: +)
        return allCases.min { counts[$0, default: 0] < counts[$1, default: 0] } ?? .blue
    }

    /// For a color this version doesn't know (written by a newer one): the same one on every device.
    static func fallback(for id: UUID) -> PersonColor {
        let sum = id.uuidString.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return allCases[sum % allCases.count]
    }
}

/// Whose documents or passwords a list shows.
enum PersonFilter: Hashable {
    case everyone
    case person(Person.ID)

    var personID: Person.ID? {
        if case .person(let id) = self { return id }
        return nil
    }
}

/// How much belongs to a person.
struct PersonCounts: Equatable {
    var documents = 0
    var passwords = 0
}
