//
//  Section.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import Foundation

/// Equality compares contents (used to detect unsaved changes). Look sections up by `id`.
struct DocSection: Identifiable, Hashable {
    var id = UUID()
    /// A `SectionKey` raw value for predefined sections, nil for custom ones.
    var key: String?
    /// The name as stored; older versions show this. Predefined sections display `displayName`.
    var name: String
    var fields: [Field]

    init(id: UUID = UUID(), key: String? = nil, name: String = "", fields: [Field] = []) {
        self.id = id
        self.key = key
        self.name = name
        self.fields = fields
    }

    var sectionKey: SectionKey? {
        key.flatMap(SectionKey.init(rawValue:))
    }

    /// The name in the current language for predefined sections.
    var displayName: String {
        sectionKey?.localizedName ?? name
    }

    /// `true` when at least one field has a value.
    var hasValues: Bool {
        fields.contains { !$0.value.isEmpty }
    }

    /// Predefined fields of this section that it doesn't have yet.
    var missingPredefinedFields: [FieldKey] {
        guard let sectionKey else { return [] }
        let present = Set(fields.compactMap(\.key))
        return sectionKey.fields.filter { !present.contains($0.rawValue) }
    }
}
