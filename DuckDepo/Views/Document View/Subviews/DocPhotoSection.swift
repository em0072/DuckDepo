//
//  NewPhotoView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 20/06/2022.
//

import SwiftUI

struct DocPhotoSection: View {

    let photos: [DocumentPhoto]
    @Binding var selectedPhoto: DocumentPhoto?

    var body: some View {
        Section {
            if photos.isEmpty {
                Text("dv_no_photos")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(photos) { photo in
                            PhotoCell(image: photo.image) {
                                selectedPhoto = photo
                            }
                        }
                    }
                    .frame(height: 110)
                }
            }
        } header: {
            Text("dv_photos")
        }
    }
}

#Preview {
    List {
        DocPhotoSection(photos: Document.test.photos, selectedPhoto: .constant(nil))
    }
}
