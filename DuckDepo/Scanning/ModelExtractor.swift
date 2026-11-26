//
//  ModelExtractor.swift
//  DuckDepo
//

import Foundation
import FoundationModels

/// Fields Apple's on-device language model found in a document's text. Nil for anything it didn't find:
/// with every field required, it made values up to fill them.
@Generable
struct ModelReading: Equatable {

    @Generable
    enum Category: Equatable {
        case identification
        case transport
        case government
        case work
        case medicine
        case education
        case leisure
        case other
    }

    @Guide(description: "What the document is, in two or three words, for example Passport, Health Insurance Card, Vehicle Registration, Residence Permit")
    var title: String?
    @Guide(description: "The category the document belongs to")
    var category: Category?
    @Guide(description: "Full name of the person the document belongs to, as printed")
    var holderName: String?
    @Guide(description: "The document, card, policy or licence number")
    var documentNumber: String?
    @Guide(description: "Date of issue as yyyy-MM-dd")
    var issueDate: String?
    @Guide(description: "Expiry or valid-until date as yyyy-MM-dd")
    var expiryDate: String?
    @Guide(description: "The authority, organisation or company that issued the document")
    var issuedBy: String?
    @Guide(description: "The holder's date of birth as yyyy-MM-dd")
    var dateOfBirth: String?
    @Guide(description: "The holder's place of birth")
    var placeOfBirth: String?
    @Guide(description: "The holder's nationality")
    var nationality: String?
    @Guide(description: "The holder's sex as printed")
    var sex: String?
    @Guide(description: "Vehicle registration plate")
    var licencePlate: String?
    @Guide(description: "Vehicle identification number (VIN)")
    var vin: String?
    @Guide(description: "Vehicle make")
    var make: String?
    @Guide(description: "Vehicle model")
    var model: String?
}

/// Asks the on-device model for a document's fields. Nothing leaves the device: this uses only
/// `SystemLanguageModel`, never a server model.
enum ModelExtractor {

    /// Longer than this and the scan goes on without the model: its suggestions aren't worth the wait.
    static let timeLimit: Duration = .seconds(6)

    private static let preparedSession = PreparedSession()

    static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// Loads the model while the user picks pages; loading is most of the first answer's time.
    static func prewarm() {
        guard isAvailable else { return }
        Task {
            await preparedSession.prepare()
        }
    }

    /// Nil when the model is unavailable, the text is in a language it doesn't support, it fails, or it
    /// takes longer than `timeLimit`.
    static func extract(from text: String) async -> ModelReading? {
        let text = String(text.prefix(3000))
        guard isAvailable, !text.isEmpty, !isMostlyCyrillic(text) else { return nil }
        let session = await preparedSession.take()
        // Not a task group: that waits for the model even after the time is up.
        return await withCheckedContinuation { continuation in
            let answer = FirstAnswer(continuation)
            let work = Task {
                let reading = try? await session.respond(to: "Document text:\n\(text)", generating: ModelReading.self,
                                                         options: GenerationOptions(sampling: .greedy)).content
                answer.give(reading)
            }
            Task {
                try? await Task.sleep(for: timeLimit)
                work.cancel()
                answer.give(nil)
            }
        }
    }

    /// The model doesn't support Russian; Latin text on the same document is read by the parsers.
    static func isMostlyCyrillic(_ text: String) -> Bool {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        let cyrillic = letters.filter { (0x0400...0x04FF).contains($0.value) }
        return !letters.isEmpty && cyrillic.count * 3 > letters.count
    }
}

/// Resumes with whichever answer comes first and ignores the rest.
private final class FirstAnswer: @unchecked Sendable {

    private let lock = NSLock()
    private var continuation: CheckedContinuation<ModelReading?, Never>?

    init(_ continuation: CheckedContinuation<ModelReading?, Never>) {
        self.continuation = continuation
    }

    func give(_ reading: ModelReading?) {
        lock.lock()
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: reading)
    }
}

/// One session, prewarmed ahead of use. Each scan takes a fresh one.
private actor PreparedSession {

    private var session: LanguageModelSession?

    func prepare() {
        guard session == nil else { return }
        let session = Self.makeSession()
        session.prewarm()
        self.session = session
    }

    func take() -> LanguageModelSession {
        defer { session = nil }
        return session ?? Self.makeSession()
    }

    private static func makeSession() -> LanguageModelSession {
        LanguageModelSession(instructions: """
            You read text recognized from a photo of a personal document, such as a passport, ID card, \
            driving licence, insurance card or vehicle registration. Fill in each field only with a value \
            printed in the text. Leave out any field that isn't printed; never guess or use an example. \
            Write dates as yyyy-MM-dd.
            """)
    }
}
