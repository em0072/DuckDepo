//
//  ShareTests.swift
//  DuckDepoTests
//

import CoreData
import Foundation
import ImageIO
import PDFKit
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import DuckDepo

private func pdfData(pages: Int, size: CGSize = CGSize(width: 595, height: 842), blank: Bool = false) -> Data {
    UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: size)).pdfData { context in
        for page in 0..<pages {
            context.beginPage()
            if !blank {
                ("Page \(page + 1)" as NSString).draw(at: CGPoint(x: 72, y: 72),
                                                      withAttributes: [.font: UIFont.systemFont(ofSize: 36)])
            }
        }
    }
}

private func jpegData(width: Int, height: Int) -> Data {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).jpegData(withCompressionQuality: 0.8) { context in
        UIColor.systemTeal.setFill()
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
}

/// The colour of one pixel of a stored photo, as red, green, blue from 0 to 255.
private func pixel(of photo: DocumentPhoto, x: Int, y: Int) -> [Int] {
    let source = CGImageSourceCreateWithData(photo.data as CFData, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    var bytes = [UInt8](repeating: 0, count: 4)
    let context = CGContext(data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Core Graphics counts rows from the bottom.
    context.draw(image, in: CGRect(x: -x, y: y - image.height + 1, width: image.width, height: image.height))
    return bytes.prefix(3).map(Int.init)
}

struct PageImportTests {

    @Test func largeImagesAreScaledDownWhileRead() throws {
        let photo = try #require(PageImport.photo(fromImageData: jpegData(width: 6000, height: 4000)))
        let size = try #require(UIImage(data: photo.data)).size
        #expect(max(size.width, size.height) == DocumentPhoto.maxPixelSize)
        #expect(size.width > size.height)
        #expect(photo.size == size)
    }

    @Test func eachPDFPageBecomesAPhoto() throws {
        let result = PageImport.photos(fromPDFData: pdfData(pages: 3))
        #expect(result.pageCount == 3)
        #expect(result.photos.count == 3)
        let size = try #require(UIImage(data: result.photos[0].data)).size
        #expect(max(size.width, size.height) == DocumentPhoto.maxPixelSize)
        // Portrait pages stay portrait.
        #expect(size.height > size.width)
        // Different pages, different photos.
        #expect(Set(result.photos.map(\.id)).count == 3)
    }

    @Test func pagesPastTheLimitAreLeftOut() {
        let result = PageImport.photos(fromPDFData: pdfData(pages: 5), limit: 2)
        #expect(result.photos.count == 2)
        #expect(result.pageCount == 5)
    }

    @Test func whatIsntAPDFGivesNothing() {
        #expect(PageImport.photos(fromPDFData: Data("not a pdf".utf8)).photos.isEmpty)
        #expect(PageImport.photo(fromImageData: Data("not an image".utf8)) == nil)
    }

    @Test func aPDFPageIsCutToItsCropBox() throws {
        // A blue page with a red area; the crop box is the red area.
        let media = CGRect(x: 0, y: 0, width: 600, height: 800)
        let crop = CGRect(x: 100, y: 100, width: 200, height: 300)
        let pdf = try #require(PDFDocument(data: UIGraphicsPDFRenderer(bounds: media).pdfData { context in
            context.beginPage()
            UIColor.blue.setFill()
            context.fill(media)
            UIColor.red.setFill()
            // UIKit's origin is at the top left; the crop box's is at the bottom left.
            context.fill(CGRect(x: crop.minX, y: media.height - crop.maxY, width: crop.width, height: crop.height))
        }))
        pdf.page(at: 0)?.setBounds(crop, for: .cropBox)
        let data = try #require(pdf.dataRepresentation())

        let photo = try #require(PageImport.photos(fromPDFData: data).photos.first)
        #expect(abs(photo.size.width / photo.size.height - crop.width / crop.height) < 0.01)
        let corner = pixel(of: photo, x: 3, y: 3)
        #expect(corner[0] > 200 && corner[2] < 60, "the corner is \(corner), not red")
    }

    @Test func longPagesStayReadable() throws {
        // A Safari full-page screenshot, saved as a PDF.
        let page = try #require(PageImport.photos(fromPDFData: pdfData(pages: 1, size: CGSize(width: 390, height: 12000))).photos.first)
        #expect(page.size.width >= 300)
        #expect(max(page.size.width, page.size.height) <= DocumentPhoto.maxLongSide)
        // A long screenshot.
        let image = try #require(PageImport.photo(fromImageData: jpegData(width: 1179, height: 8000)))
        #expect(image.size.width >= 600)
    }

    @Test func transparentImagesAreOnWhite() throws {
        // A PNG of a black square on a transparent background.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let png = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200), format: format).pngData { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 50, y: 50, width: 100, height: 100))
        }
        let photo = try #require(PageImport.photo(fromImageData: png))
        #expect(pixel(of: photo, x: 5, y: 5).allSatisfy { $0 > 240 })
        #expect(pixel(of: photo, x: 100, y: 100).allSatisfy { $0 < 30 })
    }

    @Test func eachPageOfATIFFIsKept() throws {
        let output = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(output, UTType.tiff.identifier as CFString, 3, nil))
        for color in [UIColor.red, .green, .blue] {
            let image = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 80)).image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 60, height: 80))
            }
            CGImageDestinationAddImage(destination, try #require(image.cgImage), nil)
        }
        #expect(CGImageDestinationFinalize(destination))

        let all = PageImport.photos(fromImageData: output as Data)
        #expect(all.photos.count == 3)
        #expect(all.pageCount == 3)
        let some = PageImport.photos(fromImageData: output as Data, limit: 2)
        #expect(some.photos.count == 2)
        #expect(some.pageCount == 3)
    }

    @Test func providersAreReadInOrderUpToTheLimit() async {
        let image = NSItemProvider(item: jpegData(width: 300, height: 200) as NSData, typeIdentifier: "public.jpeg")
        let pdf = NSItemProvider(item: pdfData(pages: 3) as NSData, typeIdentifier: "com.adobe.pdf")
        let text = NSItemProvider(item: "hello" as NSString, typeIdentifier: "public.plain-text")
        let result = await PageImport.photos(from: [image, text, pdf], limit: 3)
        #expect(result.photos.count == 3)
        #expect(result.isTruncated)
        let all = await PageImport.photos(from: [image, pdf], limit: 10)
        #expect(all.photos.count == 4)
        #expect(!all.isTruncated)
    }

    @Test func identicalPagesAreKeptOnce() async {
        // Two blank separator pages, and the same picture shared twice.
        let blanks = NSItemProvider(item: pdfData(pages: 2, blank: true) as NSData, typeIdentifier: "com.adobe.pdf")
        let picture = jpegData(width: 300, height: 200)
        let first = NSItemProvider(item: picture as NSData, typeIdentifier: "public.jpeg")
        let again = NSItemProvider(item: picture as NSData, typeIdentifier: "public.jpeg")
        let result = await PageImport.photos(from: [blanks, first, again], limit: 10)
        #expect(result.photos.count == 2)
        #expect(Set(result.photos.map(\.id)).count == 2)
        #expect(!result.isTruncated)
    }
}

struct DocumentPhotoMemoryTests {

    @Test func aPhotoDecodesItsImageOnlyWhenAsked() {
        let photo = DocumentPhoto.sample(width: 120, height: 80)
        #expect(photo.size == CGSize(width: 120, height: 80))
        // A new image each time, so a decoded one goes away with whoever drew it.
        #expect(photo.image !== photo.image)
    }

    @Test func stripCopiesAreSharpEnoughForTheirCell() throws {
        let photo = DocumentPhoto.sample(width: 1600, height: 900)
        // A 16:9 photo in a 96 pt high, 1.8 times wide cell on a 3x screen.
        let cell = CGSize(width: 96 * 1.8, height: 96)
        let image = PhotoThumbnails.image(for: photo, filling: cell, scale: 3)
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        #expect(pixels.width >= cell.width * 3 - 1)
        #expect(pixels.height >= cell.height * 3 - 1)
        // Never larger than the photo.
        #expect(PhotoThumbnails.pixelSize(of: photo, filling: CGSize(width: 2000, height: 2000), scale: 3) == 1600)
    }
}

@MainActor
struct SharedPagesStorageTests {

    @Test func pagesAreAddedWithoutTouchingTheRest() throws {
        let database = TestStack.makeDatabase()
        let first = DocumentPhoto.sample(color: .red)
        let second = DocumentPhoto.sample(color: .blue)
        var info = SectionKey.documentInfo.makeSection()
        info.fields[0].value = "AB123"
        info.fields[3].value = "2031-05-01"
        let document = Document(name: "Passport", description: "Jane Duck", documentType: .identification,
                                photos: [first], sections: [info])
        database.save(document)
        let stored = try #require(database.fetchFromDB(document))
        let sections = Set(stored.getSections().map(\.objectID))
        let fields = Set(stored.getSections().flatMap { $0.getAllFields() }.map(\.objectID))
        let expiresAt = stored.expiresAt

        // The one it has isn't added twice, nor one shared twice.
        #expect(database.addPhotos([first, second, second], toDocumentWith: document.id) == .saved)

        let after = try #require(database.fetchFromDB(document))
        #expect(after.photos().map(\.id) == [first.id, second.id])
        // The same section and field records: nothing was deleted and made again.
        #expect(Set(after.getSections().map(\.objectID)) == sections)
        #expect(Set(after.getSections().flatMap { $0.getAllFields() }.map(\.objectID)) == fields)
        #expect(after.expiresAt == expiresAt)
        let full = try #require(database.fullDocument(with: document.id))
        #expect(full.sections.first?.fields[0].value == "AB123")
        #expect(full.name == "Passport")
        // Version 2.6's copy has the new page too, and the records match it.
        #expect(after.photoDataItems() == [first.data, second.data])
        #expect(after.legacyPhotosKey == DDDocument.legacyPhotosKey(for: [first.data, second.data]))
        #expect(after.photoRecordList().map(\.identifier) == [first.id, second.id])

        #expect(database.addPhotos([second], toDocumentWith: UUID()) == .failed)
    }

    @Test func photosOnlyInTheOldCopyAreKept() throws {
        let database = TestStack.makeDatabase()
        let first = DocumentPhoto.sample(color: .red)
        let second = DocumentPhoto.sample(color: .blue)
        let document = Document(name: "Insurance", documentType: .medicine)
        database.save(document)
        // Version 2.6 added a photo, and its records haven't been made yet.
        let stored = try #require(database.fetchFromDB(document))
        stored.setPhotosLikeVersion26([first])
        #expect(database.save())

        #expect(database.addPhotos([second], toDocumentWith: document.id) == .saved)
        let after = try #require(database.fetchFromDB(document))
        #expect(after.photos().map(\.id) == [first.id, second.id])
        #expect(after.photoDataItems() == [first.data, second.data])
    }

    @Test func aDocumentWithTooManyPhotosIsLeftAlone() throws {
        let database = TestStack.makeDatabase()
        let first = DocumentPhoto.sample(color: .red)
        let document = Document(name: "Manual", documentType: .other, photos: [first])
        database.save(document)

        let result = database.addPhotos([DocumentPhoto.sample(color: .blue)], toDocumentWith: document.id,
                                        maximumExistingBytes: first.data.count - 1)
        #expect(result == .tooLarge)
        #expect(try #require(database.fetchFromDB(document)).photos().map(\.id) == [first.id])
    }

    @Test func theAppMergesWhatTheExtensionsWrite() {
        let predicate = PersistenceController.extensionTransactions
        #expect(predicate.evaluate(with: ["author": PersistenceController.Role.share.transactionAuthor]))
        #expect(predicate.evaluate(with: ["author": PersistenceController.Role.autoFill.transactionAuthor]))
        #expect(!predicate.evaluate(with: ["author": PersistenceController.Role.app.transactionAuthor]))
    }
}

struct DocumentTextTests {

    @Test func plainTextHasTheNameDescriptionAndFilledInFields() {
        var info = SectionKey.documentInfo.makeSection()
        info.fields[0].value = "AB123"
        info.fields[3].value = "2031-05-01"
        let empty = DocSection(name: "Empty", fields: [Field(title: "Nothing")])
        let document = Document(name: "Passport", description: "Jane Duck", documentType: .identification,
                                sections: [info, empty])
        let lines = document.plainText.components(separatedBy: "\n")
        #expect(lines.first == "Passport")
        #expect(lines.contains("Jane Duck"))
        #expect(lines.contains(SectionKey.documentInfo.localizedName))
        #expect(lines.contains("\(FieldKey.number.localizedName): AB123"))
        #expect(lines.contains("\(FieldKey.expiryDate.localizedName): \(FieldDate.displayString(for: "2031-05-01"))"))
        #expect(!document.plainText.contains("Empty"))
        #expect(!document.plainText.contains("DuckDepo.com"))
    }

    @Test func aDocumentWithOnlyANameIsJustItsName() {
        #expect(Document(name: "Card").plainText == "Card")
    }
}
