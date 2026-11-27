//
//  PwnedPasswords.swift
//  DuckDepo
//

import Foundation

/// Finds out whether passwords appeared in known data leaks.
protocol LeakChecking {
    /// The leaked SHA-1 hashes that start with `prefix` (five hex digits), without the prefix, uppercase.
    func leakedSuffixes(forPrefix prefix: String) async throws -> Set<String>
}

/// Have I Been Pwned's Pwned Passwords range API. Only the first five hex digits of a password's SHA-1 hash
/// are sent; the answer lists every leaked hash starting with them, padded with fake entries so its size
/// gives nothing away. The password, and the rest of its hash, never leave the device.
struct PwnedPasswords: LeakChecking {

    /// Ephemeral: nothing about the requests is written to disk.
    private let session: URLSession

    init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    func leakedSuffixes(forPrefix prefix: String) async throws -> Set<String> {
        let (data, response) = try await session.data(for: Self.request(forPrefix: prefix))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try Self.leakedSuffixes(in: String(decoding: data, as: UTF8.self))
    }

    /// The same for every user: no language, device or app version beyond the name.
    static func request(forPrefix prefix: String) throws -> URLRequest {
        guard prefix.count == 5, prefix.allSatisfy(\.isHexDigit),
              let url = URL(string: "https://api.pwnedpasswords.com/range/\(prefix)") else { throw URLError(.badURL) }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("true", forHTTPHeaderField: "Add-Padding")
        request.setValue("DuckDepo", forHTTPHeaderField: "User-Agent")
        request.setValue("text/plain", forHTTPHeaderField: "Accept")
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        return request
    }

    /// Lines of "SUFFIX:COUNT" (35 hex digits); padding entries have a count of 0. Anything else (a block page
    /// from a network filter, an empty answer) throws: read as "nothing leaked", it would call leaked
    /// passwords safe for a week.
    static func leakedSuffixes(in body: String) throws -> Set<String> {
        var suffixes = Set<String>()
        var lines = 0
        for line in body.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 2, parts[0].count == 35, parts[0].allSatisfy(\.isHexDigit),
                  let count = Int(parts[1]), count >= 0 else { throw URLError(.cannotParseResponse) }
            lines += 1
            if count > 0 {
                suffixes.insert(parts[0].uppercased())
            }
        }
        guard lines > 0 else { throw URLError(.zeroByteResource) }
        return suffixes
    }

    /// Uppercase hex, as the API writes it.
    static func hash(of password: String) -> String {
        PasswordsStorage.valueHash(of: password)
    }
}

extension LeakChecking {

    /// Looks the hashes up, one request per distinct prefix, a few at a time. `answered` hears about each
    /// prefix as soon as it's answered (the hashes asked about, and which of them leaked), so what was found
    /// is kept even if a later request fails. Throws if any request fails.
    func lookUp(_ hashes: Set<String>, answered: (_ checked: Set<String>, _ leaked: Set<String>) -> Void) async throws {
        let byPrefix = Dictionary(grouping: hashes) { String($0.prefix(5)) }
        let check = { (prefix: String, hashes: [String]) async throws -> (Set<String>, Set<String>) in
            let suffixes = try await leakedSuffixes(forPrefix: prefix)
            return (Set(hashes), Set(hashes.filter { suffixes.contains(String($0.dropFirst(5))) }))
        }
        try await withThrowingTaskGroup(of: (Set<String>, Set<String>).self) { group in
            var remaining = byPrefix.makeIterator()
            for _ in 0..<4 {
                if let (prefix, hashes) = remaining.next() {
                    group.addTask { try await check(prefix, hashes) }
                }
            }
            while let (checked, leaked) = try await group.next() {
                answered(checked, leaked)
                if let (prefix, hashes) = remaining.next() {
                    group.addTask { try await check(prefix, hashes) }
                }
            }
        }
    }

    /// Which of these hashes leaked. Throws if any request fails: a partial answer would call leaked
    /// passwords safe.
    func leakedHashes(among hashes: Set<String>) async throws -> Set<String> {
        var leaked = Set<String>()
        try await lookUp(hashes) { _, found in
            leaked.formUnion(found)
        }
        return leaked
    }
}
