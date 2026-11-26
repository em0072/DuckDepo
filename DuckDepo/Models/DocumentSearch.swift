//
//  DocumentSearch.swift
//  DuckDepo
//

import Foundation

/// Documents of one type, a section of the documents list.
struct DocumentGroup: Identifiable, Equatable {
    let type: DocumentType
    let documents: [Document]

    var id: DocumentType { type }
}

enum DocumentSearch {

    /// The documents that match `query`, grouped by type in the order types are listed. Keeps the
    /// documents' order within each group.
    static func groups(for documents: [Document], matching query: String) -> [DocumentGroup] {
        let matching = documents.filter { matches($0, query: query) }
        let byType = Dictionary(grouping: matching, by: \.documentType)
        return DocumentType.allCases.compactMap { type in
            byType[type].map { DocumentGroup(type: type, documents: $0) }
        }
    }

    /// Matches the name, description, type and any field value, ignoring case and diacritics.
    static func matches(_ document: Document, query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        let fieldValues = document.sections.lazy.flatMap(\.fields).map(\.displayValue)
        return [document.name, document.description, document.documentType.localizedName]
            .contains { $0.localizedStandardContains(query) }
            || fieldValues.contains { $0.localizedStandardContains(query) }
    }
}
