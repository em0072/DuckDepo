//
//  PhotoViewer.swift
//  DuckDepo
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Photos full screen: swipe between them, pinch or double-tap to zoom, swipe down to close. Present it
/// with a zoom transition from the photo it opens on.
struct PhotoViewer: View {

    let photos: [DocumentPhoto]
    /// The photo on screen. Shared with the screen that opened the viewer, so closing it zooms back into
    /// the photo the user ended on.
    @Binding var currentPhotoID: DocumentPhoto.ID?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverRunning
    @State private var areControlsHidden = false
    @State private var isShowingCopied = false

    var body: some View {
        NavigationStack {
            // A paging scroll view rather than a page-style TabView, which starts its pages below the
            // top of the screen.
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        ZoomableImage(photo: photo, isLoaded: abs(index - currentIndex) <= 1,
                                      onTap: toggleControls, onPullToClose: { dismiss() })
                            .containerRelativeFrame([.horizontal, .vertical])
                            .accessibilityElement()
                            .accessibilityLabel(Text("photo_n_of_m \(index + 1) \(photos.count)"))
                            .accessibilityAddTraits(.isImage)
                            .id(photo.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentPhotoID)
            .scrollIndicators(.hidden)
            .scrollEdgeEffectHidden(true, for: .all)
            .ignoresSafeArea()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarVisibility(areControlsVisible ? .visible : .hidden, for: .navigationBar, .bottomBar)
        }
        // Dark for the viewer only. `preferredColorScheme` would also switch the screen underneath to dark
        // for a moment while the viewer opens, so the app blinks black in light mode.
        .environment(\.colorScheme, .dark)
        .statusBarHidden(!areControlsVisible)
        .accessibilityAction(.escape) {
            dismiss()
        }
        .pillNotification(text: "copied_notification".localized(), show: $isShowingCopied)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
                dismiss()
            }
        }
        if let photo = currentPhoto {
            ToolbarItem(placement: .bottomBar) {
                ShareLink(item: SharedPhoto(data: photo.data),
                          preview: SharePreview(Text("dv_photos"),
                                                image: Image(uiImage: PhotoThumbnails.image(for: photo, filling: CGSize(width: 64, height: 64), scale: 3)))) {
                    Label("pv_share_alert_button", systemImage: "square.and.arrow.up")
                }
            }
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                Button {
                    ClipboardController.shared.copy(image: photo.image)
                    isShowingCopied = true
                } label: {
                    Label("dv_copy_to_clipboard", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private var currentPhoto: DocumentPhoto? {
        photos.first { $0.id == currentPhotoID } ?? photos.first
    }

    private var currentIndex: Int {
        photos.firstIndex { $0.id == currentPhotoID } ?? 0
    }

    private var title: Text {
        guard photos.count > 1, let index = photos.firstIndex(where: { $0.id == currentPhotoID }) else {
            return Text(verbatim: "")
        }
        return Text("photo_counter \(index + 1) \(photos.count)")
    }

    /// VoiceOver users always get the controls: they can't see the photo to tap it.
    private var areControlsVisible: Bool {
        !areControlsHidden || isVoiceOverRunning
    }

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            areControlsHidden.toggle()
        }
    }
}

/// Shares the photo's own JPEG rather than a re-encoded copy.
private struct SharedPhoto: Transferable {

    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { $0.data }
            .suggestedFileName("Photo.jpg")
    }
}

private struct ZoomableImage: UIViewRepresentable {

    let photo: DocumentPhoto
    /// Only the photo on screen and its neighbours hold their full-size image: a decoded page takes
    /// about 20 MB.
    let isLoaded: Bool
    let onTap: () -> Void
    let onPullToClose: () -> Void

    func makeUIView(context: Context) -> ZoomingImageScrollView {
        let view = ZoomingImageScrollView()
        showImage(in: view)
        return view
    }

    func updateUIView(_ view: ZoomingImageScrollView, context: Context) {
        view.onTap = onTap
        view.onPullToClose = onPullToClose
        showImage(in: view)
    }

    private func showImage(in view: ZoomingImageScrollView) {
        let shown = isLoaded ? photo.id : nil
        guard view.photoID != shown else { return }
        view.photoID = shown
        view.image = isLoaded ? photo.image : nil
    }
}

/// One photo that fits the screen at zoom 1 and zooms up to its full resolution.
final class ZoomingImageScrollView: UIScrollView, UIScrollViewDelegate {

    var onTap: (() -> Void)?
    var onPullToClose: (() -> Void)?
    /// The photo whose image is shown, if any.
    var photoID: DocumentPhoto.ID?

    var image: UIImage? {
        get { imageView.image }
        set {
            imageView.image = newValue
            fittedBoundsSize = .zero
            setNeedsLayout()
        }
    }

    /// How far, in points, the photo has to be pulled down to close the viewer.
    private static let pullToCloseDistance: CGFloat = 100
    private static let doubleTapZoom: CGFloat = 3

    private let imageView = UIImageView()
    /// The size the photo was last fitted to, to fit it again only when the size changes (rotation).
    private var fittedBoundsSize: CGSize = .zero

    init() {
        super.init(frame: .zero)
        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        decelerationRate = .fast
        bouncesZoom = true
        // Lets the photo be pulled down at zoom 1, to close the viewer.
        alwaysBounceVertical = true
        // No dimming under the bars: the photo should show edge to edge.
        topEdgeEffect.isHidden = true
        bottomEdgeEffect.isHidden = true
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(singleTap)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isZoomedIn: Bool {
        zoomScale > minimumZoomScale + 0.01
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != fittedBoundsSize {
            fittedBoundsSize = bounds.size
            fitImage()
        }
    }

    /// Fits the photo to the screen at zoom 1. A new screen size starts over at zoom 1.
    private func fitImage() {
        guard let image = imageView.image, image.size.width > 0, image.size.height > 0,
              bounds.width > 0, bounds.height > 0 else { return }
        minimumZoomScale = 1
        zoomScale = 1
        let fitScale = min(bounds.width / image.size.width, bounds.height / image.size.height)
        let fitted = CGSize(width: image.size.width * fitScale, height: image.size.height * fitScale)
        imageView.frame = CGRect(origin: .zero, size: fitted)
        contentSize = fitted
        // Up to the photo's own pixels, and at least 3×, so small print is readable.
        let pixelsPerPoint = image.size.width * image.scale / (fitted.width * traitCollection.displayScale)
        maximumZoomScale = max(Self.doubleTapZoom, pixelsPerPoint)
        centerImage()
    }

    /// Keeps a photo smaller than the screen in its middle.
    private func centerImage() {
        let horizontal = max(0, (bounds.width - contentSize.width) / 2)
        let vertical = max(0, (bounds.height - contentSize.height) / 2)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImage()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard !isZoomedIn else { return }
        // Positive while pulled down. Velocity is negative when the finger moves down.
        let pull = -(contentOffset.y + contentInset.top)
        if pull > Self.pullToCloseDistance || (pull > 30 && velocity.y < -1) {
            onPullToClose?()
        }
    }

    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        if isZoomedIn {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            // Zooms in on the tapped spot.
            let point = recognizer.location(in: imageView)
            let scale = min(maximumZoomScale, Self.doubleTapZoom)
            let size = CGSize(width: bounds.width / scale, height: bounds.height / scale)
            zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                            width: size.width, height: size.height), animated: true)
        }
    }

    @objc private func handleSingleTap() {
        onTap?()
    }
}

#Preview {
    @Previewable @State var currentPhotoID: DocumentPhoto.ID?
    PhotoViewer(photos: Document.test.photos, currentPhotoID: $currentPhotoID)
}
