//
//  NewDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import SwiftUI

struct DocumentView: View {

    @Environment(\.dismiss) private var dismiss

    @State var viewModel: DocumentViewModel

    init(document: Document) {
        _viewModel = State(initialValue: DocumentViewModel(document: document))
    }

    var body: some View {
        List {
            DocPhotoSection(photos: viewModel.document.photos, selectedPhoto: $viewModel.selectedPhoto)
            ForEach(viewModel.document.sectionsWithValues) { section in
                DocSectionSection(section: section)
            }
        }
        .listStyle(.insetGrouped)
        .onAppear(perform: viewModel.load)
        .toolbar {
            ToolbarItem(placement: .principal) {
                DocumentToolbarTitleView(icon: viewModel.document.documentType.image,
                                         iconColor: viewModel.document.documentType.iconColor,
                                         name: viewModel.document.name,
                                         description: viewModel.document.description)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarView }
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
        .fullScreenCover(isPresented: $viewModel.showEditDocumentView) {
            EditDocumentView(viewModel: viewModel.editDocumentViewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showingImageViewer, onDismiss: { viewModel.selectedPhoto = nil }) {
            if let selectedPhoto = viewModel.selectedPhoto {
                ImageViewer(photos: viewModel.document.photos.map(\.image), selectedImage: selectedPhoto.image)
            }
        }
        .onChange(of: viewModel.shouldDismissView) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
}

private struct DocumentToolbarTitleView: View {

    let icon: Image
    let iconColor: Color
    let name: String
    let description: String

    var body: some View {
        HStack {
            icon
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, iconColor)
                .frame(width: 35, height: 35)
                .accessibilityHidden(true)
            VStack {
                Text(name)
                    .foregroundStyle(.primary)
                    .bold()
                if !description.isEmpty {
                    Text(description)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

extension DocumentView {
    private var toolbarView: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: viewModel.shareButtonPressed) {
                Label("dv_share_doc_title", systemImage: "square.and.arrow.up")
            }
            Button(action: viewModel.editButtonPressed) {
                Label("edit_button", systemImage: "pencil")
            }
            .disabled(!viewModel.editAllowed())
        }
    }
}

#Preview {
    NavigationStack {
        DocumentView(document: Document.test)
    }
}
