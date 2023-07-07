//
//  NewPhotoView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 20/06/2022.
//

import SwiftUI

struct DocPhotoSection: View {
    
    var photos: [UIImage]
    @Binding var selectedPhoto: UIImage?

    var body: some View {
        Section {
                if !photos.isEmpty {
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(photos, id: \.self) { photo in
                                PhotoCell(image: photo) {
                                    self.selectedPhoto = photo
                                }
                            }
                        }
                        .frame(height: 110)
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("dv_no_photos")
                        Spacer()
                    }
                    .padding()
                }
        } header: {
            Text("dv_photos")
        }
    }
}

struct NewPhotoView_Previews: PreviewProvider {
    
    static var previews: some View {
        List {
            DocPhotoSection(photos: Document.test.photos, selectedPhoto: .constant(nil))
        }
    }
}
