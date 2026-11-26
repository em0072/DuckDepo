//
//  FieldDate.swift
//  DuckDepo
//

import Foundation

/// Date fields store a calendar day as "yyyy-MM-dd": no time or time zone, so the day is the same on every
/// device. Older versions stored dates as free text; `parseLegacy` converts the unambiguous ones.
enum FieldDate {

    static func components(from storedValue: String) -> DateComponents? {
        let parts = storedValue.split(separator: "-")
        guard parts.count == 3, parts[0].count == 4,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        return validated(year: year, month: month, day: day)
    }

    static func storedValue(from components: DateComponents) -> String? {
        guard let year = components.year, let month = components.month, let day = components.day,
              validated(year: year, month: month, day: day) != nil else { return nil }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// The day as a date at midnight UTC, for storing and sorting (e.g. a document's expiry).
    static func utcDate(from storedValue: String) -> Date? {
        components(from: storedValue).flatMap { utcCalendar.date(from: $0) }
    }

    /// The day at the start of the day in the user's time zone, for a date picker.
    static func localDate(from storedValue: String, calendar: Calendar = localCalendar) -> Date? {
        components(from: storedValue).flatMap { calendar.date(from: $0) }
    }

    static func storedValue(fromLocalDate date: Date, calendar: Calendar = localCalendar) -> String? {
        storedValue(from: calendar.dateComponents([.year, .month, .day], from: date))
    }

    /// Gregorian in the user's time zone. Stored days are Gregorian, so converting with `Calendar.current`
    /// would store the wrong year for someone using, say, the Buddhist or Japanese calendar.
    static var localCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    /// Whole days from the day of `date` in `calendar`'s time zone to a day stored as midnight UTC.
    /// Negative when the day has passed.
    static func days(from date: Date, toUTCDay utcDay: Date, calendar: Calendar = localCalendar) -> Int {
        let today = calendar.dateComponents([.year, .month, .day], from: date)
        guard let todayUTC = utcCalendar.date(from: today) else { return 0 }
        return utcCalendar.dateComponents([.day], from: todayUTC, to: utcDay).day ?? 0
    }

    /// A day stored as midnight UTC in the user's format.
    static func displayString(forUTCDay date: Date, locale: Locale = .current) -> String {
        var style = Date.FormatStyle(date: .long, time: .omitted, locale: locale)
        style.timeZone = .gmt
        return date.formatted(style)
    }

    /// The day in the user's format, or the value as is if it isn't a stored date.
    static func displayString(for storedValue: String, locale: Locale = .current) -> String {
        guard let date = utcDate(from: storedValue) else { return storedValue }
        return displayString(forUTCDay: date, locale: locale)
    }

    /// Converts a date typed into an older version, only when it can be read just one way:
    /// "2032-02-01", "01.02.2032" (dots are day-first everywhere), or slashes/dashes where one part
    /// is above 12. "01/02/2032" stays text: it is 1 February in Europe and 2 January in the US.
    static func parseLegacy(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if components(from: trimmed) != nil {
            return trimmed
        }
        for separator: Character in [".", "/", "-"] {
            let parts = trimmed.split(separator: separator, omittingEmptySubsequences: false)
            guard parts.count == 3, parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isNumber) }),
                  parts[2].count == 4, parts[0].count <= 2, parts[1].count <= 2,
                  let first = Int(parts[0]), let second = Int(parts[1]), let year = Int(parts[2]) else { continue }
            let day: Int
            let month: Int
            if separator == "." || first > 12 {
                (day, month) = (first, second)
            } else if second > 12 {
                (day, month) = (second, first)
            } else {
                return nil
            }
            return validated(year: year, month: month, day: day).flatMap(storedValue(from:))
        }
        return nil
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    private static func validated(year: Int, month: Int, day: Int) -> DateComponents? {
        guard (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day) else { return nil }
        let components = DateComponents(year: year, month: month, day: day)
        // Rejects days that don't exist, like 31 February.
        guard let date = utcCalendar.date(from: components) else { return nil }
        let roundTrip = utcCalendar.dateComponents([.year, .month, .day], from: date)
        guard roundTrip.year == year, roundTrip.month == month, roundTrip.day == day else { return nil }
        return components
    }
}
