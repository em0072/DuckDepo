//
//  NewDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import SwiftUI

struct DocumentView: View {
    
    @StateObject var viewModel: DocumentViewModel
    
    init(document: Document) {
        let viewModel = DocumentViewModel(document: document)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            List {
                DocPhotoSection(photos: viewModel.document.photos, selectedPhoto: $viewModel.selectedPhoto)
                
                ForEach(viewModel.document.sections) { section in
                    DocSectionSection(section: section)
                }
            }
            .listStyle(.insetGrouped)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    viewModel.document.documentType.image
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, viewModel.document.documentType.iconColor)
                        .frame(width: 35, height: 35)
                    
                    VStack {
                        Text(viewModel.document.name)
                            .foregroundColor(.primary)
                            .bold()
                        Text(viewModel.document.description)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: toolbarView)
        .actionSheet(isPresented: $viewModel.showShareActionSheet, content: shareActionSheetView)
        .sheet(isPresented: $viewModel.showShareSheetView, onDismiss: viewModel.onShareSheetDismiss) {
            ShareSheetView(items: viewModel.itemsToShare)
                .presentationDetents([.medium,.large])
        }
        .fullScreenCover(isPresented: $viewModel.showEditDocumentView) {
            EditDocumentView(type: .existing(viewModel.document))
        }
        .fullScreenCover(isPresented: $viewModel.showingImageViewer, onDismiss: nil) {
            if let selctedPhoto = viewModel.selectedPhoto {
                ImageViewer(photos: viewModel.document.photos, selectedImage: selctedPhoto)
            }
        }
        
    }
    
    private func toolbarView() -> some ToolbarContent {
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
    
    private func shareActionSheetView() -> ActionSheet {
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

struct NewDocumentView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            DocumentView(document: Document.test)
        }
    }
}
