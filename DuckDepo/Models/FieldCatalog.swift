//
//  FieldCatalog.swift
//  DuckDepo
//

import Foundation

/// A predefined section. The key is stored with the section, so its name shows in the current language
/// whatever language it was added in. Raw values are stored and synced and must not change.
enum SectionKey: String, CaseIterable {
    case documentInfo
    case owner
    case vehicle
    case additional

    var fields: [FieldKey] {
        switch self {
        case .documentInfo: [.number, .issueDate, .issuedBy, .expiryDate]
        case .owner: [.fullName, .sex, .dateOfBirth, .placeOfBirth, .nationality, .phone]
        case .vehicle: [.licencePlate, .vin, .make, .model, .vehicleType, .color, .power]
        case .additional: [.remarks, .notes]
        }
    }

    /// Also the English name the app stored before sections had keys.
    var localizationKey: String {
        switch self {
        case .documentInfo: "Document Info"
        case .owner: "Document Owner"
        case .vehicle: "Vehical Info"
        case .additional: "Additional Info"
        }
    }

    var localizedName: String {
        localizationKey.localized()
    }

    /// Names older versions displayed (and so stored) that are no longer the current translation.
    fileprivate var formerNames: [String] {
        switch self {
        case .vehicle: ["Vehical Info"]
        default: []
        }
    }

    func makeSection() -> DocSection {
        DocSection(key: rawValue, name: localizedName)
    }
}

/// A predefined field. Lets the app find a field (the expiry date for reminders, say) without
/// matching on its name. Raw values are stored and synced and must not change.
enum FieldKey: String, CaseIterable {
    case number
    case issueDate
    case issuedBy
    case expiryDate
    case fullName
    case sex
    case dateOfBirth
    case placeOfBirth
    case nationality
    case phone
    case licencePlate
    case vin
    case make
    case model
    case vehicleType
    case color
    case power
    case remarks
    case notes

    var type: Field.FieldType {
        switch self {
        case .issueDate, .expiryDate, .dateOfBirth: .date
        default: .string
        }
    }

    /// Also the English name the app stored before fields had keys.
    var localizationKey: String {
        switch self {
        case .number: "Number"
        case .issueDate: "Issue Date"
        case .issuedBy: "Issued By"
        case .expiryDate: "Date Of Expiry"
        case .fullName: "Full Name"
        case .sex: "Sex"
        case .dateOfBirth: "Date Of Birth"
        case .placeOfBirth: "Place Of Birth"
        case .nationality: "Nationality"
        case .phone: "Phone"
        case .licencePlate: "Licence Plate"
        case .vin: "Identification Number (VIN)"
        case .make: "Make"
        case .model: "Model"
        case .vehicleType: "Type"
        case .color: "Color"
        case .power: "Power"
        case .remarks: "Remarks"
        case .notes: "Notes"
        }
    }

    var localizedName: String {
        localizationKey.localized()
    }

    /// Names older versions displayed (and so stored) that are no longer the current translation.
    fileprivate var formerNames: [String] {
        switch self {
        case .vin: ["Идентификацилонный номер (VIN)"]
        default: []
        }
    }

    func makeField() -> Field {
        Field(key: rawValue, title: localizedName, type: type)
    }
}

/// Matches names stored before keys existed to their keys.
enum FieldCatalog {

    static func sectionKey(forStoredName name: String) -> SectionKey? {
        sectionLookup[normalized(name)]
    }

    static func fieldKey(forStoredTitle title: String) -> FieldKey? {
        fieldLookup[normalized(title)]
    }

    // Names were stored in whatever language the device used, so match every translation the app ships.
    // Every device running this version builds the same tables, so they all assign the same keys.
    private static let sectionLookup: [String: SectionKey] = lookup(SectionKey.allCases) { ($0.localizationKey, $0.formerNames) }
    private static let fieldLookup: [String: FieldKey] = lookup(FieldKey.allCases) { ($0.localizationKey, $0.formerNames) }

    private static func lookup<Key>(_ keys: [Key], names: (Key) -> (String, [String])) -> [String: Key] {
        let bundles = Bundle.main.localizations.compactMap { localization in
            Bundle.main.path(forResource: localization, ofType: "lproj").flatMap(Bundle.init(path:))
        }
        var table: [String: Key] = [:]
        for key in keys {
            let (localizationKey, formerNames) = names(key)
            var all = [localizationKey] + formerNames
            all += bundles.map { $0.localizedString(forKey: localizationKey, value: localizationKey, table: nil) }
            for name in all where table[normalized(name)] == nil {
                table[normalized(name)] = key
            }
        }
        return table
    }

    private static func normalized(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
