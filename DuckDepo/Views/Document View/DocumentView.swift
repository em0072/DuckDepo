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
                    PhotoCarousel(photos: viewModel.document.photos, selection: $currentPhotoID, namespace: photoNamespace) {
                        isShowingPhotoViewer = true
                    }
                    .listRowInsets(EdgeInsets())
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
            viewModel.reload()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: viewModel.shareButtonPressed) {
                    Label("dv_share_doc_title", systemImage: "square.and.arrow.up")
                }
                Button(action: viewModel.editButtonPressed) {
                    Label("edit_button", systemImage: "pencil")
                }
            }
        }
        .confirmationDialog("dv_share_doc_title", isPresented: $viewModel.showShareOptions, titleVisibility: .visible) {
            Button("dv_share_photo_and_text", action: viewModel.sharePhotosAndTextButtonPressed)
            Button("dv_share_photo", action: viewModel.sharePhotosButtonPressed)
            Button("dv_share_text", action: viewModel.shareTextButtonPressed)
        } message: {
            Text("dv_share_doc_body")
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
            }
        }
    }
}

#Preview {
    NavigationStack {
        DocumentView(document: Document.test)
    }
}
