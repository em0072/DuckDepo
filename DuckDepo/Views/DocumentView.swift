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

    @StateObject var document: DDDocument
    @State private var imageViewerImage: Image?
    @State private var showingImageViewer = false
    @State private var isEditingDocumentView = false
    @State private var showShareActionSheet = false
    @State private var showShareSheetView = false
    @State private var sharedItems: [Any]?
    
    var body: some View {
        List {
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
        .onAppear {
            print("DocumentView onAppear")
        }
        .onChange(of: document, perform: { newValue in
            print("DocumentView onChange")

        })
        .navigationBarTitleDisplayMode(.large)
        .navigationBarTitle(Text((document.name ?? "")))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
//                ToolbarItem {
                    Button(action: shareInfo) {
                        Image(systemName: "square.and.arrow.up")
                    }
//                }
//                ToolbarItem {
                    Button(action: {
                        self.isEditingDocumentView = true
                    }) {
                        Image(systemName: "pencil")
                    }
//                }
            }
        }
        .fullScreenCover(isPresented: $showingImageViewer, onDismiss: nil) {
            ImageViewer(image: $imageViewerImage, viewerShown: $showingImageViewer)
        }
        .sheet(isPresented: $showShareSheetView, onDismiss: {
            sharedItems = nil
        }) {
            if let items = sharedItems {
                ShareSheetView(items: .constant(items))
            }
        }
        .fullScreenCover(isPresented: $isEditingDocumentView) {
            let document = document.convert()
            EditDocumentView(isPresented: $isEditingDocumentView, type: .existing(document))
        }
        .actionSheet(isPresented: $showShareActionSheet, content: {
                ActionSheet(title: Text("Share Document"),
                        message: Text("Would you like to share document photos or text information?"),
                        buttons: [
                            .default(Text("Photos")) {
                      sharePhotos()
                            },
                  .default(Text("Text")) {
                      shareText()
                  },
                  .cancel()
                ])
        })
        .animation(.default, value: document)


    }
    
    private func shareInfo() {
        if document.getPhotos()?.count ?? 0 == 0 {
            shareText()
        } else {
            showShareActionSheet = true
        }
    }
        
    private func sharePhotos() {
        if let photos = document.getPhotos() {
            share(items: photos)
        }
    }
    
    private func shareText() {
        var documentString: String = ""
        if let docName = document.name {
            documentString.append("Here is details of ")
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
        documentString.append("Shared with 🦆 DuckDepo.")
        documentString.append("\n")
        documentString.append("https://DuckDepo.com")
        share(items: [documentString])
    }
    
    private func share(items: [Any]) {
        sharedItems = items
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
        Section("Photos") {
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
                Text("No Photos")
            }
        }
    }
}
