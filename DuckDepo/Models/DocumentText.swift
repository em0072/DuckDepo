//
//  DocumentText.swift
//  DuckDepo
//

import Foundation

extension Document {

    /// The document as plain text, as it shows in DuckDepo: its name, description and every filled-in
    /// field by section. What "Share as Text" and "Copy All" give.
    var plainText: String {
        [name, description, sectionsText].filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    /// Each filled-in section's name, then a "Title: value" line per field; sections apart by a blank line.
    var sectionsText: String {
        sectionsWithValues.map { section in
            ([section.displayName] + section.fields.map { "\($0.displayTitle): \($0.displayValue)" }).joined(separator: "\n")
        }.joined(separator: "\n\n")
    }
}
