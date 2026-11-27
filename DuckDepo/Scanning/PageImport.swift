//
//  PageImport.swift
//  DuckDepo
//

import ImageIO
import PDFKit
import UIKit
import UniformTypeIdentifiers

/// Turns images and PDFs from other apps into document photos. Files are read where they lie, a page at a
/// time, and images are scaled down while they're read, so a large PDF or a 48-megapixel photo never sits
/// in memory whole (the share extension has little).
enum PageImport {

    /// Pages kept from one import; more would make a document no one scrolls through.
    static let maximumPages = 20
    /// Pages the share extension takes, from a share and in its editor: it has little memory.
    static let maximumSharedPages = 10

    /// The photos read, and how many pages there were.
    typealias Pages = (photos: [DocumentPhoto], pageCount: Int)

    // MARK: - Images

    /// A photo from image data (JPEG, HEIC, PNG...), its main image at the size it's stored at.
    static func photo(fromImageData data: Data) -> DocumentPhoto? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), CGImageSourceGetCount(source) > 0 else { return nil }
        return autoreleasepool { photo(from: source, at: CGImageSourceGetPrimaryImageIndex(source)) }
    }

    /// The pages of an image: one, or each page of a multi-page TIFF (a scan, a fax), up to `limit`.
    static func photos(fromImageData data: Data, limit: Int = maximumPages) -> Pages {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return ([], 0) }
        return photos(from: source, limit: limit)
    }

    static func photos(fromImageAt url: URL, limit: Int = maximumPages) -> Pages {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return ([], 0) }
        return photos(from: source, limit: limit)
    }

    private static func photos(from source: CGImageSource, limit: Int) -> Pages {
        let indexes = pageIndexes(of: source)
        var photos: [DocumentPhoto] = []
        for index in indexes.prefix(limit) {
            if let photo = autoreleasepool(invoking: { photo(from: source, at: index) }) {
                photos.append(photo)
            }
        }
        return (photos, indexes.count)
    }

    /// Each image of a TIFF is a page. Other files with several images (bursts, animations) show one.
    private static func pageIndexes(of source: CGImageSource) -> [Int] {
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return [] }
        if count > 1, let type = CGImageSourceGetType(source).flatMap({ UTType($0 as String) }), type.conforms(to: .tiff) {
            return Array(0..<count)
        }
        return [CGImageSourceGetPrimaryImageIndex(source)]
    }

    /// Scaled while it's decoded (`DocumentPhoto.storedScale`), turned upright, on white where it's
    /// transparent.
    private static func photo(from source: CGImageSource, at index: Int) -> DocumentPhoto? {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] ?? [:]
        let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue ?? 0
        let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue ?? 0
        let longest = max(width, height)
        let maxPixelSize = longest > 0
            ? (longest * DocumentPhoto.storedScale(for: CGSize(width: width, height: height))).rounded()
            : DocumentPhoto.maxPixelSize
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, maxPixelSize),
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, index, options as CFDictionary) else { return nil }
        return DocumentPhoto(image: UIImage(cgImage: image))
    }

    // MARK: - PDFs

    /// One photo per page, up to `limit`, rendered on white at the size pages are stored at, and how many
    /// pages the PDF has.
    static func photos(fromPDFData data: Data, limit: Int = maximumPages) -> Pages {
        guard let pdf = PDFDocument(data: data) else { return ([], 0) }
        return photos(from: pdf, limit: limit)
    }

    static func photos(fromPDFAt url: URL, limit: Int = maximumPages) -> Pages {
        guard let pdf = PDFDocument(url: url) else { return ([], 0) }
        return photos(from: pdf, limit: limit)
    }

    private static func photos(from pdf: PDFDocument, limit: Int) -> Pages {
        var photos: [DocumentPhoto] = []
        for index in 0..<min(pdf.pageCount, limit) {
            guard let page = pdf.page(at: index) else { continue }
            if let photo = autoreleasepool(invoking: { render(page) }) {
                photos.append(photo)
            }
        }
        return (photos, pdf.pageCount)
    }

    private static func render(_ page: PDFPage) -> DocumentPhoto? {
        // The crop box is what viewers show (it's the media box when the page has none).
        let bounds = page.bounds(for: .cropBox)
        let rotated = page.rotation % 180 != 0
        let width = rotated ? bounds.height : bounds.width
        let height = rotated ? bounds.width : bounds.height
        guard width > 0, height > 0 else { return nil }
        let scale = DocumentPhoto.storedScale(for: CGSize(width: width, height: height), scalingUp: true)
        let size = CGSize(width: max(1, (width * scale).rounded()), height: max(1, (height * scale).rounded()))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        // 8 bits per channel: a wide-colour canvas takes twice the memory, and the JPEG doesn't keep it.
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let cgContext = context.cgContext
            // PDF space has its origin at the bottom left. Drawing maps the box to the origin and turns
            // the page by its rotation.
            cgContext.translateBy(x: 0, y: size.height)
            cgContext.scaleBy(x: size.width / width, y: -size.height / height)
            page.draw(with: .cropBox, to: cgContext)
        }
        return DocumentPhoto(image: image)
    }

    // MARK: - Shared items

    /// What a shared item is, if DuckDepo can take it.
    enum Kind {
        case pdf, image

        init?(_ provider: NSItemProvider) {
            if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                self = .pdf
            } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                self = .image
            } else {
                return nil
            }
        }

        var type: UTType {
            switch self {
            case .pdf: .pdf
            case .image: .image
            }
        }

        func pages(at url: URL, limit: Int) -> Pages {
            switch self {
            case .pdf: PageImport.photos(fromPDFAt: url, limit: limit)
            case .image: PageImport.photos(fromImageAt: url, limit: limit)
            }
        }

        func pages(in data: Data, limit: Int) -> Pages {
            switch self {
            case .pdf: PageImport.photos(fromPDFData: data, limit: limit)
            case .image: PageImport.photos(fromImageData: data, limit: limit)
            }
        }
    }

    /// The pages of everything shared, in order, up to `limit`. `isTruncated` says some were left out.
    /// Identical pages (blank ones, the same file twice) are kept once: a photo's ID comes from its bytes.
    static func photos(from providers: [NSItemProvider], limit: Int = maximumPages) async -> (photos: [DocumentPhoto], isTruncated: Bool) {
        var photos: [DocumentPhoto] = []
        var seen = Set<DocumentPhoto.ID>()
        var isTruncated = false
        for provider in providers {
            guard let kind = Kind(provider) else { continue }
            guard photos.count < limit else {
                isTruncated = true
                continue
            }
            let pages = await pages(of: kind, from: provider, limit: limit - photos.count)
            photos += pages.photos.filter { seen.insert($0.id).inserted }
            isTruncated = isTruncated || pages.pageCount > pages.photos.count
        }
        return (photos, isTruncated)
    }

    /// From the item's file, which PDFKit and ImageIO read as they need it. Its data, read whole, only
    /// when there's no file.
    private static func pages(of kind: Kind, from provider: NSItemProvider, limit: Int) async -> Pages {
        let fromFile: Pages? = await withCheckedContinuation { continuation in
            _ = provider.loadFileRepresentation(for: kind.type, openInPlace: false) { url, _, _ in
                // The file is removed once this returns, so it's read here (on a background queue).
                continuation.resume(returning: url.map { kind.pages(at: $0, limit: limit) })
            }
        }
        if let fromFile {
            return fromFile
        }
        guard let data = await data(of: kind.type, from: provider) else { return ([], 0) }
        return await Task.detached(priority: .userInitiated) {
            kind.pages(in: data, limit: limit)
        }.value
    }

    private static func data(of type: UTType, from provider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { continuation in
            _ = provider.loadDataRepresentation(for: type) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
