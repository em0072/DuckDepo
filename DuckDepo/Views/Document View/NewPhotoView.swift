//
//  NewPhotoView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 20/06/2022.
//

import SwiftUI

struct NewPhotoView: View {
    
    var photos: [UIImage]
    @Binding var selectedPhoto: UIImage?
//    @Binding var showingImageViewer: Bool

    var body: some View {
        Section {
            if !photos.isEmpty {
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(photos, id: \.self) { photo in
                            Button {
                                self.selectedPhoto = photo
                            } label: {
                                PhotoCell(image: photo)
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

struct NewPhotoView_Previews: PreviewProvider {
    
    static var previews: some View {
        NewPhotoView(photos: [UIImage(named: "duck")!], selectedPhoto: .constant(nil))
    }
}
