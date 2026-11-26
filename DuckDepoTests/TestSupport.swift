//
//  TestSupport.swift
//  DuckDepoTests
//

import CoreData
import Foundation
import UIKit
@testable import DuckDepo

/// Keychain stand-in. `failWrites` simulates a keychain error.
final class InMemoryKeychain: KeychainStoring {
    var items: [String: String] = [:]
    var failWrites = false

    func string(forKey key: String) -> String? {
        items[key]
    }

    @discardableResult
    func set(_ value: String, forKey key: String) -> Bool {
        guard !failWrites else { return false }
        items[key] = value
        return true
    }

    @discardableResult
    func delete(_ key: String) -> Bool {
        items.removeValue(forKey: key) != nil
    }

    @discardableResult
    func clear() -> Bool {
        items.removeAll()
        return true
    }
}

/// Deterministic random numbers (SplitMix64) so randomized tests are reproducible.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum TestStack {
    static func makeDatabase() -> DataBase {
        let persistence = PersistenceController(role: .inMemory)
        precondition(persistence.isLoaded, "in-memory store failed to load: \(String(describing: persistence.loadError))")
        return DataBase(persistenceController: persistence)
    }

    static func makeDefaults() -> UserDefaults {
        let name = "DuckDepoTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}

extension DocumentPhoto {
    /// A small solid-color photo. Photos are identified by their bytes, so use different colors for different photos.
    static func sample(width: Int = 40, height: Int = 30, color: UIColor = .systemYellow) -> DocumentPhoto {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return DocumentPhoto(image: image)!
    }
}

extension DDDocument {
    /// What version 2.6 writes: photos only as an archived array in `photoData`.
    func setPhotosLikeVersion26(_ photos: [DocumentPhoto]) {
        photoData = photos.isEmpty ? nil : try? NSKeyedArchiver.archivedData(
            withRootObject: photos.map { $0.data as NSData } as NSArray, requiringSecureCoding: true)
    }
}
