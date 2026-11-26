//
//  OneTimeCode.swift
//  DuckDepo
//

import CryptoKit
import Foundation

/// A time-based one-time code (TOTP, RFC 6238), as set up with an authenticator app: from an
/// `otpauth://totp/…` link (what setup QR codes hold) or from the setup key alone.
struct OneTimeCode: Equatable {

    enum Algorithm: String, CaseIterable {
        case sha1 = "SHA1"
        case sha256 = "SHA256"
        case sha512 = "SHA512"
    }

    /// Setup keys are at least 80 bits (16 Base32 characters); anything shorter is a typo or a word.
    static let minimumSecretLength = 10

    let secret: Data
    var algorithm: Algorithm = .sha1
    var digits = 6
    /// Seconds each code is valid for.
    var period = 30
    var issuer: String?
    var account: String?

    init(secret: Data, algorithm: Algorithm = .sha1, digits: Int = 6, period: Int = 30,
         issuer: String? = nil, account: String? = nil) {
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
        self.issuer = issuer
        self.account = account
    }

    /// From an `otpauth://totp/` link or a Base32 setup key (spaces, dashes and case don't matter).
    /// Nil for anything else, including counter-based `hotp` links.
    init?(text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.lowercased().hasPrefix("otpauth://") {
            self.init(uri: text)
        } else {
            guard let secret = Self.base32Decode(text), secret.count >= Self.minimumSecretLength else { return nil }
            self.init(secret: secret)
        }
    }

    private init?(uri: String) {
        guard let components = URLComponents(string: uri), components.host?.lowercased() == "totp" else { return nil }
        let items = Dictionary((components.queryItems ?? []).map { ($0.name.lowercased(), $0.value ?? "") },
                               uniquingKeysWith: { first, _ in first })
        guard let secret = items["secret"].flatMap(Self.base32Decode), secret.count >= Self.minimumSecretLength else { return nil }
        let algorithm = items["algorithm"].flatMap { Algorithm(rawValue: $0.uppercased()) } ?? .sha1
        let digits = items["digits"].flatMap(Int.init) ?? 6
        let period = items["period"].flatMap(Int.init) ?? 30
        guard (6...8).contains(digits), period > 0 else { return nil }
        // The label is "Issuer:account" or just "account".
        let label = String(components.path.drop { $0 == "/" })
        let parts = label.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let account = parts.last.flatMap { $0.isEmpty ? nil : $0 }
        let issuer = items["issuer"].flatMap { $0.isEmpty ? nil : $0 } ?? (parts.count == 2 ? parts.first : nil)
        self.init(secret: secret, algorithm: algorithm, digits: digits, period: period, issuer: issuer, account: account)
    }

    /// An `otpauth://totp/` link holding everything needed to make codes; how it's stored.
    var uri: String {
        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = "totp"
        let label = [issuer, account].compactMap { $0 }.joined(separator: ":")
        components.path = "/" + label
        components.queryItems = [
            URLQueryItem(name: "secret", value: Self.base32Encode(secret)),
            issuer.map { URLQueryItem(name: "issuer", value: $0) },
            URLQueryItem(name: "algorithm", value: algorithm.rawValue),
            URLQueryItem(name: "digits", value: String(digits)),
            URLQueryItem(name: "period", value: String(period)),
        ].compactMap { $0 }
        return components.string ?? ""
    }

    // MARK: - Codes

    /// The code for `date`.
    func code(at date: Date = .now) -> String {
        let counter = UInt64(max(0, date.timeIntervalSince1970) / Double(period))
        var bigEndian = counter.bigEndian
        let message = Data(bytes: &bigEndian, count: MemoryLayout<UInt64>.size)
        let key = SymmetricKey(data: secret)
        let hash: [UInt8] = switch algorithm {
        case .sha1: Array(HMAC<Insecure.SHA1>.authenticationCode(for: message, using: key))
        case .sha256: Array(HMAC<SHA256>.authenticationCode(for: message, using: key))
        case .sha512: Array(HMAC<SHA512>.authenticationCode(for: message, using: key))
        }
        // Dynamic truncation (RFC 4226).
        let offset = Int(hash[hash.count - 1] & 0x0F)
        let value = (UInt32(hash[offset] & 0x7F) << 24) | (UInt32(hash[offset + 1]) << 16)
            | (UInt32(hash[offset + 2]) << 8) | UInt32(hash[offset + 3])
        let modulus = (0..<digits).reduce(UInt32(1)) { result, _ in result * 10 }
        let code = String(value % modulus)
        return String(repeating: "0", count: digits - code.count) + code
    }

    /// Seconds until the code for `date` changes.
    func secondsRemaining(at date: Date = .now) -> Int {
        let elapsed = Int(max(0, date.timeIntervalSince1970)) % period
        return period - elapsed
    }

    /// "123 456", easier to read and type.
    static func formatted(_ code: String) -> String {
        let middle = code.index(code.startIndex, offsetBy: code.count / 2)
        return String(code[..<middle]) + " " + String(code[middle...])
    }

    // MARK: - Base32 (RFC 4648)

    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

    static func base32Decode(_ text: String) -> Data? {
        let characters = text.uppercased().filter { !" -=\n\t".contains($0) }
        guard !characters.isEmpty else { return nil }
        var bytes: [UInt8] = []
        var buffer: UInt32 = 0
        var bits = 0
        for character in characters {
            guard let value = alphabet.firstIndex(of: character) else { return nil }
            buffer = (buffer << 5) | UInt32(value)
            bits += 5
            if bits >= 8 {
                bytes.append(UInt8((buffer >> UInt32(bits - 8)) & 0xFF))
                bits -= 8
            }
        }
        return Data(bytes)
    }

    static func base32Encode(_ data: Data) -> String {
        var output = ""
        var buffer: UInt32 = 0
        var bits = 0
        for byte in data {
            buffer = (buffer << 8) | UInt32(byte)
            bits += 8
            while bits >= 5 {
                output.append(alphabet[Int((buffer >> UInt32(bits - 5)) & 0x1F)])
                bits -= 5
            }
        }
        if bits > 0 {
            output.append(alphabet[Int((buffer << UInt32(5 - bits)) & 0x1F)])
        }
        return output
    }
}
