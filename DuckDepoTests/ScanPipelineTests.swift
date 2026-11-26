//
//  ScanPipelineTests.swift
//  DuckDepoTests
//

import Foundation
import Testing
import UIKit
@testable import DuckDepo

/// Text recognition on rendered documents, then the parsers: the whole scan except the language model,
/// whose answers vary.
struct ScanPipelineTests {

    private let today: Date = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: 2026, month: 11, day: 26))!
    }()

    @Test func readsAPassportPhoto() async throws {
        let image = Self.render([
            ("UTOPIA", 40, false), ("PASSPORT / PASSEPORT", 36, false), ("Surname: ERIKSSON", 32, false),
            ("Given names: ANNA MARIA", 32, false), ("", 32, false),
            ("P<UTOERIKSSON<<ANNA<MARIA<<<<<<<<<<<<<<<<<<<", 34, true),
            ("L898902C36UTO7408122F1204159ZE184226B<<<<<10", 34, true),
        ])
        let lines = await DocumentReader.lines(in: image)
        let reading = await DocumentScanner.reading(from: lines, today: today, useModel: false)
        #expect(reading.kind == .passport)
        #expect(reading.values[.number] == ScanReading.Value(text: "L898902C3", confidence: .verified))
        #expect(reading.values[.dateOfBirth]?.text == "1974-08-12")
        #expect(reading.holderName?.text == "Anna Maria Eriksson")
    }

    @Test func readsADrivingLicencePhoto() async throws {
        let image = Self.render([
            ("RIJBEWIJS", 40, false), ("1. De Vries", 32, false), ("2. Jan Pieter", 32, false),
            ("3. 15.04.1985 Amsterdam", 32, false), ("4a. 23.03.2023    4c. Gemeente Rotterdam", 32, false),
            ("4b. 23.03.2033", 32, false), ("5. 5123456789", 32, false),
        ])
        let lines = await DocumentReader.lines(in: image)
        let reading = await DocumentScanner.reading(from: lines, today: today, useModel: false)
        #expect(reading.kind == .drivingLicence)
        #expect(reading.values[.number]?.text == "5123456789", "Recognized: \(lines)")
        #expect(reading.values[.expiryDate]?.text == "2033-03-23")
        #expect(reading.values[.issuedBy]?.text == "Gemeente Rotterdam")
    }

    /// Black text on white, one line per entry; `monospaced` for machine-readable zones.
    static func render(_ lines: [(text: String, size: CGFloat, monospaced: Bool)]) -> UIImage {
        let size = CGSize(width: 1400, height: 120 + CGFloat(lines.count) * 70)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            var y: CGFloat = 60
            for line in lines {
                let font = line.monospaced
                    ? UIFont.monospacedSystemFont(ofSize: line.size, weight: .medium)
                    : UIFont.systemFont(ofSize: line.size)
                (line.text as NSString).draw(at: CGPoint(x: 60, y: y),
                                             withAttributes: [.font: font, .foregroundColor: UIColor.black])
                y += 70
            }
        }
    }
}
