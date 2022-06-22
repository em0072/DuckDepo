//
//  NewDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 19/06/2022.
//

import SwiftUI

struct NewDocumentView: View {
    
    @StateObject var viewModel: NewDocumentViewModel
    
    init(document: Document) {
        let viewModel = NewDocumentViewModel(document: document)
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            HStack {
                viewModel.document.documentType.image
                    .frame(width: 35, height: 35)
                VStack(alignment: .leading) {
                    Text(viewModel.document.name)
                    let description = viewModel.document.description
                    if !description.isEmpty {
                        Text(description)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
            .padding(.vertical, 8)
            
            let photos = viewModel.document.photos
            if !photos.isEmpty {
                NewPhotoView(photos: viewModel.document.photos, selectedPhoto: $viewModel.selectedPhoto)
            }
            
            ForEach(viewModel.document.sections) { section in
                Section {
                ForEach(section.fields) { field in
                    if let fieldTitle = field.title, let fieldValue = field.value {
                        FloatingTextView(title: fieldTitle, value: fieldValue)
                    }
                }
                } header: {
                    Text(section.name)
                }
            }
        }
//        .overlay(
//            ZStack {
//                if viewModel.showingImageViewer {
//                    ImageViewer(photos: viewModel.document.photos, selectedImage: viewModel.selectedPhoto, showImageViewer: $viewModel.showingImageViewer)
//                }
//            }
//        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: toolbarView)
        .actionSheet(isPresented: $viewModel.showShareActionSheet, content: shareActionSheetView)
        .sheet(isPresented: $viewModel.showShareSheetView, onDismiss: viewModel.onShareSheetDismiss) {
            ShareSheetView(items: viewModel.itemsToShare)
        }
        .fullScreenCover(isPresented: $viewModel.showEditDocumentView) {
            EditDocumentView(isPresented: $viewModel.showEditDocumentView, type: .existing(viewModel.document))
        }
        .fullScreenCover(isPresented: $viewModel.showingImageViewer, onDismiss: nil) {
            if let selctedPhoto = viewModel.selectedPhoto {
            ImageViewer(photos: viewModel.document.photos, selectedImage: selctedPhoto)
            }
        }
//        .animation(.default, value: viewModel.)

    }
    
//    @ViewBuilder
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
    
    static let testDocument = Document(name: "Document", description: "Bob Macron", documentType: .identification, photos: [UIImage(named: "duck")!], folder: "what is folder?")
    
    static var previews: some View {
        NewDocumentView(document: NewDocumentView_Previews.testDocument)
    }
}
