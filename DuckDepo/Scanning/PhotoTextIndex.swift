//
//  PhotoTextIndex.swift
//  DuckDepo
//

import Foundation
import os

extension Notification.Name {
    /// Posted on the main queue when photo text was added or removed.
    static let photoTextIndexDidChange = Notification.Name("photoTextIndexDidChange")
}

/// The text read from each document photo, so search can find documents by what's in their pictures.
///
/// Kept only on this device, in a file with complete data protection: every device reads its own photos,
/// so nothing extra syncs and the Core Data model stays as it is. Photo IDs come from the image bytes,
/// so an entry stays right for as long as its photo exists.
final class PhotoTextIndex: @unchecked Sendable {

    /// One photo of one document. The same picture can belong to two documents.
    struct Key: Hashable, Codable {
        let documentID: UUID
        let photoID: UUID
    }

    static let shared = PhotoTextIndex(fileURL: defaultFileURL)

    private let fileURL: URL?
    private let lock = NSLock()
    private var texts: [Key: String]
    private let logger = Logger(subsystem: "DuckDepo", category: "PhotoTextIndex")

    /// `fileURL` nil keeps the index in memory (tests).
    init(fileURL: URL?) {
        self.fileURL = fileURL
        texts = fileURL.flatMap(Self.load) ?? [:]
    }

    var keys: Set<Key> {
        lock.withLock { Set(texts.keys) }
    }

    func text(for key: Key) -> String? {
        lock.withLock { texts[key] }
    }

    func set(_ text: String, for key: Key) {
        lock.withLock { texts[key] = text }
    }

    /// Forgets photos that no longer exist. Returns whether anything was removed.
    @discardableResult
    func removeEntries(notIn existing: Set<Key>) -> Bool {
        lock.withLock {
            let stale = texts.keys.filter { !existing.contains($0) }
            stale.forEach { texts[$0] = nil }
            return !stale.isEmpty
        }
    }

    func removeAll() {
        lock.withLock { texts = [:] }
        save()
    }

    /// Documents with a photo whose text contains `query` (ignoring case and accents), each with a short
    /// excerpt around the first match.
    func matches(_ query: String) -> [UUID: String] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [:] }
        let texts = lock.withLock { self.texts }
        var matches: [UUID: String] = [:]
        for (key, text) in texts where matches[key.documentID] == nil {
            if let range = text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) {
                matches[key.documentID] = Self.excerpt(of: text, around: range)
            }
        }
        return matches
    }

    /// A line's worth of text around `range`, on one line.
    static func excerpt(of text: String, around range: Range<String.Index>, before: Int = 20, after: Int = 40) -> String {
        let start = text.index(range.lowerBound, offsetBy: -before, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: after, limitedBy: text.endIndex) ?? text.endIndex
        let words = text[start..<end].split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return (start > text.startIndex ? "…" : "") + words + (end < text.endIndex ? "…" : "")
    }

    // MARK: - File

    func save() {
        guard let fileURL else { return }
        let entries = lock.withLock { texts.map { Entry(key: $0.key, text: $0.value) } }
        do {
            var folder = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            // It can be rebuilt from the photos, so it stays out of device backups.
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? folder.setResourceValues(values)
            try JSONEncoder().encode(entries).write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            logger.error("Saving photo text failed: \(String(describing: error), privacy: .public)")
        }
    }

    private struct Entry: Codable {
        let key: Key
        let text: String
    }

    private static func load(from url: URL) -> [Key: String]? {
        guard let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return nil }
        return Dictionary(entries.map { ($0.key, $0.text) }, uniquingKeysWith: { first, _ in first })
    }

    private static var defaultFileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("PhotoText", isDirectory: true)
            .appendingPathComponent("index.json")
    }
}
