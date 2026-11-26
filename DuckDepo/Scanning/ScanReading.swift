//
//  ScanReading.swift
//  DuckDepo
//

import Foundation

/// How sure a scan is of a value it filled in.
enum ScanConfidence: Equatable {
    /// Confirmed by check digits (passport and ID-card zones).
    case verified
    /// Read by a parser that knows the document's layout.
    case read
    /// From the on-device model, or a zone that failed a check: worth a look.
    case suggested
}

/// Everything a scan found, before it becomes a document. The most reliable source fills a field first;
/// later sources only fill what's still empty.
struct ScanReading: Equatable {

    enum Kind: Equatable {
        case passport
        case idCard
        case drivingLicence
        case visa
    }

    struct Value: Equatable {
        let text: String
        let confidence: ScanConfidence
    }

    var kind: Kind?
    /// What the model called the document, when no parser recognized it.
    var modelTitle: String?
    var modelCategory: DocumentType?
    var holderName: Value?
    var values: [FieldKey: Value] = [:]

    var isEmpty: Bool {
        kind == nil && modelTitle == nil && holderName == nil && values.isEmpty
    }

    mutating func fill(_ key: FieldKey, _ text: String?, _ confidence: ScanConfidence) {
        guard values[key] == nil, let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        values[key] = Value(text: text, confidence: confidence)
    }

    private mutating func fillHolder(_ name: String?, _ confidence: ScanConfidence) {
        guard holderName == nil, let name = name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
        holderName = Value(text: name, confidence: confidence)
        fill(.fullName, name, confidence)
    }

    // MARK: - Sources

    mutating func add(_ mrz: MRZ) {
        switch mrz.kind {
        case .passport: kind = kind ?? .passport
        case .idCard: kind = kind ?? .idCard
        case .visa: kind = kind ?? .visa
        case .other: break
        }
        let confidence: ScanConfidence = mrz.isVerified ? .verified : .suggested
        fillHolder(mrz.fullName, confidence)
        fill(.number, mrz.documentNumber, confidence)
        fill(.expiryDate, mrz.expiryDate, confidence)
        fill(.dateOfBirth, mrz.birthDate, confidence)
        fill(.sex, mrz.sex.map(\.rawValue), confidence)
        fill(.nationality, Self.countryName(mrz.nationality), confidence)
    }

    mutating func add(_ licence: DrivingLicenceReading) {
        kind = kind ?? .drivingLicence
        fillHolder(licence.fullName, .read)
        fill(.number, licence.number, .read)
        fill(.issueDate, licence.issueDate, .read)
        fill(.expiryDate, licence.expiryDate, .read)
        fill(.issuedBy, licence.authority, .read)
        fill(.dateOfBirth, licence.birthDate, .read)
        fill(.placeOfBirth, licence.birthPlace, .read)
    }

    mutating func add(vin: String) {
        fill(.vin, vin, .read)
    }

    /// Takes only values that are printed in `text`, so nothing the model made up gets in.
    mutating func add(_ model: ModelReading, text: String) {
        let check = PrintedValueCheck(text: text)
        // The model's title and category are often guesses ("Passport" for an insurance card), so both
        // count only when the title is printed.
        if kind == nil, let title = check.ifPrinted(model.title) {
            modelTitle = title
            modelCategory = model.category?.documentType
        }
        fillHolder(check.ifPrinted(model.holderName), .suggested)
        fill(.number, check.ifPrinted(model.documentNumber), .suggested)
        fill(.issueDate, check.ifPrintedDate(model.issueDate), .suggested)
        fill(.expiryDate, check.ifPrintedDate(model.expiryDate), .suggested)
        fill(.issuedBy, check.ifPrinted(model.issuedBy), .suggested)
        fill(.dateOfBirth, check.ifPrintedDate(model.dateOfBirth), .suggested)
        fill(.placeOfBirth, check.ifPrinted(model.placeOfBirth), .suggested)
        fill(.nationality, check.ifPrinted(model.nationality), .suggested)
        fill(.sex, check.ifPrinted(model.sex), .suggested)
        fill(.licencePlate, check.ifPrinted(model.licencePlate), .suggested)
        fill(.vin, check.ifPrinted(model.vin), .suggested)
        fill(.make, check.ifPrinted(model.make), .suggested)
        fill(.model, check.ifPrinted(model.model), .suggested)
    }

    /// "Netherlands" for "NLD", in the current language. ICAO writes Germany as "D".
    static func countryName(_ code: String) -> String {
        let code = code == "D" ? "DEU" : code
        return Locale.current.localizedString(forRegionCode: code) ?? code
    }
}

private extension ModelReading.Category {
    var documentType: DocumentType {
        switch self {
        case .identification: .identification
        case .transport: .transport
        case .government: .government
        case .work: .work
        case .medicine: .medicine
        case .education: .education
        case .leisure: .leisure
        case .other: .other
        }
    }
}

/// Whether a value appears in the recognized text, ignoring case, accents, spaces and punctuation.
struct PrintedValueCheck {

    private let compact: String
    private let digits: String

    init(text: String) {
        compact = Self.compacted(text)
        digits = text.filter(\.isASCII).filter(\.isNumber)
    }

    /// The value if each of its words is printed.
    func ifPrinted(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        let words = value.split { !$0.isLetter && !$0.isNumber }.map { Self.compacted(String($0)) }.filter { !$0.isEmpty }
        return !words.isEmpty && words.allSatisfy(compact.contains) ? value : nil
    }

    /// A "yyyy-MM-dd" value if it's a real day whose year and day are printed.
    func ifPrintedDate(_ value: String?) -> String? {
        guard let value, let components = FieldDate.components(from: value), FieldDate.storedValue(from: components) == value else { return nil }
        let parts = value.split(separator: "-")
        let year = String(parts[0]), day = String(Int(parts[2])!)
        guard digits.contains(year) || digits.contains(year.suffix(2)), digits.contains(day) else { return nil }
        return value
    }

    private static func compacted(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .filter { $0.isLetter || $0.isNumber }
    }
}
