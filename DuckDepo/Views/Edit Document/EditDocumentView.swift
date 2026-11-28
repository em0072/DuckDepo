//
//  EditDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 03/07/2022.
//

import SwiftUI

struct EditDocumentView: View {

    @Environment(\.dismiss) private var dismiss
    @State var viewModel: EditDocumentViewModel
    @State private var isShowingDeleteAlert = false
    @State private var isShowingDiscardDialog = false
    @Namespace private var photoNamespace

    var body: some View {
        NavigationStack {
            Form {
                if let foundNothing = viewModel.scanFoundNothing {
                    ScanBanner(foundNothing: foundNothing)
                }
                TitleView(name: $viewModel.document.name,
                          description: $viewModel.document.description,
                          documentType: $viewModel.document.documentType,
                          personID: $viewModel.document.personID,
                          showsPeople: viewModel.showsPeople,
                          isPersonSuggested: viewModel.isPersonSuggested)
                PhotosSectionView(photos: viewModel.document.photos, namespace: photoNamespace, delegate: viewModel)
                SectionView(sections: $viewModel.document.sections, delegate: viewModel,
                            scanConfidence: viewModel.scanConfidence(for:))
                AddSectionMenu(availableSections: viewModel.availableSections, delegate: viewModel)
                if !viewModel.isNew {
                    Section {
                        Button("delete_document", role: .destructive) {
                            isShowingDeleteAlert = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .onAppear(perform: viewModel.load)
            .navigationTitle(viewModel.viewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close, action: closeButtonAction)
                        .confirmationDialog("discard_changes_title", isPresented: $isShowingDiscardDialog, titleVisibility: .visible) {
                            Button("discard_changes_button", role: .destructive) {
                                dismiss()
                            }
                            Button("keep_editing_button", role: .cancel) {}
                        }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: viewModel.save)
                        .disabled(!viewModel.canSave)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.hasChanges)
        .onChange(of: viewModel.shouldCloseView) { _, shouldClose in
            if shouldClose {
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $viewModel.isShowingPhotoViewer) {
            PhotoViewer(photos: viewModel.document.photos, currentPhotoID: $viewModel.viewerPhotoID)
                .navigationTransition(.zoom(sourceID: viewModel.viewerPhotoID, in: photoNamespace))
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
