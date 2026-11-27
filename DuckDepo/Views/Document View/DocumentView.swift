//
//  DocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import SwiftUI

struct DocumentView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: DocumentViewModel
    /// The list's copy, to notice changes that arrive from iCloud.
    private let document: Document

    @State private var currentPhotoID: DocumentPhoto.ID?
    @State private var isShowingPhotoViewer = false
    @Namespace private var photoNamespace

    init(document: Document) {
        self.document = document
        _viewModel = State(initialValue: DocumentViewModel(document: document))
    }

    var body: some View {
        List {
            if !viewModel.document.photos.isEmpty {
                Section {
                    PhotoGallery(photos: viewModel.document.photos, selection: $currentPhotoID, namespace: photoNamespace) {
                        isShowingPhotoViewer = true
                    }
                    // On the page itself, not on a card.
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            if let expiryDate = viewModel.document.expiryDate {
                Section {
                    ExpiryRow(expiryDate: expiryDate)
                }
            }
            ForEach(viewModel.document.sectionsWithValues) { section in
                DocSectionSection(section: section)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.document.name)
        .navigationSubtitle(viewModel.document.description)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.load)
        .onChange(of: document) {
            // A change from iCloud or another screen; the first load (onAppear) isn't animated.
            withAnimation {
                viewModel.reload()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                shareMenu
                Button(action: viewModel.editButtonPressed) {
                    Label("edit_button", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $viewModel.showShareSheetView, onDismiss: viewModel.onShareSheetDismiss) {
            ShareSheetView(items: viewModel.itemsToShare)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showEditDocumentView) {
            EditDocumentView(viewModel: viewModel.editDocumentViewModel)
        }
        .fullScreenCover(isPresented: $isShowingPhotoViewer) {
            PhotoViewer(photos: viewModel.document.photos, currentPhotoID: $currentPhotoID)
                .navigationTransition(.zoom(sourceID: currentPhotoID, in: photoNamespace))
        }
        .onChange(of: viewModel.shouldDismissView) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    /// The whole document as text (shared, or copied in one go instead of field by field), or its photos.
    private var shareMenu: some View {
        Menu {
            ShareLink(item: viewModel.document.plainText) {
                Label("dv_share_text", systemImage: "text.alignleft")
            }
            Button("dv_copy_all", systemImage: "doc.on.doc", action: viewModel.copyAllButtonPressed)
            if !viewModel.document.photos.isEmpty {
                Section {
                    Button("dv_share_photo", systemImage: "photo.on.rectangle", action: viewModel.sharePhotosButtonPressed)
                    Button("dv_share_photo_and_text", systemImage: "doc.richtext", action: viewModel.sharePhotosAndTextButtonPressed)
                }
            }
        } label: {
            Label("dv_share_doc_title", systemImage: "square.and.arrow.up")
        }
    }
}

/// When the document expires, flagged when that's soon or past.
private struct ExpiryRow: View {

    let expiryDate: Date

    var body: some View {
        let status = ExpiryStatus(expiryDate: expiryDate)
        LabeledContent {
            Text(FieldDate.displayString(forUTCDay: expiryDate))
        } label: {
            Label {
                Text(status.badgeText ?? String(localized: "expiry_valid"))
            } icon: {
                Image(systemName: status.systemImage)
                    .foregroundStyle(status.color)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
    }
}

#Preview {
    NavigationStack {
        DocumentView(document: Document.test)
    }
}
