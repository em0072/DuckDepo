//
//  PersonSuggestion.swift
//  DuckDepo
//

import CoreData
import Foundation

/// Whose a scanned document probably is, from the holder's name on it.
enum PersonSuggestion {

    /// The holder's name on a document that belongs to someone.
    struct Holder: Equatable {
        let documentID: UUID
        let personID: Person.ID
        let name: Set<String>
    }

    /// From what's stored. Reads nothing when the scan has no holder name or there's nobody to suggest,
    /// and otherwise only the holder names on documents that belong to someone.
    static func person(for document: Document, in database: DataBase) -> Person.ID? {
        guard holderName(of: document) != nil else { return nil }
        let people = database.allPeople()
        guard !people.isEmpty else { return nil }
        return person(for: document, holders: database.holderNames(), people: people)
    }

    /// The person whose other documents carry the same holder name; failing that, the one person whose
    /// name is part of the holder's ("Anna" for ANNA LEE). Nil when it's nobody, or not clear who.
    static func person(for document: Document, among documents: [Document], people: [Person]) -> Person.ID? {
        let holders = documents.compactMap { other -> Holder? in
            guard let personID = other.personID, let name = holderName(of: other) else { return nil }
            return Holder(documentID: other.id, personID: personID, name: name)
        }
        return person(for: document, holders: holders, people: people)
    }

    static func person(for document: Document, holders: [Holder], people: [Person]) -> Person.ID? {
        guard let holder = holderName(of: document) else { return nil }
        let known = Set(people.map(\.id))
        let byDocuments = Set(holders.compactMap { other -> Person.ID? in
            guard other.documentID != document.id, known.contains(other.personID), other.name == holder else { return nil }
            return other.personID
        })
        if byDocuments.count == 1 {
            return byDocuments.first
        }
        guard byDocuments.isEmpty else { return nil }
        let byName = people.filter { person in
            let words = normalizedWords(in: person.name)
            return !words.isEmpty && words.isSubset(of: holder)
        }
        return byName.count == 1 ? byName[0].id : nil
    }

    /// The words of the holder's name, in any order: "LEE ANNA" and "Anna Lee" are the same.
    static func holderName(of document: Document) -> Set<String>? {
        let value = document.sections.lazy.flatMap(\.fields)
            .first { $0.fieldKey == .fullName && !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }?
            .value
        return value.flatMap(holderName(in:))
    }

    fileprivate static func holderName(in value: String) -> Set<String>? {
        let words = normalizedWords(in: value)
        return words.isEmpty ? nil : words
    }

    /// Lowercased, in Latin letters without accents, so a Cyrillic name can match its spelling on a
    /// passport's machine-readable zone when the spellings agree.
    static func normalizedWords(in text: String) -> Set<String> {
        let latin = text.applyingTransform(.toLatin, reverse: false) ?? text
        let folded = latin.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        return Set(folded.split { !$0.isLetter }.map(String.init))
    }
}

extension DataBase {

    /// The holder's name on each document that belongs to someone: the first filled-in full name, as on
    /// screen. Reads only those fields, not whole documents.
    func holderNames() -> [PersonSuggestion.Holder] {
        let request = DDField.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@ AND section.document.folder != nil", FieldKey.fullName.rawValue)
        request.relationshipKeyPathsForPrefetching = ["section", "section.document", "section.document.folder"]
        guard let fields = try? context.fetch(request) else { return [] }
        var first: [UUID: (position: (Int32, Int32), holder: PersonSuggestion.Holder)] = [:]
        for field in fields {
            guard let section = field.section, let document = section.document, let documentID = document.identifier,
                  let personID = document.folder?.identifier,
                  let value = field.value, !value.trimmingCharacters(in: .whitespaces).isEmpty,
                  let name = PersonSuggestion.holderName(in: value) else { continue }
            let position = (section.order, field.order)
            if let existing = first[documentID], existing.position <= position { continue }
            first[documentID] = (position, PersonSuggestion.Holder(documentID: documentID, personID: personID, name: name))
        }
        return first.values.map(\.holder)
    }
}
