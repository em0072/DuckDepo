//
//  AddNewDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/10/2021.
//

import SwiftUI

struct EditDocumentView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject var viewModel: EditDocumentViewModel

    @State private var isShowingDeleteAlert = false
    @State private var isShowingDiscardDialog = false

    var body: some View {
        NavigationStack {
            List {
                TitleView(name: $viewModel.document.name,
                          description: $viewModel.document.description,
                          documentType: $viewModel.document.documentType)
                PhotosSectionView(photos: viewModel.document.photos, delegate: viewModel)
                SectionView(sections: $viewModel.document.sections, options: viewModel.inputOption.sections, delegate: viewModel)
                AddSectionMenu(menuOptions: .constant(viewModel.inputOption.listOfSectionNames()), delegate: viewModel)
                AddButtonView(title: viewModel.saveButtonTitle, action: viewModel.save)
                    .disabled(!viewModel.canSave)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(viewModel.viewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(action: closeButtonAction)
                        .confirmationDialog("discard_changes_title", isPresented: $isShowingDiscardDialog, titleVisibility: .visible) {
                            Button("discard_changes_button", role: .destructive) {
                                dismiss()
                            }
                            Button("keep_editing_button", role: .cancel) {}
                        }
                }
                if !viewModel.isNew {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingDeleteAlert = true
                        } label: {
                            Label("delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.hasChanges)
        .onChange(of: viewModel.shouldCloseView) { _, shouldClose in
            if shouldClose {
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingImageViewer) {
            if let photo = viewModel.imageViewerPhoto {
                ImageViewer(photos: viewModel.document.photos.map(\.image), selectedImage: photo.image)
            }
        }
        .alert("save_failed_title", isPresented: $viewModel.saveFailed) {
            Button("Ok", role: .cancel) {}
        } message: {
            Text("save_failed_body")
        }
        .alert("delete_confirmation_title", isPresented: $isShowingDeleteAlert) {
            Button("delete", role: .destructive, action: viewModel.delete)
        } message: {
            Text("delete_confirmation_body")
        }
    }

    private func closeButtonAction() {
        if viewModel.hasChanges {
            isShowingDiscardDialog = true
        } else {
            dismiss()
        }
    }
}

#Preview {
    EditDocumentView(viewModel: EditDocumentViewModel(type: .existing(Document.test)))
}
