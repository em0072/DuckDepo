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
                    if remainingPhotos > 0 {
                        AddCell {
                            #if SHARE_EXTENSION
                            // Extensions can't use the camera: nothing to choose between.
                            showingPhotoPicker = true
                            #else
                            showingPhotoChooser = true
                            #endif
                        }
                        .frame(width: cellSize, height: cellSize)
                        .accessibilityLabel(Text("psv_add_photo"))
                    }
                    if isProcessing {
                        ProgressView()
                            .frame(width: cellSize, height: cellSize)
                    }
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        let size = CGSize(width: width(of: photo), height: cellSize)
                        PhotoCell(photo: photo, size: size) {
                            delegate?.select(photo: photo)
                        }
                        .matchedTransitionSource(id: photo.id, in: namespace)
                        .frame(width: size.width, height: size.height)
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
            #if !SHARE_EXTENSION
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
            #endif
            .photosPicker(isPresented: $showingPhotoPicker, selection: $pickerItems,
                          maxSelectionCount: min(10, max(1, remainingPhotos)), matching: .images)
            .onChange(of: pickerItems) { _, items in
                guard !items.isEmpty else { return }
                loadPickedItems(items)
            }
            #if !SHARE_EXTENSION
            .fullScreenCover(isPresented: $showingCameraView, onDismiss: onCameraDismiss) {
                CameraPickerView(imageArray: $cameraImages)
                    .ignoresSafeArea()
            }
            #endif
        } header: {
            Text("psv_photos")
        }
    }

    /// How many more photos can be added. The share extension takes no more than it takes from a share:
    /// it has little memory.
    private var remainingPhotos: Int {
        #if SHARE_EXTENSION
        PageImport.maximumSharedPages - photos.count
        #else
        .max
        #endif
    }

    /// The photo's own shape at the strip's height, as on the document's page.
    private func width(of photo: DocumentPhoto) -> CGFloat {
        let size = photo.size
        guard size.height > 0 else { return cellSize }
        return min(max(cellSize * size.width / size.height, cellSize * 0.6), cellSize * 1.8)
    }

    /// One at a time, each read at the size it's stored at: a photo decoded at full size takes about
    /// 100 MB, more than the share extension has.
    private func loadPickedItems(_ items: [PhotosPickerItem]) {
        pickerItems = []
        withAnimation {
            isProcessing = true
        }
        Task {
            var photos: [DocumentPhoto] = []
            for item in items.prefix(max(0, remainingPhotos)) {
                guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                let photo = await Task.detached(priority: .userInitiated) {
                    PageImport.photo(fromImageData: data)
                }.value
                if let photo {
                    photos.append(photo)
                }
            }
            withAnimation {
                isProcessing = false
                delegate?.add(photos: photos)
            }
        }
    }

    private func onCameraDismiss() {
        guard let images = cameraImages, !images.isEmpty else { return }
        cameraImages = nil
        withAnimation {
            isProcessing = true
        }
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
            withAnimation {
                isProcessing = false
                delegate?.add(photos: photos)
            }
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace
    Form {
        PhotosSectionView(photos: Document.test.photos, namespace: namespace)
    }
}
