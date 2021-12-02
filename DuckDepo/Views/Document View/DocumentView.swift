//
//  DocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import SwiftUI
import ImageViewer
import CoreData


struct DocumentView: View {

    @ObservedObject var document: DDDocument
    @StateObject var viewModel: ViewModel = ViewModel()
    
    @State private var imageViewerImage: Image?
    @State private var showingImageViewer = false
    @State private var isEditingDocumentView = false
    @State private var showShareActionSheet = false
    @State private var showShareSheetView = false

    var body: some View {
        List {
            Section {
                Text(document.name ?? "")
            } header: {
                Text("dv_doc_name")
            }
            
            PhotosView(document: document, imageViewerImage: $imageViewerImage, showingImageViewer: $showingImageViewer)
            
            ForEach(document.getSections()) { section in
                Section {
                ForEach(section.getAllFields()) { field in
                    if let fieldTitle = field.title, let fieldValue = field.value {
                        FloatingTextView(title: fieldTitle, value: fieldValue)
                    }
                }
                } header: {
                    Text(section.name ?? "")
                }
            }
        }
        
        .navigationBarTitle(Text(document.name ?? ""))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
//MARK:  For Now it is not possible to use it - there is a bug in the NSPersistanceCloudKitController that is prevent database of deleteing created earlier share when the user taps "unshare". As a result, even though share is unshared, UI will always be as it is shared. So we wait for the bugfix from Apple.
//                Button(action: shareAction, label: iconForShareButton)
//                    .sheet(isPresented: $viewModel.isCloudSharing, content: shareView)
                Button(action: shareInfo) {
                    Image(systemName: "square.and.arrow.up")
                }
                .actionSheet(isPresented: $showShareActionSheet, content: {
                        ActionSheet(title: Text("dv_share_doc_title"),
                                message: Text("dv_share_doc_body"),
                                    buttons: [
                                        //MARK: Doesn't work for some reason - only single object can be shared
//                                        .default(Text("dv_share_photo_and_text")) {
//                                            sharePhotosAndText()
//                                        },
                                        .default(Text("dv_share_photo")) {
                                            sharePhotos()
                                        },
                                        .default(Text("dv_share_text")) {
                                            shareText()
                                        },
                                        .cancel()
                                    ])
                })
                .sheet(isPresented: $showShareSheetView, onDismiss: {
                    viewModel.itemsToShare = nil
                }) {
                    if let items = viewModel.itemsToShare {
                        ShareSheetView(items: items)
                    }
                }
                Button(action: editButtonAction) {
                    Image(systemName: "pencil")
                }
                .disabled(!viewModel.canEdit(document))
                .fullScreenCover(isPresented: $isEditingDocumentView) {
                    let document = document.convert()
                    EditDocumentView(isPresented: $isEditingDocumentView, type: .existing(document))
                }
            }
        }
        .fullScreenCover(isPresented: $showingImageViewer, onDismiss: nil) {
            ImageViewer(image: $imageViewerImage, viewerShown: $showingImageViewer)
        }
        
        .animation(.default, value: document)
    }
    
    private func editButtonAction() {
        self.isEditingDocumentView = true
    }
    
    private func shareAction() {
        viewModel.share(document) { share, container, error in
            if error != nil {
            } else {
                DispatchQueue.main.async {
                    viewModel.activeContainer = container
                    viewModel.activeShare = share
                    viewModel.isCloudSharing = true
                }
            }
        }
    }
    
    private func iconForShareButton() -> some View {
        Image(systemName: viewModel.isShared(document) ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.plus")
            .renderingMode(.original)
    }
    
    private func shareView() -> CloudSharingView? {
        guard let share = viewModel.activeShare, let container = viewModel.activeContainer else {
            return nil
        }
        return CloudSharingView(container: container, share: share)
    }

    
    private func shareInfo() {
        if document.getPhotos()?.count ?? 0 == 0 {
            shareText()
        } else {
            showShareActionSheet = true
        }
    }
    
    private func sharePhotosAndText() {
        share(items: [constractSharePhotos(), constractShareText()])
    }
        
    private func sharePhotos() {
        share(items: constractSharePhotos())
    }
    
    private func constractSharePhotos() -> [UIImage] {
        return document.getPhotos() ?? []
    }
    
    private func constractShareText() -> String {
        var documentString: String = ""
        if let docName = document.name {
            documentString.append("dv_share_details_title".localized())
            documentString.append(docName)
            documentString.append("\n\n")
        }
        for section in document.getSections() {
            documentString.append(section.name ?? "")
            documentString.append(":")
            documentString.append("\n")
            for field in section.getAllFields() {
                documentString.append(field.title ?? "")
                documentString.append(": ")
                documentString.append(field.value ?? "")
                documentString.append("\n")
            }
            documentString.append("\n")
        }
        documentString.append("dv_share_caption".localized())
        documentString.append("\n")
        documentString.append("https://DuckDepo.com")
        return documentString
    }
    
    private func shareText() {
        share(items: [constractShareText()])
    }
    
    private func share(items: [Any]) {
        viewModel.itemsToShare = items
        showShareSheetView = true
    }
}

struct DocumentView_Previews: PreviewProvider {
    
    static var document: DDDocument = {
        let context = PersistenceController.shared.context
        let document = DDDocument(context: context)
        document.name = "Test Doc"
        document.addToPhotos([UIImage(named: "duck")!, UIImage(named: "duck")!, UIImage(named: "duck")!])
        
        return document
    }()
    
    static var previews: some View {
        DocumentView(document: DocumentView_Previews.document)
    }
}

struct PhotosView: View {
    
    @ObservedObject var document: DDDocument
    @Binding var imageViewerImage: Image?
    @Binding var showingImageViewer: Bool

    var body: some View {
        Section {
            if let photos = document.getPhotos(), !photos.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(photos, id: \.self) { photo in
                            PhotoCell(image: photo)
                                .onTapGesture {
                                    self.imageViewerImage = Image(uiImage: photo)
                                    self.showingImageViewer = true
                                }
                            
                        }
                    }
                    .frame(height: 70)
                }
                .padding([.trailing, .leading], -12)
            } else {
                Text("dv_no_photos")
            }
        } header: {
            Text("dv_photos")
        }
    }
}
