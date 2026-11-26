//
//  DomainMatcher.swift
//  DuckDepo
//

import Foundation

/// Matches a saved website against the site AutoFill is asking about.
enum DomainMatcher {

    /// Lower-cased host without a leading `www.`; `nil` for empty or unparsable input.
    static func host(from string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard var host = URLComponents(string: withScheme)?.host, !host.isEmpty else { return nil }
        if host.hasPrefix("www.") {
            host.removeFirst(4)
        }
        return host.isEmpty ? nil : host
    }

    /// `true` when both hosts are equal or one is a subdomain of the other
    /// (`accounts.google.com` matches `google.com`). Empty websites never match.
    static func matches(website: String, serviceIdentifier: String) -> Bool {
        guard let saved = host(from: website), let requested = host(from: serviceIdentifier) else { return false }
        return saved == requested
            || requested.hasSuffix("." + saved)
            || saved.hasSuffix("." + requested)
    }
}
