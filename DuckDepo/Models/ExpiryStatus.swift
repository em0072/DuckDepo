//
//  ExpiryStatus.swift
//  DuckDepo
//

import SwiftUI

/// How close a document is to its expiry day, the last day it is valid.
enum ExpiryStatus: Equatable {
    case expired
    /// `days` until the expiry day; 0 means today is the last valid day.
    case expiresSoon(days: Int)
    case valid

    /// Documents closer than this to expiring are flagged in the list.
    static let soonThreshold = 90

    /// - Parameter expiryDate: The expiry day as midnight UTC (`Document.expiryDate`).
    init(expiryDate: Date, today: Date = .now, calendar: Calendar = FieldDate.localCalendar) {
        let days = FieldDate.days(from: today, toUTCDay: expiryDate, calendar: calendar)
        if days < 0 {
            self = .expired
        } else if days <= Self.soonThreshold {
            self = .expiresSoon(days: days)
        } else {
            self = .valid
        }
    }

    /// Short text for flagging the document in lists, or nil when there is nothing to flag.
    var badgeText: String? {
        switch self {
        case .expired: String(localized: "expiry_expired")
        case .expiresSoon(0): String(localized: "expiry_today")
        case .expiresSoon(let days): String(localized: "expiry_in_days \(days)")
        case .valid: nil
        }
    }

    var color: Color {
        switch self {
        case .expired: .red
        case .expiresSoon: .orange
        case .valid: .green
        }
    }

    var systemImage: String {
        switch self {
        case .expired: "exclamationmark.triangle.fill"
        case .expiresSoon: "clock.fill"
        case .valid: "checkmark.seal.fill"
        }
    }
}

extension Document {
    var expiryStatus: ExpiryStatus? {
        expiryDate.map { ExpiryStatus(expiryDate: $0) }
    }
}
