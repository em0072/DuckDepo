//
//  OneTimeCodeTests.swift
//  DuckDepoTests
//

import AuthenticationServices
import CoreImage
import UIKit
import Foundation
import Testing
@testable import DuckDepo

struct OneTimeCodeTests {

    /// RFC 6238, appendix B: 8-digit codes for the three algorithms.
    @Test(arguments: [
        (59.0, "94287082", "46119246", "90693936"),
        (1111111109.0, "07081804", "68084774", "25091201"),
        (1111111111.0, "14050471", "67062674", "99943326"),
        (1234567890.0, "89005924", "91819424", "93441116"),
        (2000000000.0, "69279037", "90698825", "38618901"),
        (20000000000.0, "65353130", "77737706", "47863826"),
    ])
    func matchesTheRFCTestVectors(time: Double, sha1: String, sha256: String, sha512: String) {
        let date = Date(timeIntervalSince1970: time)
        let seed = "12345678901234567890"
        func code(_ secret: String, _ algorithm: OneTimeCode.Algorithm) -> String {
            OneTimeCode(secret: Data(secret.utf8), algorithm: algorithm, digits: 8).code(at: date)
        }
        #expect(code(seed, .sha1) == sha1)
        #expect(code(seed + "123456789012", .sha256) == sha256)
        #expect(code(seed + seed + seed + "1234", .sha512) == sha512)
    }

    @Test func makesSixDigitCodesFromASetupKey() throws {
        // "12345678901234567890" in Base32, typed with spaces and in lower case.
        let code = try #require(OneTimeCode(text: "gezd gnbv gy3t qojq gezd gnbv gy3t qojq"))
        #expect(code.code(at: Date(timeIntervalSince1970: 59)) == "287082")
        #expect(code.secondsRemaining(at: Date(timeIntervalSince1970: 59)) == 1)
        #expect(code.secondsRemaining(at: Date(timeIntervalSince1970: 60)) == 30)
        #expect(OneTimeCode.formatted("287082") == "287 082")
    }

    @Test func readsAnOtpauthLink() throws {
        let link = "otpauth://totp/GitHub:jane%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA256&digits=8&period=60"
        let code = try #require(OneTimeCode(text: link))
        #expect(code.issuer == "GitHub")
        #expect(code.account == "jane@example.com")
        #expect(code.algorithm == .sha256)
        #expect(code.digits == 8)
        #expect(code.period == 60)
        #expect(code.secret == OneTimeCode.base32Decode("JBSWY3DPEHPK3PXP"))
        // What's stored reads back the same.
        #expect(OneTimeCode(text: code.uri) == code)
    }

    @Test func takesTheIssuerFromTheLabelWhenThereIsNoParameter() throws {
        let code = try #require(OneTimeCode(text: "otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP"))
        #expect(code.issuer == "Example")
        #expect(code.account == "alice")
        #expect(code.algorithm == .sha1)
        #expect(code.digits == 6)
        #expect(code.period == 30)
    }

    @Test func rejectsWhatIsntASetupCode() {
        #expect(OneTimeCode(text: "") == nil)
        #expect(OneTimeCode(text: "not a key!") == nil)
        // Valid Base32, but far too short to be a setup key.
        #expect(OneTimeCode(text: "nonsense") == nil)
        #expect(OneTimeCode(text: "https://example.com") == nil)
        #expect(OneTimeCode(text: "otpauth://hotp/Example?secret=JBSWY3DPEHPK3PXP&counter=1") == nil)
        #expect(OneTimeCode(text: "otpauth://totp/Example?issuer=Example") == nil)
        #expect(OneTimeCode(text: "otpauth://totp/Example?secret=JBSWY3DPEHPK3PXP&digits=4") == nil)
    }

    @Test func base32RoundTrips() {
        for text in ["", "f", "fo", "foo", "foob", "fooba", "foobar"] {
            let data = Data(text.utf8)
            #expect(OneTimeCode.base32Decode(OneTimeCode.base32Encode(data)) ?? Data() == data)
        }
        #expect(OneTimeCode.base32Encode(Data("foobar".utf8)) == "MZXW6YTBOI")
    }
}

@MainActor
struct OneTimeCodeStorageTests {

    private let database = TestStack.makeDatabase()
    private let keychain = InMemoryKeychain()

    private var storage: PasswordsStorage {
        PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
    }

    @Test func savesAndRemovesTheCodeWithThePassword() throws {
        let code = try #require(OneTimeCode(text: "JBSWY3DPEHPK3PXP"))
        var password = Password(name: "GitHub", login: "jane", value: "secret", website: "github.com", oneTimeCode: code.uri)
        #expect(storage.save(password))
        #expect(storage.oneTimeCode(for: password.id) == code.uri)

        password.oneTimeCode = ""
        #expect(storage.save(password))
        #expect(storage.oneTimeCode(for: password.id).isEmpty)

        password.oneTimeCode = code.uri
        #expect(storage.save(password))
        storage.delete(password)
        #expect(keychain.string(forKey: PasswordsStorage.oneTimeCodeKey(for: password.id)) == nil)
    }

    @Test func theEditorLoadsTheCodeAndFillsInANewEntry() throws {
        let code = try #require(OneTimeCode(text: "otpauth://totp/GitHub:jane?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"))
        let password = Password(name: "GitHub", login: "jane", value: "secret", oneTimeCode: code.uri)
        #expect(storage.save(password))

        // A list item has no secrets; the editor reads them and isn't changed by that.
        let existing = EditPasswordViewModel(type: .existing(Password(id: password.id, name: "GitHub", login: "jane")),
                                             storage: storage)
        existing.load()
        #expect(existing.oneTimeCode == code)
        #expect(!existing.hasChanges)
        existing.removeOneTimeCode()
        #expect(existing.hasChanges)

        let new = EditPasswordViewModel(type: .new, storage: storage)
        new.setUpOneTimeCode(from: code.uri)
        #expect(new.passwordName == "GitHub")
        #expect(new.passwordLogin == "jane")
        new.setUpOneTimeCode(from: "nonsense")
        #expect(new.oneTimeCodeError)
        #expect(new.oneTimeCode == code)
    }

    @Test func autoFillOffersCodesOnlyForEntriesWithOne() throws {
        let code = try #require(OneTimeCode(text: "JBSWY3DPEHPK3PXP"))
        let withCode = Password(name: "GitHub", login: "jane", value: "a", website: "https://github.com/login", oneTimeCode: code.uri)
        let without = Password(name: "Example", login: "joe", value: "b", website: "example.com")
        #expect(storage.save(withCode))
        #expect(storage.save(without))
        let records = try database.context.fetch(DDPassword.fetchRequest())
        let identities = records.compactMap { CredentialIdentityStoreController.oneTimeCodeIdentity(for: $0, keychain: keychain) }
        #expect(identities.count == 1)
        #expect(identities.first?.serviceIdentifier.identifier == "github.com")
        #expect(identities.first?.label == "jane")
        #expect(identities.first?.recordIdentifier == withCode.id.uuidString)
    }
}

struct QRCodeReadingTests {

    /// A setup QR code with a literal "@" in its label, as sites make them, on a larger white picture.
    @Test func readsASetupQRCodeFromAPicture() async throws {
        let link = "otpauth://totp/GitHub:jane@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
        let filter = try #require(CIFilter(name: "CIQRCodeGenerator"))
        filter.setValue(Data(link.utf8), forKey: "inputMessage")
        let qr = try #require(filter.outputImage).transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        let qrImage = try #require(CIContext().createCGImage(qr, from: qr.extent))
        let size = CGSize(width: qr.extent.width + 400, height: qr.extent.height + 600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let screenshot = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIImage(cgImage: qrImage).draw(at: CGPoint(x: 200, y: 300))
        }
        let codes = await DocumentReader.qrCodes(in: screenshot)
        #expect(codes == [link])
        #expect(OneTimeCode(text: codes.first ?? "")?.account == "jane@example.com")
    }
}
