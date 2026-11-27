//
//  CredentialExchange.swift
//  DuckDepo
//

import AuthenticationServices
import CryptoKit
import Foundation

/// Converts between DuckDepo's data and the format iOS uses to move credentials between password
/// managers (FIDO Credential Exchange). Only converts: `CredentialTransfer` reads and saves.
///
/// Passports, ID cards and driving licences go as those types, with every other filled-in section as
/// custom fields labelled in the current language; the document type goes as a tag. Every document
/// also goes as a note, because Passwords keeps nothing else. Photos don't go: the format has no place
/// for them.
enum CredentialExchange {

    static let exporterName = "DuckDepo"

    // MARK: - Export

    static func exportedData(passwords: [Password], passkeys: [Passkey], documents: [Document],
                             formatVersion: ASExportedCredentialData.FormatVersion,
                             now: Date = .now) -> ASExportedCredentialData {
        let items = passwords.map { item(for: $0, now: now) }
            + passkeys.compactMap(item(for:))
            + documents.map { item(for: $0, now: now) }
        let account = ASImportableAccount(id: UUID().data, userName: "", email: "", collections: [], items: items)
        return ASExportedCredentialData(accounts: [account], formatVersion: formatVersion,
                                        exporterRelyingPartyIdentifier: Bundle.main.bundleIdentifier ?? exporterName,
                                        exporterDisplayName: exporterName, timestamp: now)
    }

    static func item(for password: Password, now: Date) -> ASImportableItem {
        var credentials: [ASImportableCredential] = [
            .basicAuthentication(.init(userName: field(password.login), password: field(password.value, .concealedString))),
        ]
        if let code = OneTimeCode(text: password.oneTimeCode) {
            credentials.append(.totp(.init(secret: code.secret, period: UInt16(clamping: code.period),
                                           digits: UInt16(clamping: code.digits), userName: code.account,
                                           algorithm: code.algorithm.exchangeAlgorithm, issuer: code.issuer)))
        }
        let title = password.name.isEmpty ? (DomainMatcher.host(from: password.website) ?? password.login) : password.name
        return ASImportableItem(id: password.id.data, created: now, lastModified: now, title: title,
                                scope: scope(for: password), credentials: credentials)
    }

    /// Only a website that names a real host: Passwords refuses the whole item for one like "gi". An item
    /// without a website keeps its login, password and code there.
    private static func scope(for password: Password) -> ASImportableCredentialScope? {
        guard let url = password.websiteURL, let host = url.host(), host.contains(".") else { return nil }
        return ASImportableCredentialScope(urls: [url])
    }

    static func item(for passkey: Passkey) -> ASImportableItem? {
        guard let key = passkey.signingKey else { return nil }
        let credential = ASImportableCredential.Passkey(credentialID: passkey.credentialID,
                                                        relyingPartyIdentifier: passkey.relyingParty,
                                                        userName: passkey.userName, userDisplayName: passkey.userName,
                                                        userHandle: passkey.userHandle, key: key.derRepresentation)
        return ASImportableItem(id: passkey.id.data, created: passkey.createdAt, lastModified: passkey.createdAt,
                                title: passkey.relyingParty,
                                scope: URL(string: "https://" + passkey.relyingParty).map { ASImportableCredentialScope(urls: [$0]) },
                                credentials: [.passkey(credential)])
    }

    static func item(for document: Document, now: Date) -> ASImportableItem {
        var sections = document.sectionsWithValues
        var credentials: [ASImportableCredential] = []
        switch Kind(document) {
        case .passport:
            credentials.append(.passport(.init(
                issuingCountry: nil, passportType: nil,
                passportNumber: take(.number, from: &sections),
                nationalIdentificationNumber: nil,
                nationality: take(.nationality, from: &sections),
                fullName: take(.fullName, from: &sections),
                birthDate: take(.dateOfBirth, from: &sections),
                birthPlace: take(.placeOfBirth, from: &sections),
                sex: take(.sex, from: &sections),
                issueDate: take(.issueDate, from: &sections),
                expiryDate: take(.expiryDate, from: &sections),
                issuingAuthority: take(.issuedBy, from: &sections))))
        case .idCard:
            credentials.append(.identityDocument(.init(
                issuingCountry: nil,
                documentNumber: take(.number, from: &sections),
                identificationNumber: nil,
                nationality: take(.nationality, from: &sections),
                fullName: take(.fullName, from: &sections),
                birthDate: take(.dateOfBirth, from: &sections),
                birthPlace: take(.placeOfBirth, from: &sections),
                sex: take(.sex, from: &sections),
                issueDate: take(.issueDate, from: &sections),
                expiryDate: take(.expiryDate, from: &sections),
                issuingAuthority: take(.issuedBy, from: &sections))))
        case .drivingLicence:
            credentials.append(.driversLicense(.init(
                fullName: take(.fullName, from: &sections),
                birthDate: take(.dateOfBirth, from: &sections),
                issueDate: take(.issueDate, from: &sections),
                expiryDate: take(.expiryDate, from: &sections),
                issuingAuthority: take(.issuedBy, from: &sections),
                territory: nil, country: nil,
                licenseNumber: take(.number, from: &sections),
                licenseClass: nil)))
        case .other:
            break
        }
        // With their own IDs, so two sections with the same name stay apart.
        credentials += sections.filter { !$0.fields.isEmpty }.map { section in
            .customFields(.init(id: section.id.data, label: section.displayName,
                                fields: section.fields.map { exchangeField(for: $0, labelled: true) }))
        }
        // Also what keeps a document that has only photos from arriving with nothing in it.
        credentials.append(.note(.init(content: ASImportableEditableField(id: nil, fieldType: .string,
                                                                           value: summary(of: document)))))
        return ASImportableItem(id: document.id.data, created: document.createdAt ?? now,
                                lastModified: document.updatedAt ?? now, title: document.name,
                                subtitle: document.description.isEmpty ? nil : document.description,
                                credentials: credentials, tags: [document.documentType.localizedName])
    }

    /// The document as text, as it shows in DuckDepo: the description, each section's name with its
    /// "Title: value" lines, and a last line saying it came from DuckDepo, by which DuckDepo knows its
    /// own note when the document comes back.
    static func summary(of document: Document) -> String {
        var blocks = [document.description].filter { !$0.isEmpty }
        for section in document.sectionsWithValues {
            let lines = [section.displayName] + section.fields.map { "\($0.displayTitle): \($0.displayValue)" }
            blocks.append(lines.joined(separator: "\n"))
        }
        blocks.append(noteFooterKey.localized())
        return blocks.joined(separator: "\n\n")
    }

    private static let noteFooterKey = "cx_note_footer"

    /// Whether DuckDepo wrote this note (in any language it ships), and the note without that last line.
    static func ownNoteContent(_ note: String) -> String? {
        var lines = note.components(separatedBy: .newlines)
        while let last = lines.last, last.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.removeLast()
        }
        guard let last = lines.last?.trimmingCharacters(in: .whitespaces),
              FieldCatalog.translations(of: noteFooterKey).contains(last) else { return nil }
        lines.removeLast()
        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Which typed credential a document goes as. DuckDepo doesn't store this, so it's read from the
    /// document's type and name (the scanner names documents "Passport", "Driving Licence" and so on).
    enum Kind {
        case passport, idCard, drivingLicence, other

        init(_ document: Document) {
            let name = document.name.lowercased()
            switch document.documentType {
            case .identification:
                self = ["passport", "паспорт"].contains(where: name.contains) ? .passport : .idCard
            case .transport:
                self = ["licence", "license", "водительск", "права"].contains(where: name.contains) ? .drivingLicence : .other
            default:
                self = .other
            }
        }
    }

    /// Removes the first filled-in field with this key from a predefined section, its own first, and
    /// returns it. Custom sections keep theirs: a visa section's "Number" isn't the passport's.
    private static func take(_ key: FieldKey, from sections: inout [DocSection]) -> ASImportableEditableField? {
        let own = sections.indices.filter { sections[$0].sectionKey?.fields.contains(key) == true }
        let otherPredefined = sections.indices.filter { sections[$0].sectionKey != nil && !own.contains($0) }
        for index in own + otherPredefined {
            if let fieldIndex = sections[index].fields.firstIndex(where: { $0.fieldKey == key }) {
                return exchangeField(for: sections[index].fields.remove(at: fieldIndex), labelled: false)
            }
        }
        return nil
    }

    private static func exchangeField(for field: Field, labelled: Bool) -> ASImportableEditableField {
        let label = labelled ? field.displayTitle : nil
        if field.type == .date, let day = storedDay(field.value) {
            return ASImportableEditableField(id: nil, fieldType: .date, value: day, label: label)
        }
        return ASImportableEditableField(id: nil, fieldType: field.isSensitive ? .concealedString : .string,
                                         value: field.value, label: label)
    }

    private static func field(_ value: String, _ type: ASImportableEditableField.FieldType = .string) -> ASImportableEditableField? {
        value.isEmpty ? nil : ASImportableEditableField(id: nil, fieldType: type, value: value)
    }

    /// A day as DuckDepo stores it and the format expects ("yyyy-MM-dd", zero-padded), from that or an
    /// older format like "15.03.2020". Nil when it isn't a day.
    static func storedDay(_ text: String) -> String? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = FieldDate.components(from: text) ?? FieldDate.parseLegacy(text).flatMap(FieldDate.components(from:))
        return components.flatMap(FieldDate.storedValue(from:))
    }
}

// MARK: - Import

/// What another app sent, as DuckDepo items, before leaving out what's already saved.
struct CredentialImport {
    let source: String
    var passwords: [Password] = []
    var passkeys: [Passkey] = []
    var documents: [Document] = []
    /// Credentials DuckDepo has no place for: bank cards, Wi-Fi networks, SSH and API keys, addresses.
    /// What came with them stays with them.
    var unsupportedCount = 0
    /// Notes and extra fields on passwords, which DuckDepo passwords don't have.
    var droppedNoteCount = 0

    init(_ data: ASExportedCredentialData, now: Date = .now) {
        source = data.exporterDisplayName
        for item in data.accounts.flatMap(\.items) {
            add(item, now: now)
        }
    }

    private mutating func add(_ item: ASImportableItem, now: Date) {
        var logins: [ASImportableCredential.BasicAuthentication] = []
        var codes: [OneTimeCode] = []
        var keys: [ASImportableCredential.Passkey] = []
        var typedParts: [ASImportableCredential] = []
        var customParts: [ASImportableCredential.CustomFields] = []
        var notes: [String] = []
        var hasUnsupported = false
        for credential in item.credentials {
            switch credential {
            case .basicAuthentication(let login):
                // Passwords sends its note-only items with an empty login.
                if !(login.userName?.value ?? "").isEmpty || !(login.password?.value ?? "").isEmpty {
                    logins.append(login)
                }
            case .totp(let totp):
                if let code = OneTimeCode(totp) {
                    codes.append(code)
                } else {
                    unsupportedCount += 1
                }
            case .passkey(let passkey):
                keys.append(passkey)
            case .passport, .identityDocument, .driversLicense:
                typedParts.append(credential)
            case .customFields(let custom):
                customParts.append(custom)
            case .note(let note):
                notes.append(note.content.value)
            default:
                unsupportedCount += 1
                hasUnsupported = true
            }
        }

        let website = Self.website(of: item.scope)
        let title = item.title.isEmpty ? Self.fallbackTitle(website: website, scope: item.scope) : item.title
        // A code goes with the login it names, then with the first login left.
        var unpaired = codes
        var paired = [OneTimeCode?](repeating: nil, count: logins.count)
        for (index, login) in logins.enumerated() {
            let user = (login.userName?.value ?? "").lowercased()
            if !user.isEmpty, let match = unpaired.firstIndex(where: { $0.account?.lowercased() == user }) {
                paired[index] = unpaired.remove(at: match)
            }
        }
        for index in paired.indices where paired[index] == nil && !unpaired.isEmpty {
            paired[index] = unpaired.removeFirst()
        }
        for (index, login) in logins.enumerated() {
            passwords.append(Password(name: title, login: login.userName?.value ?? "",
                                      value: login.password?.value ?? "", website: website,
                                      oneTimeCode: paired[index]?.uri ?? ""))
        }
        for code in unpaired {
            passwords.append(Password(name: title.isEmpty ? (code.issuer ?? "") : title, login: code.account ?? "",
                                      website: website, oneTimeCode: code.uri))
        }
        for key in keys {
            guard let privateKey = try? P256.Signing.PrivateKey(derRepresentation: key.key) else {
                // Only P-256 keys can be used here; DuckDepo signs with ES256.
                unsupportedCount += 1
                continue
            }
            passkeys.append(Passkey(id: UUID(), credentialID: key.credentialID, relyingParty: key.relyingPartyIdentifier,
                                    userName: key.userName.isEmpty ? key.userDisplayName : key.userName,
                                    userHandle: key.userHandle, privateKey: privateKey.rawRepresentation,
                                    createdAt: item.created ?? now))
        }

        let meaningfulNotes = notes.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let isLogin = !logins.isEmpty || !codes.isEmpty || !keys.isEmpty
        if !typedParts.isEmpty {
            documents += DocumentDraft.documents(from: item, typed: typedParts, custom: customParts, notes: meaningfulNotes)
        } else if hasUnsupported {
            // A card's or network's notes and fields stay with it in the other app; it's counted.
        } else if isLogin {
            droppedNoteCount += meaningfulNotes.count + customParts.count
        } else if !customParts.isEmpty || !notes.isEmpty || (item.credentials.isEmpty && !item.title.isEmpty) {
            documents += DocumentDraft.documents(from: item, typed: [], custom: customParts, notes: meaningfulNotes)
        }
    }

    /// The first address that names a host. An item can have several; a DuckDepo password has one.
    static func website(of scope: ASImportableCredentialScope?) -> String {
        guard let urls = scope?.urls, let url = urls.first(where: { $0.host() != nil }) ?? urls.first else { return "" }
        return website(from: url)
    }

    /// The site as people type it: "https://example.com" rather than "https://example.com/".
    static func website(from url: URL) -> String {
        var text = url.absoluteString
        if url.path.isEmpty || url.path == "/", url.query == nil, text.hasSuffix("/") {
            text.removeLast()
        }
        return text
    }

    /// For an item without a title: its site, or the Android app it's for.
    private static func fallbackTitle(website: String, scope: ASImportableCredentialScope?) -> String {
        DomainMatcher.host(from: website) ?? scope?.androidApps.first.map { $0.name ?? $0.bundleID } ?? ""
    }
}

/// Builds a document from typed credentials and custom fields, filling predefined fields where it can.
private struct DocumentDraft {

    private var sections: [DocSection] = []
    /// Sections made for a group of custom fields, which later groups don't join.
    private var groupSections = Set<Int>()

    /// One document per typed credential, so an identity that holds a passport and a licence doesn't
    /// mix their numbers and dates. The custom fields and notes go with the first.
    static func documents(from item: ASImportableItem, typed: [ASImportableCredential],
                          custom: [ASImportableCredential.CustomFields], notes: [String]) -> [Document] {
        guard typed.count > 1 else {
            return [document(from: item, typed: typed.first, custom: custom, notes: notes, isOneOfSeveral: false)]
        }
        return typed.enumerated().map { index, part in
            document(from: item, typed: part, custom: index == 0 ? custom : [], notes: index == 0 ? notes : [],
                     isOneOfSeveral: true)
        }
    }

    private static func document(from item: ASImportableItem, typed: ASImportableCredential?,
                                 custom: [ASImportableCredential.CustomFields], notes: [String],
                                 isOneOfSeveral: Bool) -> Document {
        var draft = DocumentDraft()
        var typedType: DocumentType?
        var kindName = ""
        switch typed {
        case .passport(let passport):
            typedType = .identification
            kindName = "scan_kind_passport".localized()
            draft.set(.number, passport.passportNumber)
            draft.set(.issueDate, passport.issueDate)
            draft.set(.issuedBy, passport.issuingAuthority)
            draft.set(.expiryDate, passport.expiryDate)
            draft.setOwner(fullName: passport.fullName, sex: passport.sex, birthDate: passport.birthDate,
                           birthPlace: passport.birthPlace, nationality: passport.nationality)
            draft.addExtra("cx_issuing_country", passport.issuingCountry)
            draft.addExtra("cx_passport_type", passport.passportType)
            draft.addExtra("cx_personal_number", passport.nationalIdentificationNumber)
        case .identityDocument(let card):
            typedType = .identification
            kindName = "scan_kind_id_card".localized()
            draft.set(.number, card.documentNumber)
            draft.set(.issueDate, card.issueDate)
            draft.set(.issuedBy, card.issuingAuthority)
            draft.set(.expiryDate, card.expiryDate)
            draft.setOwner(fullName: card.fullName, sex: card.sex, birthDate: card.birthDate,
                           birthPlace: card.birthPlace, nationality: card.nationality)
            draft.addExtra("cx_issuing_country", card.issuingCountry)
            draft.addExtra("cx_personal_number", card.identificationNumber)
        case .driversLicense(let licence):
            typedType = .transport
            kindName = "scan_kind_driving_licence".localized()
            draft.set(.number, licence.licenseNumber)
            draft.set(.issueDate, licence.issueDate)
            draft.set(.issuedBy, licence.issuingAuthority)
            draft.set(.expiryDate, licence.expiryDate)
            draft.set(.fullName, licence.fullName)
            draft.set(.dateOfBirth, licence.birthDate)
            draft.addExtra("cx_licence_class", licence.licenseClass)
            draft.addExtra("cx_issuing_country", licence.country)
            draft.addExtra("cx_region", licence.territory)
        default:
            break
        }
        for group in custom {
            draft.add(group)
        }

        // DuckDepo's own note repeats the fields. It's the data only when nothing else came, as from
        // Passwords, which keeps nothing else.
        let hasFields = typed != nil || !custom.isEmpty
        let texts = notes.compactMap { note -> String? in
            guard let own = CredentialExchange.ownNoteContent(note) else {
                return note.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return hasFields || own.isEmpty ? nil : own
        }
        if !texts.isEmpty {
            draft.set(.notes, ASImportableEditableField(id: nil, fieldType: .string, value: texts.joined(separator: "\n\n")))
        }

        // A typed document is what it says; DuckDepo's tag tells the type of the others.
        let type = typedType ?? item.tags.lazy.compactMap(Self.documentType(forTag:)).first ?? .other
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = if title.isEmpty { kindName } else if isOneOfSeveral && !kindName.isEmpty { "\(title) – \(kindName)" } else { title }
        return Document(name: name, description: item.subtitle ?? "", documentType: type,
                        sections: draft.sections.filter(\.hasValues))
    }

    /// DuckDepo exports the type's name as a tag; it's matched in every language the app ships.
    private static func documentType(forTag tag: String) -> DocumentType? {
        let tag = FieldCatalog.normalized(tag)
        return DocumentType.allCases.first { type in
            FieldCatalog.translations(of: "doc_type_" + type.rawValue).contains { FieldCatalog.normalized($0) == tag }
        }
    }

    private mutating func setOwner(fullName: ASImportableEditableField?, sex: ASImportableEditableField?,
                                   birthDate: ASImportableEditableField?, birthPlace: ASImportableEditableField?,
                                   nationality: ASImportableEditableField?) {
        set(.fullName, fullName)
        set(.sex, sex)
        set(.dateOfBirth, birthDate)
        set(.placeOfBirth, birthPlace)
        set(.nationality, nationality)
    }

    /// Fills the predefined field in its usual section.
    private mutating func set(_ key: FieldKey, _ field: ASImportableEditableField?) {
        guard let value = field.flatMap(Self.value(of:)) else { return }
        let sectionKey = SectionKey.allCases.first { $0.fields.contains(key) } ?? .additional
        put(key: key, title: key.localizedName, value: value, isDate: false, in: sectionIndex(for: sectionKey))
    }

    /// A detail DuckDepo has no field for, kept as a custom field of the document's info.
    private mutating func addExtra(_ titleKey: String, _ field: ASImportableEditableField?) {
        guard let field, let value = Self.value(of: field) else { return }
        put(key: nil, title: titleKey.localized(), value: value, isDate: field.fieldType == .date,
            in: sectionIndex(for: .documentInfo))
    }

    /// A group of custom fields becomes a section of its own, named by its label. A label that names a
    /// predefined section (DuckDepo labels its groups with section names) fills the one a typed
    /// credential started. Fields whose label is a predefined field's name become that field.
    private mutating func add(_ group: ASImportableCredential.CustomFields) {
        let label = group.label?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let key = label.isEmpty ? SectionKey.additional : FieldCatalog.sectionKey(forStoredName: label)
        let index: Int
        if let key, let existing = sections.firstIndex(where: { $0.sectionKey == key }), !groupSections.contains(existing) {
            index = existing
        } else {
            sections.append(key?.makeSection() ?? DocSection(name: label))
            index = sections.count - 1
        }
        groupSections.insert(index)
        for field in group.fields {
            guard let value = Self.value(of: field) else { continue }
            let title = field.label ?? ""
            put(key: FieldCatalog.fieldKey(forStoredTitle: title), title: title, value: value,
                isDate: field.fieldType == .date, in: index)
        }
    }

    /// Fills an empty predefined field or adds one. Days are stored as DuckDepo stores them; a value
    /// under a date field that isn't a day stays text in a custom field.
    private mutating func put(key: FieldKey?, title: String, value: String, isDate: Bool, in index: Int) {
        if let key {
            var value = value
            if key.type == .date {
                guard let day = CredentialExchange.storedDay(value) else {
                    sections[index].fields.append(Field(title: title, value: value))
                    return
                }
                value = day
            }
            if let fieldIndex = sections[index].fields.firstIndex(where: { $0.fieldKey == key && $0.value.isEmpty }) {
                sections[index].fields[fieldIndex].value = value
            } else {
                var field = key.makeField()
                field.value = value
                sections[index].fields.append(field)
            }
        } else if isDate, let day = CredentialExchange.storedDay(value) {
            sections[index].fields.append(Field(title: title, value: day, type: .date))
        } else {
            sections[index].fields.append(Field(title: title, value: value))
        }
    }

    private mutating func sectionIndex(for key: SectionKey) -> Int {
        if let index = sections.firstIndex(where: { $0.sectionKey == key }) {
            return index
        }
        sections.append(key.makeSection())
        return sections.count - 1
    }

    /// The value as DuckDepo shows it: country codes become names. Nil when empty.
    private static func value(of field: ASImportableEditableField) -> String? {
        let value = field.value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if field.fieldType == .countryCode {
            return Locale.current.localizedString(forRegionCode: value) ?? value
        }
        return value
    }
}

// MARK: - Plan

/// What an import will add, once what's already in DuckDepo is left out.
struct ImportPlan: Identifiable {
    let id = UUID()
    let source: String
    var passwords: [Password] = []
    /// Codes for saved passwords that are the same account and password and have no code yet.
    var codesForSaved: [UUID: String] = [:]
    var passkeys: [Passkey] = []
    var documents: [Document] = []
    var alreadySavedCount = 0
    var unsupportedCount = 0
    var droppedNoteCount = 0

    var codeCount: Int {
        passwords.filter { !$0.oneTimeCode.isEmpty }.count + codesForSaved.count
    }

    var isEmpty: Bool {
        passwords.isEmpty && codesForSaved.isEmpty && passkeys.isEmpty && documents.isEmpty
    }

    /// The same account: the same site and login, or without a site, the same name and login.
    private struct Account: Hashable {
        let site: String
        let name: String
        let login: String

        init(_ password: Password) {
            site = DomainMatcher.host(from: password.website) ?? password.website.trimmingCharacters(in: .whitespaces).lowercased()
            name = site.isEmpty ? FieldCatalog.normalized(password.name) : ""
            login = FieldCatalog.normalized(password.login)
        }
    }

    private struct Known {
        let id: UUID
        let isSaved: Bool
        /// Nil for a saved password whose value hasn't reached this device's keychain yet.
        var value: String?
        var code: String
    }

    /// `savedSecrets` reads a saved password's value (nil if the keychain doesn't have it yet) and code.
    /// It's only asked about accounts that match an incoming one, so a large import doesn't read the
    /// whole keychain.
    init(_ incoming: CredentialImport, savedPasswords: [Password], savedSecrets: (UUID) -> (value: String?, code: String),
         savedPasskeyIDs: Set<Data>, savedDocuments: [Document]) {
        source = incoming.source
        unsupportedCount = incoming.unsupportedCount
        droppedNoteCount = incoming.droppedNoteCount

        var known: [Account: [Known]] = [:]
        var isRead = Set<Account>()
        for password in savedPasswords {
            known[Account(password), default: []].append(Known(id: password.id, isSaved: true, value: nil, code: ""))
        }
        for password in incoming.passwords {
            let account = Account(password)
            if !isRead.contains(account) {
                isRead.insert(account)
                for index in (known[account] ?? []).indices where known[account]![index].isSaved {
                    let secrets = savedSecrets(known[account]![index].id)
                    known[account]![index].value = secrets.value
                    known[account]![index].code = secrets.code
                }
            }
            // A saved value that hasn't synced here yet can't be compared; the account is taken as saved
            // rather than added twice. Different codes are different setups: both are kept.
            let match = known[account]?.firstIndex { known in
                (known.value == nil || known.value == password.value) && Self.codesAgree(known.code, password.oneTimeCode)
            }
            guard let index = match else {
                known[account, default: []].append(Known(id: password.id, isSaved: false, value: password.value,
                                                         code: password.oneTimeCode))
                passwords.append(password)
                continue
            }
            let existing = known[account]![index]
            if existing.code.isEmpty, !password.oneTimeCode.isEmpty {
                known[account]![index].code = password.oneTimeCode
                if existing.isSaved {
                    codesForSaved[existing.id] = password.oneTimeCode
                } else if let new = passwords.firstIndex(where: { $0.id == existing.id }) {
                    passwords[new].oneTimeCode = password.oneTimeCode
                }
            } else {
                alreadySavedCount += 1
            }
        }

        var passkeyIDs = savedPasskeyIDs
        for passkey in incoming.passkeys {
            if passkeyIDs.insert(passkey.credentialID).inserted {
                passkeys.append(passkey)
            } else {
                alreadySavedCount += 1
            }
        }

        var signatures = Set(savedDocuments.map(Self.signature(of:)))
        for document in incoming.documents {
            if signatures.insert(Self.signature(of: document)).inserted {
                documents.append(document)
            } else {
                alreadySavedCount += 1
            }
        }
    }

    /// Either is empty, or both make the same codes.
    private static func codesAgree(_ lhs: String, _ rhs: String) -> Bool {
        guard !lhs.isEmpty, !rhs.isEmpty else { return true }
        if let left = OneTimeCode(text: lhs), let right = OneTimeCode(text: rhs) {
            return left.secret == right.secret
        }
        return lhs == rhs
    }

    /// Same type, name, description and filled-in fields (by key, or title), wherever they are. Days
    /// are compared as stored, and titles by the field they name, so a later migration of the saved
    /// copy doesn't make it look different.
    private static func signature(of document: Document) -> [String] {
        let fields = document.sections.flatMap(\.fields).filter { !$0.value.isEmpty }.map { field in
            let name = field.key ?? FieldCatalog.fieldKey(forStoredTitle: field.title)?.rawValue
                ?? FieldCatalog.normalized(field.title)
            let value = CredentialExchange.storedDay(field.value) ?? field.value.trimmingCharacters(in: .whitespacesAndNewlines)
            return name + "=" + value
        }
        return [document.documentType.rawValue, FieldCatalog.normalized(document.name),
                FieldCatalog.normalized(document.description)] + fields.sorted()
    }
}

// MARK: - Helpers

extension UUID {
    /// The 16 bytes, as Credential Exchange identifies items.
    var data: Data {
        withUnsafeBytes(of: uuid) { Data($0) }
    }
}

extension OneTimeCode {
    init?(_ totp: ASImportableCredential.TOTP) {
        let digits = Int(totp.digits)
        let period = Int(totp.period)
        guard !totp.secret.isEmpty, (6...8).contains(digits), period > 0 else { return nil }
        let algorithm: Algorithm = switch totp.algorithm {
        case .sha256: .sha256
        case .sha512: .sha512
        default: .sha1
        }
        self.init(secret: totp.secret, algorithm: algorithm, digits: digits, period: period,
                  issuer: totp.issuer.flatMap { $0.isEmpty ? nil : $0 },
                  account: totp.userName.flatMap { $0.isEmpty ? nil : $0 })
    }
}

extension OneTimeCode.Algorithm {
    var exchangeAlgorithm: ASImportableCredential.TOTP.Algorithm {
        switch self {
        case .sha1: .sha1
        case .sha256: .sha256
        case .sha512: .sha512
        }
    }
}
