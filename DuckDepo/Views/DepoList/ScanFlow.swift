//
//  ScanFlow.swift
//  DuckDepo
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import VisionKit

/// Where a scan's pages come from.
enum ScanSource: Identifiable {
    case camera
    case photos
    case files

    var id: Self { self }

    static var isCameraAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }
}

extension View {
    /// Gets pages from `source`, reads them on the device, and hands back a draft to review.
    func scanFlow(source: Binding<ScanSource?>, onDraft: @escaping (ScanDraft) -> Void) -> some View {
        modifier(ScanFlow(source: source, onDraft: onDraft))
    }
}

private struct ScanFlow: ViewModifier {

    /// At most this many pages from Photos or Files.
    private static let maximumPages = 10

    @Binding var source: ScanSource?
    let onDraft: (ScanDraft) -> Void

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var cameraImages: [UIImage]?
    @State private var isReading = false

    func body(content: Content) -> some View {
        content
            .onChange(of: source) { _, source in
                if source != nil {
                    ModelExtractor.prewarm()
                }
            }
            .disabled(isReading)
            .overlay {
                // Animated here only: the editor the scan opens has its own presentation.
                ZStack {
                    if isReading {
                        ReadingOverlay()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isReading)
            }
            .fullScreenCover(isPresented: isPresenting(.camera), onDismiss: readCameraPages) {
                CameraPickerView(imageArray: $cameraImages)
                    .ignoresSafeArea()
            }
            .photosPicker(isPresented: isPresenting(.photos), selection: $pickerItems,
                          maxSelectionCount: Self.maximumPages, matching: .images)
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty else { return }
                pickerItems = []
                read { await Self.images(from: items) }
            }
            .fileImporter(isPresented: isPresenting(.files), allowedContentTypes: [.pdf, .image],
                          allowsMultipleSelection: true) { result in
                guard case .success(let urls) = result, !urls.isEmpty else { return }
                read { await Task.detached(priority: .userInitiated) { Self.images(from: urls) }.value }
            }
    }

    private func isPresenting(_ value: ScanSource) -> Binding<Bool> {
        Binding {
            source == value
        } set: { isPresented in
            if !isPresented, source == value {
                source = nil
            }
        }
    }

    private func readCameraPages() {
        guard let images = cameraImages, !images.isEmpty else { return }
        cameraImages = nil
        read { images }
    }

    private func read(_ loadImages: @escaping () async -> [UIImage]) {
        isReading = true
        Task {
            let images = await loadImages()
            guard !images.isEmpty else {
                isReading = false
                return
            }
            let draft = await DocumentScanner.draft(from: images)
            isReading = false
            onDraft(draft)
        }
    }

    private static func images(from items: [PhotosPickerItem]) async -> [UIImage] {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                images.append(image)
            }
        }
        return images
    }

    /// Images as they are, and PDFs as their first pages.
    private static func images(from urls: [URL]) -> [UIImage] {
        var images: [UIImage] = []
        for url in urls where images.count < maximumPages {
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            if UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) == true {
                images += DocumentReader.pages(ofPDF: url, maximumPages: maximumPages - images.count)
            } else if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                images.append(image)
            }
        }
        return images
    }
}

/// Shown while the pages are read, which takes a second or two.
private struct ReadingOverlay: View {

    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("scan_reading")
                    .font(.headline)
            }
            .padding(28)
            .glassEffect(in: .rect(cornerRadius: 28))
            .accessibilityElement(children: .combine)
        }
    }
}
