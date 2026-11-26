//
//  PhotosSectionView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/07/2022.
//

import PhotosUI
import SwiftUI
import VisionKit

protocol PhotosSectionViewDelegate {
    func select(photo: DocumentPhoto)
    func add(photos: [DocumentPhoto])
    func delete(photo: DocumentPhoto)
}

struct PhotosSectionView: View {

    let photos: [DocumentPhoto]
    /// For zooming the viewer out of the tapped photo.
    let namespace: Namespace.ID
    var delegate: PhotosSectionViewDelegate?

    @State private var showingPhotoChooser = false
    @State private var showingCameraView = false
    @State private var showingPhotoPicker = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var cameraImages: [UIImage]?
    @State private var isProcessing = false

    @ScaledMetric(relativeTo: .body) private var cellSize: CGFloat = 96

    var body: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    AddCell {
                        showingPhotoChooser = true
                    }
                    .frame(width: cellSize, height: cellSize)
                    .accessibilityLabel(Text("psv_add_photo"))
                    if isProcessing {
                        ProgressView()
                            .frame(width: cellSize, height: cellSize)
                    }
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        PhotoCell(image: photo.image) {
                            delegate?.select(photo: photo)
                        }
                        .matchedTransitionSource(id: photo.id, in: namespace)
                        .frame(width: width(of: photo), height: cellSize)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                delegate?.delete(photo: photo)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .black.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                            .padding(4)
                            .accessibilityLabel(Text("psv_delete_photo"))
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(Text("photo_n_of_m \(index + 1) \(photos.count)"))
                    }
                }
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            .confirmationDialog("psv_photo_selection_body", isPresented: $showingPhotoChooser, titleVisibility: .visible) {
                if VNDocumentCameraViewController.isSupported {
                    Button("psv_camera") {
                        showingCameraView = true
                    }
                }
                Button("psv_photo_library") {
                    showingPhotoPicker = true
                }
            }
            .photosPicker(isPresented: $showingPhotoPicker, selection: $pickerItems, maxSelectionCount: 10, matching: .images)
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty else { return }
                loadPickedItems(items)
            }
            .fullScreenCover(isPresented: $showingCameraView, onDismiss: onCameraDismiss) {
                CameraPickerView(imageArray: $cameraImages)
                    .ignoresSafeArea()
            }
        } header: {
            Text("psv_photos")
        }
    }

    /// The photo's own shape at the strip's height, as on the document's page.
    private func width(of photo: DocumentPhoto) -> CGFloat {
        let size = photo.image.size
        guard size.height > 0 else { return cellSize }
        return min(max(cellSize * size.width / size.height, cellSize * 0.6), cellSize * 1.8)
    }

    private func loadPickedItems(_ items: [PhotosPickerItem]) {
        pickerItems = []
        isProcessing = true
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            await addEncoded(images)
        }
    }

    private func onCameraDismiss() {
        guard let images = cameraImages, !images.isEmpty else { return }
        cameraImages = nil
        isProcessing = true
        Task {
            await addEncoded(images)
        }
    }

    /// JPEG-encodes off the main thread; scanned pages are large.
    private func addEncoded(_ images: [UIImage]) async {
        let photos = await Task.detached(priority: .userInitiated) {
            images.compactMap(DocumentPhoto.init(image:))
        }.value
        await MainActor.run {
            isProcessing = false
            delegate?.add(photos: photos)
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    Form {
        PhotosSectionView(photos: Document.test.photos, namespace: namespace)
    }
}
