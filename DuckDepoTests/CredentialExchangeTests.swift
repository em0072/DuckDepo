//
//  CredentialExchangeTests.swift
//  DuckDepoTests
//

import AuthenticationServices
import CryptoKit
import Foundation
import Testing
@testable import DuckDepo

/// Through JSON, as the data goes between apps.
private func transferred(passwords: [Password] = [], passkeys: [Passkey] = [], documents: [Document] = []) throws -> CredentialImport {
    let data = CredentialExchange.exportedData(passwords: passwords, passkeys: passkeys, documents: documents, formatVersion: .v1)
    let json = try JSONEncoder().encode(data)
    return CredentialImport(try JSONDecoder().decode(ASExportedCredentialData.self, from: json))
}

private func field(_ value: String, _ type: ASImportableEditableField.FieldType = .string,
                   label: String? = nil) -> ASImportableEditableField {
    ASImportableEditableField(id: nil, fieldType: type, value: value, label: label)
}

private func exported(_ items: [ASImportableItem], from source: String = "Other") -> ASExportedCredentialData {
    ASExportedCredentialData(accounts: [ASImportableAccount(id: Data([1]), userName: "", email: "", collections: [], items: items)],
                             formatVersion: .v1, exporterRelyingPartyIdentifier: "other.example",
                             exporterDisplayName: source, timestamp: .now)
}

private func item(_ title: String, url: String? = nil, tags: [String] = [], _ credentials: [ASImportableCredential]) -> ASImportableItem {
    ASImportableItem(id: UUID().data, created: .now, lastModified: .now, title: title,
                     scope: url.flatMap(URL.init(string:)).map { ASImportableCredentialScope(urls: [$0]) },
                     credentials: credentials, tags: tags)
}

private extension Document {
    func value(of key: FieldKey) -> String? {
        sections.flatMap(\.fields).first { $0.fieldKey == key }?.value
    }
}

struct CredentialExchangeTests {

    private let code = "otpauth://totp/GitHub:octo?secret=JBSWY3DPEHPK3PXPJBSWY3DP&issuer=GitHub&digits=6&period=30&algorithm=SHA1"

    @Test func passwordsComeBackAsTheyWere() throws {
        let password = Password(name: "GitHub", login: "octo", value: "s3cret!", website: "https://github.com", oneTimeCode: code)
        let plain = Password(name: "", login: "me@example.com", value: "pw", website: "example.com")
        let incoming = try transferred(passwords: [password, plain])
        #expect(incoming.passwords.count == 2)
        let first = try #require(incoming.passwords.first)
        #expect(first.name == "GitHub")
        #expect(first.login == "octo")
        #expect(first.value == "s3cret!")
        #expect(first.website == "https://github.com")
        #expect(OneTimeCode(text: first.oneTimeCode) == OneTimeCode(text: code))
        let second = try #require(incoming.passwords.last)
        #expect(second.name == "example.com")
        #expect(second.website == "https://example.com")
        #expect(second.oneTimeCode.isEmpty)
        #expect(incoming.unsupportedCount == 0 && incoming.droppedNoteCount == 0)
    }

    @Test func passkeysKeepTheirKey() throws {
        let passkey = Passkey.make(relyingParty: "webauthn.io", userName: "duck", userHandle: Data([7, 8, 9]))
        let incoming = try transferred(passkeys: [passkey])
        let back = try #require(incoming.passkeys.first)
        #expect(back.credentialID == passkey.credentialID)
        #expect(back.relyingParty == "webauthn.io")
        #expect(back.userName == "duck")
        #expect(back.userHandle == passkey.userHandle)
        #expect(back.privateKey == passkey.privateKey)
        #expect(back.createdAt.timeIntervalSince(passkey.createdAt).magnitude < 1)
    }

    @Test func passportsGoAsPassports() throws {
        var info = SectionKey.documentInfo.makeSection()
        var owner = SectionKey.owner.makeSection()
        info.fields[0].value = "AB123"           // number
        info.fields[3].value = "2031-05-01"      // expiry date
        owner.fields[0].value = "Jane Duck"      // full name
        owner.fields[2].value = "1990-02-03"     // date of birth
        let extra = DocSection(name: "Visa", fields: [Field(title: "Country", value: "Japan")])
        let passport = Document(name: "Passport", description: "Jane", documentType: .identification,
                                sections: [info, owner, extra])

        let item = CredentialExchange.item(for: passport, now: .now)
        guard case .passport(let typed) = item.credentials.first else {
            Issue.record("expected a passport, got \(item.credentials)")
            return
        }
        #expect(typed.passportNumber?.value == "AB123")
        #expect(typed.expiryDate?.fieldType == .date)
        #expect(typed.fullName?.value == "Jane Duck")
        // Only the custom section is left over, and everything is repeated as a note for apps that keep only notes.
        #expect(item.credentials.count == 3)
        guard case .note(let note) = item.credentials.last else {
            Issue.record("expected a note last, got \(item.credentials)")
            return
        }
        #expect(note.content.value.contains("AB123"))
        #expect(note.content.value.contains("Japan"))

        let back = try #require(try transferred(documents: [passport]).documents.first)
        #expect(back.name == "Passport")
        #expect(back.description == "Jane")
        #expect(back.documentType == .identification)
        #expect(back.value(of: .number) == "AB123")
        #expect(back.value(of: .expiryDate) == "2031-05-01")
        #expect(back.expiryDate != nil)
        #expect(back.value(of: .fullName) == "Jane Duck")
        #expect(back.value(of: .dateOfBirth) == "1990-02-03")
        let visa = try #require(back.sections.first { $0.name == "Visa" })
        #expect(visa.fields.map(\.value) == ["Japan"])
        // The note DuckDepo added isn't brought back as notes.
        #expect(back.value(of: .notes) == nil)
    }

    @Test func otherDocumentsKeepTheirTypeAndSections() throws {
        var info = SectionKey.documentInfo.makeSection()
        info.fields[0].value = "INS-42"
        info.fields[3].value = "2027-01-01"
        var additional = SectionKey.additional.makeSection()
        additional.fields[1].value = "Call before visiting"
        let custom = DocSection(name: "Doctor", fields: [Field(title: "Name", value: "Dr Quack")])
        let insurance = Document(name: "Health Insurance", documentType: .medicine, sections: [info, custom, additional])

        let back = try #require(try transferred(documents: [insurance]).documents.first)
        #expect(back.documentType == .medicine)
        #expect(back.sections.map(\.sectionKey) == [.documentInfo, nil, .additional])
        #expect(back.value(of: .number) == "INS-42")
        #expect(back.value(of: .notes) == "Call before visiting")
        #expect(back.expiryDate != nil)
        #expect(back.sections[1].name == "Doctor")
        #expect(back.sections[1].fields.map(\.title) == ["Name"])
    }

    @Test func otherManagersItemsBecomeDuckDepoItems() throws {
        let totp = ASImportableCredential.TOTP(secret: Data(repeating: 1, count: 20), period: 30, digits: 6,
                                                userName: "duck", algorithm: .sha256, issuer: "Pond")
        let licence = ASImportableCredential.DriversLicense(
            fullName: field("Jane Duck"), birthDate: field("1990-02-03", .date), issueDate: nil,
            expiryDate: field("2030-12-31", .date), issuingAuthority: field("DVLA"), territory: nil,
            country: field("GB", .countryCode), licenseNumber: field("DUCK901"), licenseClass: field("B"))
        let data = exported([
            item("Pond", url: "https://pond.example/", [
                .basicAuthentication(.init(userName: field("duck"), password: field("quack", .concealedString))),
                .totp(totp),
                .note(.init(content: field("Recovery codes in the drawer"))),
            ]),
            item("Visa Card", [.creditCard(.init(number: field("4111"), fullName: nil, cardType: nil, verificationNumber: nil,
                                                  pin: nil, expiryDate: nil, validFrom: nil))]),
            item("", [.driversLicense(licence)]),
            // How Passwords sends an item that has only a note.
            item("Wi-Fi idea", [.basicAuthentication(.init(userName: field(""), password: nil)),
                                .note(.init(content: field("Router is in the hall")))]),
        ], from: "Passwords")

        let incoming = CredentialImport(data)
        #expect(incoming.source == "Passwords")
        #expect(incoming.passwords.count == 1)
        let password = try #require(incoming.passwords.first)
        #expect(password.website == "https://pond.example")
        #expect(OneTimeCode(text: password.oneTimeCode)?.algorithm == .sha256)
        #expect(incoming.droppedNoteCount == 1)
        #expect(incoming.unsupportedCount == 1)

        #expect(incoming.documents.count == 2)
        let licenceDocument = try #require(incoming.documents.first)
        #expect(licenceDocument.documentType == .transport)
        #expect(licenceDocument.name == "scan_kind_driving_licence".localized())
        #expect(licenceDocument.value(of: .number) == "DUCK901")
        #expect(licenceDocument.value(of: .issuedBy) == "DVLA")
        let extras = licenceDocument.sections.flatMap(\.fields).filter { $0.key == nil }.map(\.value)
        #expect(extras.contains("B"))
        #expect(extras.contains(Locale.current.localizedString(forRegionCode: "GB") ?? "GB"))

        let note = try #require(incoming.documents.last)
        #expect(note.documentType == .other)
        #expect(note.value(of: .notes) == "Router is in the hall")
    }

    @Test func passkeysThatArentP256AreLeftOut() {
        let passkey = ASImportableCredential.Passkey(credentialID: Data([1]), relyingPartyIdentifier: "example.com",
                                                     userName: "duck", userDisplayName: "Duck", userHandle: Data([2]),
                                                     key: Curve25519.Signing.PrivateKey().rawRepresentation)
        let incoming = CredentialImport(exported([item("example.com", [.passkey(passkey)])]))
        #expect(incoming.passkeys.isEmpty)
        #expect(incoming.unsupportedCount == 1)
    }

    @Test func thePlanLeavesOutWhatsAlreadySaved() throws {
        let saved = Password(name: "GitHub", login: "Octo", value: "same", website: "github.com")
        let samePlusCode = Password(name: "GitHub", login: "octo", value: "same", website: "https://www.github.com", oneTimeCode: code)
        let otherPassword = Password(name: "GitHub", login: "octo", value: "different", website: "github.com")
        let passkey = Passkey.make(relyingParty: "github.com", userName: "octo", userHandle: Data([1]))
        let document = Document(name: "Passport", documentType: .identification,
                                sections: [DocSection(name: "Info", fields: [Field(title: "Number", value: "1")])])

        var incoming = try transferred(passwords: [samePlusCode, otherPassword, otherPassword],
                                       passkeys: [passkey, passkey], documents: [document])
        var reads: [UUID] = []
        let plan = ImportPlan(incoming, savedPasswords: [saved, Password(name: "Other", login: "x", website: "x.com")],
                              savedSecrets: { id in reads.append(id); return ("same", "") },
                              savedPasskeyIDs: [], savedDocuments: [document])
        // Only the account that might match was read.
        #expect(reads == [saved.id])
        #expect(Array(plan.codesForSaved.keys) == [saved.id])
        #expect(plan.codesForSaved[saved.id].flatMap(OneTimeCode.init(text:)) == OneTimeCode(text: code))
        #expect(plan.passwords.map(\.value) == ["different"])
        #expect(plan.passkeys.count == 1)
        #expect(plan.documents.isEmpty)
        // The repeated password and passkey, and the document.
        #expect(plan.alreadySavedCount == 3)
        #expect(plan.codeCount == 1)

        incoming.passwords = []
        incoming.passkeys = []
        incoming.documents = []
        #expect(ImportPlan(incoming, savedPasswords: [], savedSecrets: { _ in ("", "") },
                           savedPasskeyIDs: [], savedDocuments: []).isEmpty)
    }

    private func plan(_ data: ASExportedCredentialData, saved: [Password] = [],
                      secrets: @escaping (UUID) -> (value: String?, code: String) = { _ in ("", "") }) -> ImportPlan {
        ImportPlan(CredentialImport(data), savedPasswords: saved, savedSecrets: secrets, savedPasskeyIDs: [], savedDocuments: [])
    }

    private func login(_ user: String, _ password: String) -> ASImportableCredential {
        .basicAuthentication(.init(userName: field(user), password: field(password, .concealedString)))
    }

    private func totp(_ secret: UInt8, count: Int = 20, account: String? = nil) -> ASImportableCredential {
        .totp(.init(secret: Data(repeating: secret, count: count), period: 30, digits: 6, userName: account, algorithm: .sha1))
    }

    @Test func accountsWithoutAWebsiteAreToldApartByName() throws {
        let plan = plan(exported([
            item("Steam", [login("john@example.com", "hunter2")]),
            item("Epic Games", [login("john@example.com", "hunter2"), totp(1)]),
            item("GitHub", [totp(2, account: "me")]),
            item("Google", [totp(3, account: "me")]),
        ]))
        #expect(plan.passwords.map(\.name) == ["Steam", "Epic Games", "GitHub", "Google"])
        #expect(plan.passwords[0].oneTimeCode.isEmpty)
        #expect(OneTimeCode(text: plan.passwords[1].oneTimeCode)?.secret == Data(repeating: 1, count: 20))
        #expect(plan.alreadySavedCount == 0)
    }

    @Test func aNewCodeForAnAccountIsKeptNextToTheOldOne() throws {
        let saved = Password(name: "GitHub", login: "octo", website: "github.com")
        let plan = plan(exported([item("GitHub", url: "https://github.com", [login("octo", "pw"), totp(9)])]),
                        saved: [saved], secrets: { _ in ("pw", code) })
        #expect(plan.passwords.count == 1)
        #expect(plan.codesForSaved.isEmpty)
        #expect(plan.alreadySavedCount == 0)
    }

    @Test func anAccountWhoseValueHasntSyncedIsntAddedAgain() throws {
        let saved = Password(name: "GitHub", login: "octo", website: "github.com")
        let plan = plan(exported([item("GitHub", url: "https://github.com", [login("octo", "pw")])]),
                        saved: [saved], secrets: { _ in (nil, "") })
        #expect(plan.passwords.isEmpty)
        #expect(plan.alreadySavedCount == 1)
    }

    @Test func shortCodeSecretsStillMakeCodes() throws {
        let incoming = CredentialImport(exported([item("Old Site", [login("me", "pw"), totp(4, count: 8)])]))
        let code = try #require(OneTimeCode(text: incoming.passwords[0].oneTimeCode))
        #expect(code.secret.count == 8)
        // Typed keys still need the length.
        #expect(OneTimeCode(text: "nonsense") == nil)
    }

    @Test func codesGoWithTheLoginTheyName() throws {
        let incoming = CredentialImport(exported([item("Shared", [login("alice", "a"), login("bob", "b"),
                                                                  totp(5, account: "bob"), totp(6, account: "alice")])]))
        let alice = try #require(incoming.passwords.first { $0.login == "alice" })
        #expect(OneTimeCode(text: alice.oneTimeCode)?.secret.first == 6)
    }

    @Test func anItemWithSeveralDocumentsBecomesOneEach() throws {
        let passport = ASImportableCredential.passport(.init(
            issuingCountry: nil, passportType: nil, passportNumber: field("P1"), nationalIdentificationNumber: nil,
            nationality: nil, fullName: field("Jane"), birthDate: nil, birthPlace: nil, sex: nil, issueDate: nil,
            expiryDate: field("2030-01-01", .date), issuingAuthority: nil))
        let licence = ASImportableCredential.driversLicense(.init(
            fullName: field("Jane"), birthDate: nil, issueDate: nil, expiryDate: field("2028-06-30", .date),
            issuingAuthority: nil, territory: nil, country: nil, licenseNumber: field("D1"), licenseClass: nil))
        let documents = CredentialImport(exported([item("Jane", [passport, licence])])).documents
        #expect(documents.count == 2)
        #expect(documents.map(\.documentType) == [.identification, .transport])
        #expect(documents.map { $0.value(of: .number) } == ["P1", "D1"])
        #expect(documents[1].name == "Jane – " + "scan_kind_driving_licence".localized())
        #expect(documents[1].value(of: .expiryDate) == "2028-06-30")
    }

    @Test func tagsDontChangeATypedDocument() throws {
        let passport = ASImportableCredential.passport(.init(
            issuingCountry: nil, passportType: nil, passportNumber: field("P1"), nationalIdentificationNumber: nil,
            nationality: nil, fullName: nil, birthDate: nil, birthPlace: nil, sex: nil, issueDate: nil,
            expiryDate: nil, issuingAuthority: nil))
        let documents = CredentialImport(exported([item("Passport", tags: ["doc_type_medicine".localized()], [passport])])).documents
        #expect(documents.first?.documentType == .identification)
    }

    @Test func theNoteDuckDepoAddsIsRecognised() throws {
        // Fields out of the usual order, as after deleting and adding one back.
        let info = DocSection(key: SectionKey.documentInfo.rawValue, name: "", fields: [
            { var field = FieldKey.number.makeField(); field.value = "AB1"; return field }(),
            { var field = FieldKey.expiryDate.makeField(); field.value = "2030-01-01"; return field }(),
            { var field = FieldKey.issueDate.makeField(); field.value = "2020-01-01"; return field }(),
        ])
        let passport = Document(name: "Passport", description: "Jane ", documentType: .identification, sections: [info])
        let summary = CredentialExchange.summary(of: passport)
        #expect(summary.contains(SectionKey.documentInfo.localizedName))
        #expect(summary.hasSuffix("cx_note_footer".localized()))

        let back = try #require(try transferred(documents: [passport]).documents.first)
        #expect(back.value(of: .notes) == nil)

        // From an app that keeps only the note, the note is the document.
        let fromPasswords = CredentialImport(exported([item("Passport", [
            .basicAuthentication(.init(userName: field(""), password: nil)),
            .note(.init(content: field(summary))),
        ])])).documents
        let notes = try #require(fromPasswords.first?.value(of: .notes))
        #expect(notes.contains("AB1"))
        #expect(!notes.contains("cx_note_footer".localized()))
    }

    @Test func emptyDocumentsArriveWithTheirName() throws {
        let card = Document(name: "Vaccination Card", documentType: .medicine)
        let back = try #require(try transferred(documents: [card]).documents.first)
        #expect(back.name == "Vaccination Card")
        #expect(back.documentType == .medicine)
        #expect(back.sections.isEmpty)
    }

    @Test func sectionsWithTheSameNameStayApart() throws {
        let document = Document(name: "Travel", documentType: .other, sections: [
            DocSection(name: "Visa", fields: [Field(title: "Country", value: "Japan")]),
            DocSection(name: "Visa", fields: [Field(title: "Country", value: "Chile")]),
        ])
        let back = try #require(try transferred(documents: [document]).documents.first)
        #expect(back.sections.filter { $0.name == "Visa" }.map { $0.fields.map(\.value) } == [["Japan"], ["Chile"]])
    }

    @Test func daysAreExportedZeroPadded() throws {
        var info = SectionKey.documentInfo.makeSection()
        info.fields[3].value = "2031-5-1"
        let item = CredentialExchange.item(for: Document(name: "Insurance", documentType: .medicine, sections: [info]), now: .now)
        guard case .customFields(let group) = item.credentials.first else {
            Issue.record("expected custom fields, got \(item.credentials)")
            return
        }
        #expect(group.fields.first?.value == "2031-05-01")
        #expect(group.fields.first?.fieldType == .date)
    }

    @Test func aCustomSectionKeepsItsNumber() throws {
        var info = SectionKey.documentInfo.makeSection()
        info.fields[0].value = "P1"
        let visa = DocSection(name: "Visa", fields: [Field(key: FieldKey.number.rawValue, title: "Number", value: "V9")])
        let passport = Document(name: "Passport", documentType: .identification, sections: [visa, info])
        guard case .passport(let typed) = CredentialExchange.item(for: passport, now: .now).credentials.first else {
            Issue.record("expected a passport")
            return
        }
        #expect(typed.passportNumber?.value == "P1")
        let back = try #require(try transferred(documents: [passport]).documents.first)
        #expect(back.sections.first { $0.name == "Visa" }?.fields.map(\.value) == ["V9"])
    }

    @Test func textDatesBecomeDays() throws {
        let group = ASImportableCredential.customFields(.init(label: "Details", fields: [field("15.03.2020", label: "Issue Date")]))
        let document = try #require(CredentialImport(exported([item("Permit", [group])])).documents.first)
        #expect(document.value(of: .issueDate) == "2020-03-15")
    }

    @Test func documentsThatDifferOnlyInDescriptionAreBothKept() throws {
        var info = SectionKey.documentInfo.makeSection()
        info.fields[0].value = "1"
        let jane = Document(name: "Passport", description: "Jane", documentType: .identification, sections: [info])
        var john = jane
        john.id = UUID()
        john.description = "John"
        let plan = ImportPlan(try transferred(documents: [john]), savedPasswords: [], savedSecrets: { _ in ("", "") },
                              savedPasskeyIDs: [], savedDocuments: [jane])
        #expect(plan.documents.count == 1)
    }

    @Test func itemsWithSeveralAddressesUseOneWithAHost() throws {
        let scope = ASImportableCredentialScope(urls: [URL(string: "urn:app")!, URL(string: "https://a.example/")!])
        let android = ASImportableCredentialScope(urls: [], androidApps: [.init(bundleID: "com.bank.app", certificate: nil, name: "Bank")])
        let incoming = CredentialImport(exported([
            ASImportableItem(id: Data([1]), created: .now, lastModified: .now, title: "A", scope: scope, credentials: [login("me", "1")]),
            ASImportableItem(id: Data([2]), created: .now, lastModified: .now, title: "", scope: android, credentials: [login("me", "2")]),
        ]))
        #expect(incoming.passwords.map(\.website) == ["https://a.example", ""])
        #expect(incoming.passwords.last?.name == "Bank")
    }

    @Test func whatComesWithACardStaysWithIt() throws {
        let card = ASImportableCredential.creditCard(.init(number: field("4111"), fullName: nil, cardType: nil,
                                                           verificationNumber: nil, pin: nil, expiryDate: nil, validFrom: nil))
        let extra = ASImportableCredential.customFields(.init(label: "More", fields: [field("1234", .concealedString, label: "PIN")]))
        let incoming = CredentialImport(exported([item("Visa", [card, extra])]))
        #expect(incoming.documents.isEmpty)
        #expect(incoming.unsupportedCount == 1)
    }
}

@MainActor
struct CredentialTransferTests {

    @Test func anImportIsSavedOnceAndNotRepeated() async throws {
        let database = TestStack.makeDatabase()
        let keychain = InMemoryKeychain()
        let transfer = CredentialTransfer(database: database, keychain: keychain, identityStore: nil)
        let password = Password(name: "Pond", login: "duck", value: "quack", website: "pond.example",
                                oneTimeCode: "otpauth://totp/duck?secret=JBSWY3DPEHPK3PXPJBSWY3DP")
        let passkey = Passkey.make(relyingParty: "pond.example", userName: "duck", userHandle: Data([3]))
        var info = SectionKey.documentInfo.makeSection()
        info.fields[0].value = "P-1"
        let document = Document(name: "Passport", documentType: .identification, sections: [info])
        let incoming = try transferred(passwords: [password], passkeys: [passkey], documents: [document])

        let plan = transfer.plan(for: incoming)
        var progress: [Double] = []
        let result = await transfer.perform(plan) { progress.append($0) }
        #expect(result.isComplete)
        #expect(result.count == 3)
        #expect(progress.last == 1)

        let storage = PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
        let saved = PasswordsStorage.withSecrets(storage.allRecords(), keychain: keychain)
        #expect(saved.map(\.value) == ["quack"])
        #expect(!saved[0].oneTimeCode.isEmpty)
        #expect(PasskeyStorage(keychain: keychain).allWithKeys().map(\.privateKey) == [passkey.privateKey])
        #expect(database.allDocuments().map { $0.value(of: .number) } == ["P-1"])

        // The same plan a second time (a double tap) adds nothing and leaves the secrets alone.
        let second = await transfer.perform(plan)
        #expect(second.count == 0)
        #expect(second.isComplete)
        #expect(storage.count() == 1)
        #expect(database.allDocuments().count == 1)
        #expect(keychain.string(forKey: saved[0].id.uuidString) == "quack")

        let again = transfer.plan(for: incoming)
        #expect(again.isEmpty)
        #expect(again.alreadySavedCount == 3)

        // And it all goes out again.
        let export = await transfer.exportedData(formatVersion: .v1)
        #expect(export.count == 3)
    }

    @Test func codesForSavedPasswordsAreCheckedAgainAndCounted() async {
        let database = TestStack.makeDatabase()
        let keychain = InMemoryKeychain()
        let transfer = CredentialTransfer(database: database, keychain: keychain, identityStore: nil)
        let arrived = UUID()
        let without = UUID()
        keychain.set("otpauth://totp/x?secret=JBSWY3DPEHPK3PXP", forKey: PasswordsStorage.oneTimeCodeKey(for: arrived))
        var plan = transfer.plan(for: CredentialImport(exported([])))
        plan.codesForSaved = [arrived: "otpauth://totp/old?secret=MFRGGZDF", without: "otpauth://totp/new?secret=MFRGGZDF"]
        let result = await transfer.perform(plan)
        #expect(result.count == 1)
        #expect(result.isComplete)
        // The code that arrived meanwhile is kept.
        #expect(keychain.string(forKey: PasswordsStorage.oneTimeCodeKey(for: arrived)) == "otpauth://totp/x?secret=JBSWY3DPEHPK3PXP")

        keychain.failWrites = true
        plan.codesForSaved = [UUID(): "otpauth://totp/new?secret=MFRGGZDF"]
        #expect(await transfer.perform(plan).isComplete == false)
    }

    @Test func passwordsAlreadyStoredAreLeftAlone() {
        let database = TestStack.makeDatabase()
        let keychain = InMemoryKeychain()
        let storage = PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
        let password = Password(name: "Router", value: "1")
        #expect(storage.add([password]) == 1)
        keychain.failWrites = true
        // Adding it again neither stores a twin nor removes its secret.
        #expect(storage.add([password]) == 0)
        #expect(storage.count() == 1)
        #expect(keychain.string(forKey: password.id.uuidString) == "1")
    }

    @Test func passwordsWhoseValueCantBeWrittenAreLeftOut() {
        let database = TestStack.makeDatabase()
        let keychain = InMemoryKeychain()
        keychain.failWrites = true
        let storage = PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
        #expect(storage.add([Password(name: "A", value: "1")]) == 0)
        #expect(storage.count() == 0)
    }
}
