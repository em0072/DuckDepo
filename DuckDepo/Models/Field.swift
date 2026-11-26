//
//  Field.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import Foundation

struct Field: Identifiable, Equatable, Hashable {

    enum FieldType: String {
        case string
        /// The value is a day stored as "yyyy-MM-dd" (see `FieldDate`).
        case date
    }

    var id = UUID()
    /// A `FieldKey` raw value for predefined fields, nil for custom ones. Kept as a string so a key
    /// from a newer app version survives an edit here.
    var key: String?
    /// The name as stored; older versions show this. Predefined fields display `displayTitle`.
    var title: String
    var value: String = ""
    var type: FieldType = .string

    init(id: UUID = UUID(), key: String? = nil, title: String, value: String = "", type: FieldType = .string) {
        self.id = id
        self.key = key
        self.title = title
        self.value = value
        self.type = type
    }

    var fieldKey: FieldKey? {
        key.flatMap(FieldKey.init(rawValue:))
    }

    /// The name in the current language for predefined fields.
    var displayTitle: String {
        fieldKey?.localizedName ?? title
    }

    /// The value as shown and copied: dates in the user's format.
    var displayValue: String {
        type == .date ? FieldDate.displayString(for: value) : value
    }
}
