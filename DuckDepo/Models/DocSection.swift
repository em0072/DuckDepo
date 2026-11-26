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
    var name: String
    var fields: [Field]

    init(id: UUID = UUID(), name: String = "", fields: [Field] = []) {
        self.id = id
        self.name = name
        self.fields = fields
    }

    /// `true` when at least one field has a value.
    var hasValues: Bool {
        fields.contains { !$0.value.isEmpty }
    }
}
