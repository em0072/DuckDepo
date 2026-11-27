//
//  PasskeyTests.swift
//  DuckDepoTests
//

import CryptoKit
import Foundation
import Testing
@testable import DuckDepo

struct CBORTests {

    private func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    /// RFC 8949 appendix A examples.
    @Test func encodesTheShortestForm() {
        #expect(hex(CBOR.int(0).encoded) == "00")
        #expect(hex(CBOR.int(23).encoded) == "17")
        #expect(hex(CBOR.int(24).encoded) == "1818")
        #expect(hex(CBOR.int(1000).encoded) == "1903e8")
        #expect(hex(CBOR.int(1_000_000).encoded) == "1a000f4240")
        #expect(hex(CBOR.int(-1).encoded) == "20")
        #expect(hex(CBOR.int(-7).encoded) == "26")
        #expect(hex(CBOR.int(-100).encoded) == "3863")
        #expect(hex(CBOR.bytes(Data()).encoded) == "40")
        #expect(hex(CBOR.bytes(Data([1, 2, 3, 4])).encoded) == "4401020304")
        #expect(hex(CBOR.text("IETF").encoded) == "6449455446")
        #expect(hex(CBOR.map([]).encoded) == "a0")
        #expect(hex(CBOR.map([(.int(1), .int(2)), (.int(3), .int(4))]).encoded) == "a201020304")
    }
}

struct PasskeyAuthenticatorTests {

    private let passkey = Passkey.make(relyingParty: "webauthn.io", userName: "jane", userHandle: Data("user-1".utf8))
    private let clientDataHash = Data(SHA256.hash(data: Data(#"{"type":"webauthn.get"}"#.utf8)))

    @Test func theCOSEKeyIsAnES256P256Key() throws {
        let key = try #require(passkey.signingKey).publicKey
        let cose = PasskeyAuthenticator.coseKey(for: key)
        let point = key.x963Representation
        // {1: 2, 3: -7, -1: 1, -2: x, -3: y}
        var expected = Data([0xA5, 0x01, 0x02, 0x03, 0x26, 0x20, 0x01, 0x21, 0x58, 0x20])
        expected.append(point[1..<33])
        expected.append(contentsOf: [0x22, 0x58, 0x20])
        expected.append(point[33..<65])
        #expect(cose == expected)
        #expect(cose.count == 77)
    }

    @Test func theAttestationObjectCarriesTheCredential() throws {
        let object = try PasskeyAuthenticator.attestationObject(for: passkey, userVerified: true)
        // {"fmt": "none", "attStmt": {}, "authData": bytes(148)}
        var header = Data([0xA3, 0x63])
        header.append(Data("fmt".utf8))
        header.append(0x64)
        header.append(Data("none".utf8))
        header.append(0x67)
        header.append(Data("attStmt".utf8))
        header.append(contentsOf: [0xA0, 0x68])
        header.append(Data("authData".utf8))
        header.append(contentsOf: [0x58, 148])
        #expect(object.prefix(header.count) == header)
        let authData = object.dropFirst(header.count)
        #expect(authData.count == 148)
        let bytes = Array(authData)
        #expect(Data(bytes[0..<32]) == Data(SHA256.hash(data: Data("webauthn.io".utf8))))
        // User present, user verified, backup eligible, backed up, attested credential data.
        #expect(bytes[32] == 0x5D)
        #expect(bytes[33..<37] == [0, 0, 0, 0])
        #expect(bytes[37..<53] == ArraySlice(repeating: 0, count: 16))
        #expect(bytes[53..<55] == [0x00, 0x10])
        #expect(Data(bytes[55..<71]) == passkey.credentialID)
        let cose = PasskeyAuthenticator.coseKey(for: try #require(passkey.signingKey).publicKey)
        #expect(Data(bytes[71...]) == cose)
    }

    @Test func signInSignaturesVerifyWithThePublicKey() throws {
        let assertion = try PasskeyAuthenticator.assertion(for: passkey, clientDataHash: clientDataHash, userVerified: true)
        #expect(assertion.authenticatorData.count == 37)
        #expect(assertion.authenticatorData[32] == 0x1D)
        let publicKey = try #require(passkey.signingKey).publicKey
        let signature = try P256.Signing.ECDSASignature(derRepresentation: assertion.signature)
        #expect(publicKey.isValidSignature(signature, for: assertion.authenticatorData + clientDataHash))
        // Bound to this request: another client data hash doesn't verify.
        #expect(!publicKey.isValidSignature(signature, for: assertion.authenticatorData + Data(count: 32)))
    }

    @Test func withoutVerificationTheFlagSaysSo() throws {
        let assertion = try PasskeyAuthenticator.assertion(for: passkey, clientDataHash: clientDataHash, userVerified: false)
        #expect(assertion.authenticatorData[32] == 0x19)
    }
}

struct PasskeyStorageTests {

    @Test func savesListsFindsAndDeletesPasskeys() {
        let keychain = InMemoryKeychain()
        keychain.set("a password", forKey: UUID().uuidString)
        let storage = PasskeyStorage(keychain: keychain)
        let github = Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))
        let github2 = Passkey.make(relyingParty: "github.com", userName: "jane-work", userHandle: Data([2]))
        let example = Passkey.make(relyingParty: "example.com", userName: "joe", userHandle: Data([3]))
        for passkey in [github, github2, example] {
            #expect(storage.save(passkey))
        }

        #expect(storage.count() == 3)
        #expect(storage.all().map(\.userName) == ["joe", "jane", "jane-work"])
        #expect(Set(storage.passkeys(for: "github.com")) == [github.summary, github2.summary])
        #expect(storage.passkeys(for: "github.com", allowed: [github2.credentialID]) == [github2.summary])
        #expect(storage.passkey(credentialID: example.credentialID) == example)

        #expect(storage.delete(github.summary))
        #expect(storage.passkeys(for: "github.com") == [github2.summary])
        // Passwords are left alone.
        #expect(keychain.items.count == 3)
    }

    /// Lists read only the passkeys' own keychain service, never password values.
    @Test func listingReadsOnlyPasskeys() {
        let keychain = InMemoryKeychain()
        keychain.set("a password", forKey: UUID().uuidString)
        keychain.set("otpauth://totp/x?secret=ABC", forKey: UUID().uuidString + ".otp")
        let storage = PasskeyStorage(keychain: keychain)
        let passkey = Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))
        #expect(storage.save(passkey))

        #expect(keychain.keys(service: PasskeyStorage.service) == [PasskeyStorage.key(for: passkey.credentialID)])
        #expect(storage.count() == 1)
        #expect(storage.all() == [passkey.summary])
    }

    /// WebAuthn: a new passkey for the same account on the same site replaces the old one.
    @Test func aNewPasskeyReplacesTheAccountsEarlierOne() throws {
        let storage = PasskeyStorage(keychain: InMemoryKeychain())
        let old = Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))
        let otherAccount = Passkey.make(relyingParty: "github.com", userName: "joe", userHandle: Data([2]))
        let otherSite = Passkey.make(relyingParty: "example.com", userName: "jane", userHandle: Data([1]))
        for passkey in [old, otherAccount, otherSite] {
            #expect(storage.save(passkey))
        }

        let new = Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))
        let replaced = try #require(storage.saveReplacingEarlier(new))

        #expect(replaced == [old.summary])
        #expect(storage.passkey(credentialID: old.credentialID) == nil)
        #expect(Set(storage.all()) == [new.summary, otherAccount.summary, otherSite.summary])
    }

    @Test func nothingIsReplacedWhenTheNewPasskeyCantBeSaved() {
        let keychain = InMemoryKeychain()
        let storage = PasskeyStorage(keychain: keychain)
        let old = Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))
        #expect(storage.save(old))

        keychain.failWrites = true
        #expect(storage.saveReplacingEarlier(Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))) == nil)
        #expect(storage.all() == [old.summary])
    }

    /// The key stays in the keychain: summaries are decoded without it.
    @Test func summariesCarryNoKey() throws {
        let passkey = Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))
        let json = try JSONEncoder().encode(passkey.summary)
        let fields = try #require(try JSONSerialization.jsonObject(with: json) as? [String: Any])
        #expect(fields["privateKey"] == nil)
    }
}

/// The Passwords tab lists passkeys from the keychain, which only this process announces changes to.
@MainActor
struct PasswordsListPasskeyTests {

    @Test func passkeysGoAfterDeleteAllData() {
        let keychain = InMemoryKeychain()
        let database = TestStack.makeDatabase()
        let passkeys = PasskeyStorage(keychain: keychain)
        #expect(passkeys.save(Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))))
        let viewModel = PasswordsListViewModel(makeStorage: {
            PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
        }, passkeyStorage: passkeys)
        viewModel.start()
        #expect(viewModel.passkeys.count == 1)

        database.deleteEverything(keychain: keychain)

        #expect(viewModel.passkeys.isEmpty)
    }

    @Test func aDeletedPasskeyLeavesTheList() throws {
        let keychain = InMemoryKeychain()
        let passkeys = PasskeyStorage(keychain: keychain)
        let passkey = Passkey.make(relyingParty: "github.com", userName: "jane", userHandle: Data([1]))
        #expect(passkeys.save(passkey))
        let database = TestStack.makeDatabase()
        let viewModel = PasswordsListViewModel(makeStorage: {
            PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
        }, passkeyStorage: passkeys)
        viewModel.start()

        viewModel.delete(try #require(viewModel.passkeys.first))

        #expect(viewModel.passkeys.isEmpty)
        #expect(passkeys.count() == 0)
    }
}

/// The real keychain: items of one service are listed without the others. Uses throwaway names and removes them.
struct KeychainServiceTests {

    @Test func listsOnlyItsServiceAndFindsItemsByKey() {
        let keychain = Keychain()
        let service = "DuckDepoTests." + UUID().uuidString
        let key = "test." + UUID().uuidString
        let other = "test." + UUID().uuidString
        defer {
            keychain.delete(key)
            keychain.delete(other)
        }
        #expect(keychain.set("passkey", forKey: key, service: service))
        #expect(keychain.set("password", forKey: other))

        #expect(keychain.strings(service: service) == [key: "passkey"])
        #expect(keychain.keys(service: service) == [key])
        #expect(keychain.string(forKey: key) == "passkey")

        // Writing again replaces the item.
        #expect(keychain.set("passkey 2", forKey: key, service: service))
        #expect(keychain.strings(service: service) == [key: "passkey 2"])

        #expect(keychain.delete(key))
        #expect(keychain.keys(service: service).isEmpty)
        #expect(keychain.string(forKey: other) == "password")
    }
}
