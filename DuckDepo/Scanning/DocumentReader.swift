//
//  DocumentReader.swift
//  DuckDepo
//

import ImageIO
import PDFKit
import UIKit
import Vision

/// Reads the text on photos of documents, on the device.
enum DocumentReader {

    /// The text lines of one page, in reading order.
    static func lines(in image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.automaticallyDetectLanguage = true
        // Correction "fixes" names, numbers and machine-readable zones into dictionary words.
        request.textRecognitionOptions.useLanguageCorrection = false
        do {
            let observations = try await request.perform(on: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
            return observations.flatMap { $0.document.text.lines.map(\.transcript) }
        } catch {
            return []
        }
    }

    /// The first pages of a PDF as images, large enough to read.
    static func pages(ofPDF url: URL, maximumPages: Int = 5) -> [UIImage] {
        guard let document = PDFDocument(url: url) else { return [] }
        return (0..<min(document.pageCount, maximumPages)).compactMap { index in
            guard let page = document.page(at: index) else { return nil }
            let bounds = page.bounds(for: .mediaBox)
            let scale = 2000 / max(bounds.width, bounds.height, 1)
            return page.thumbnail(of: CGSize(width: bounds.width * scale, height: bounds.height * scale), for: .mediaBox)
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
