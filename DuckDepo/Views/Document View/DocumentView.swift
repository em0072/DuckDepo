//
//  NewDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import SwiftUI

struct DocumentView: View {
    
    @Environment(\.dismiss) private var dismiss

    @StateObject var viewModel: DocumentViewModel
    
    init(document: Document) {
        let viewModel = DocumentViewModel(document: document)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        
                List {
                    DocPhotoSection(photos: viewModel.document.photos, selectedPhoto: $viewModel.selectedPhoto)
                                            
                    ForEach(viewModel.document.sections) { section in
                        DocSectionSection(section: section)
                    }
                }
            .listStyle(.insetGrouped)
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
        .actionSheet(isPresented: $viewModel.showShareActionSheet) { shareActionSheetView }
        .sheet(isPresented: $viewModel.showShareSheetView, onDismiss: viewModel.onShareSheetDismiss) {
            ShareSheetView(items: viewModel.itemsToShare)
                .presentationDetents([.medium,.large])
        }
        .fullScreenCover(isPresented: $viewModel.showEditDocumentView) {
            EditDocumentView(viewModel: viewModel.editDocumentViewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showingImageViewer, onDismiss: nil) {
            if let selctedPhoto = viewModel.selectedPhoto {
                ImageViewer(photos: viewModel.document.photos, selectedImage: selctedPhoto)
            }
        }
        .onChange(of: viewModel.shouldDismissView, perform: dismissAction)
    }
    
    private func dismissAction(_ shouldDismissView: Bool) {
        if shouldDismissView {
            dismiss()
        }
    }
    
    //    private func iconForShareButton() -> some View {
    //        Image(systemName: viewModel.isShared(document) ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.plus")
    //            .renderingMode(.original)
    //    }
    //
    //    private func shareView() -> CloudSharingView? {
    //        guard let share = viewModel.activeShare, let container = viewModel.activeContainer else {
    //            return nil
    //        }
    //        return CloudSharingView(container: container, share: share)
    //    }
    
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
            
            VStack {
                Text(name)
                    .foregroundColor(.primary)
                    .bold()
                Text(description)
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension DocumentView {
    private var toolbarView: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            //MARK:  For Now it is not possible to use it - there is a bug in the NSPersistanceCloudKitController that is prevent database of deleteing created earlier share when the user taps "unshare". As a result, even though share is unshared, UI will always be as it is shared. So we wait for the bugfix from Apple.
            //                Button(action: shareAction, label: iconForShareButton)
            //                    .sheet(isPresented: $viewModel.isCloudSharing, content: shareView)
            Button(action: viewModel.shareButtonPressed) {
                Image(systemName: "square.and.arrow.up")
            }
            Button(action: viewModel.editButtonPressed) {
                Image(systemName: "pencil")
            }
            .disabled(!viewModel.editAllowed())
        }
    }
    
    private var shareActionSheetView: ActionSheet {
        ActionSheet(title: Text("dv_share_doc_title"),
                    message: Text("dv_share_doc_body"),
                    buttons: [
                        //MARK: Doesn't work for some reason - only single object can be shared
                        .default(Text("dv_share_photo_and_text"), action: viewModel.sharePhotosAndTextButtonPressed),
                        .default(Text("dv_share_photo"), action: viewModel.sharePhotosButtonPressed),
                        .default(Text("dv_share_text"), action: viewModel.shareTextButtonPressed),
                        .cancel()
                    ])
    }
}

struct NewDocumentView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            DocumentView(document: Document.test)
        }
    }
}
