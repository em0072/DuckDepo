//
//  DrivingLicenceParser.swift
//  DuckDepo
//

import Foundation

/// The front of an EU driving licence, whose fields are numbered the same in every language.
struct DrivingLicenceReading: Equatable {
    /// 1.
    var surname: String?
    /// 2.
    var givenNames: String?
    /// 3., before the place.
    var birthDate: String?
    /// 3., after the date.
    var birthPlace: String?
    /// 4a.
    var issueDate: String?
    /// 4b.
    var expiryDate: String?
    /// 4c.
    var authority: String?
    /// 5.
    var number: String?
    /// 9.
    var categories: String?

    /// Given names then surname, as printed.
    var fullName: String? {
        let parts = [givenNames, surname].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

enum DrivingLicenceParser {

    /// Reads the numbered fields from recognized lines in reading order. Nil unless enough of them are
    /// there to be sure it's a licence.
    static func parse(lines: [String], today: Date = .now) -> DrivingLicenceReading? {
        let fields = numberedFields(in: lines)
        let identifying: Set<String> = ["1", "2", "3", "4A", "4B", "5"]
        guard Set(fields.keys).intersection(identifying).count >= 3,
              fields["4A"] != nil || fields["4B"] != nil || fields["5"] != nil else { return nil }

        var reading = DrivingLicenceReading()
        reading.surname = fields["1"]
        reading.givenNames = fields["2"]
        if let birth = fields["3"] {
            if let date = ScanDates.firstDate(in: birth, tense: .past, today: today) {
                reading.birthDate = date.value
                let place = birth[date.range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
                reading.birthPlace = place.isEmpty ? nil : place
            }
        }
        reading.issueDate = fields["4A"].flatMap { ScanDates.firstDate(in: $0, tense: .past, today: today)?.value }
        reading.expiryDate = fields["4B"].flatMap { ScanDates.firstDate(in: $0, tense: .future, today: today)?.value }
        reading.authority = fields["4C"]
        reading.number = fields["5"].map { $0.replacingOccurrences(of: " ", with: "") }
        reading.categories = fields["9"]
        return reading
    }

    /// A field number at the start of a line or after a space: "1.", "4a.", "4b" (the letter is enough), and
    /// "4a)" as on Russian licences. Recognition sometimes drops the space after it ("5.5123456789") and
    /// reads the letter as its Cyrillic look-alike ("4а."). The match includes the space before it, which
    /// keeps "15.04." in a date from counting as field 5.
    nonisolated(unsafe) private static let marker = /(?:^|\s)(4\s?[a-dA-DаАвВьЬсС][.,)]?|[1-9][.,)])/

    /// The field number as a key: "4A" for "4a.", "4а." or "4a)".
    private static func key(for marker: Substring) -> String {
        let latin: [Character: Character] = ["А": "A", "В": "B", "Ь": "B", "С": "C"]
        return String(marker.uppercased().compactMap { character -> Character? in
            let character = latin[character] ?? character
            return character.isLetter || character.isNumber ? character : nil
        })
    }

    /// Field number (uppercased, without the dot) to its text. A value on the line after its number is
    /// taken too; the first occurrence of a number wins.
    private static func numberedFields(in lines: [String]) -> [String: String] {
        var fields: [String: String] = [:]
        var pendingKey: String?
        for line in lines {
            let markers = line.matches(of: marker)
            if markers.isEmpty {
                if let key = pendingKey, fields[key] == nil {
                    let value = line.trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty {
                        fields[key] = value
                    }
                }
                pendingKey = nil
                continue
            }
            pendingKey = nil
            for (index, match) in markers.enumerated() {
                let key = key(for: match.output.1)
                let end = index + 1 < markers.count ? markers[index + 1].range.lowerBound : line.endIndex
                let value = line[match.range.upperBound..<end].trimmingCharacters(in: .whitespaces)
                guard fields[key] == nil else { continue }
                if value.isEmpty {
                    pendingKey = key
                } else {
                    fields[key] = value
                }
            }
        }
        return fields
    }
}
