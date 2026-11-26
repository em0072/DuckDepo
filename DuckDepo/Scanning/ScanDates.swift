//
//  ScanDates.swift
//  DuckDepo
//

import Foundation

/// Reads dates printed on documents: "15.04.1985", "15/04/85", "1985-04-15".
enum ScanDates {

    /// Which way a two-digit year leans.
    enum Tense {
        /// Birth and issue dates: never in the future.
        case past
        /// Expiry dates: this century unless that's more than 50 years away.
        case future
    }

    /// The first date in `text`, as "yyyy-MM-dd" (the way `FieldDate` stores days), with where it was found.
    /// Day first, as printed in Europe, unless the year comes first or the second number can't be a month.
    static func firstDate(in text: String, tense: Tense, today: Date = .now) -> (value: String, range: Range<String.Index>)? {
        for match in text.matches(of: pattern) {
            let first = Int(match.output.1)!, second = Int(match.output.2)!, third = match.output.3
            let value: String?
            if match.output.1.count == 4 {
                value = storedValue(year: first, month: second, day: Int(third)!)
            } else {
                let year = Int(third)!
                let fullYear = third.count == 2 ? century(for: year, tense: tense, today: today) : year
                value = second > 12
                    ? storedValue(year: fullYear, month: first, day: second)
                    : storedValue(year: fullYear, month: second, day: first)
            }
            if let value {
                return (value, match.range)
            }
        }
        return nil
    }

    /// d.m.yyyy, d/m/yy, yyyy-mm-dd and the like, not inside a longer number. (The match may include the
    /// character before the date; only its end is used.)
    nonisolated(unsafe) private static let pattern =
        /(?:^|[^0-9])(\d{4}|\d{1,2})[.\/\- ](\d{1,2})[.\/\- ](\d{4}|\d{2})(?![0-9])/

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private static func century(for yy: Int, tense: Tense, today: Date) -> Int {
        let currentYear = calendar.component(.year, from: today)
        let year = 2000 + yy
        switch tense {
        case .past: return year > currentYear ? year - 100 : year
        case .future: return year > currentYear + 50 ? year - 100 : year
        }
    }

    private static func storedValue(year: Int, month: Int, day: Int) -> String? {
        guard (1900...2200).contains(year),
              DateComponents(year: year, month: month, day: day).isValidDate(in: calendar) else { return nil }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
