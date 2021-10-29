//
//  DocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import SwiftUI
import ImageViewer

struct DocumentView: View {
    
    let document: DDDocument
    @State var showingImageViewer = false
    @State var imageViewerImage: Image?

    
    var body: some View {
        List {
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
                        .frame(height: 150)
                    }
                    .padding([.trailing, .leading], -12)
                } else {
                    Text("No Photos")
                }
            }
        }
        .navigationBarTitle(Text((document.name ?? "")))
        .fullScreenCover(isPresented: $showingImageViewer, onDismiss: nil) {
            ImageViewer(image: $imageViewerImage, viewerShown: $showingImageViewer)
        }
    }
}

struct DocumentView_Previews: PreviewProvider {
    
    static var document: DDDocument = {
        let context = PersistenceController.shared.container.viewContext
        let document = DDDocument(context: context)
        document.name = "Test Doc"
        document.addToPhotos([UIImage(named: "duck")!, UIImage(named: "duck")!, UIImage(named: "duck")!])

        return document
    }()
    
    static var previews: some View {
        DocumentView(document: DocumentView_Previews.document)
    }
}
