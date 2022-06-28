//
//  ImageViewer.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 20/06/2022.
//

import SwiftUI

struct ImageViewer: View {
    @Environment(\.dismiss) private var dismiss // Applies to DetailView.
    
    var photos: [UIImage]
    @State var selectedImage: UIImage
    
    
    init(photos: [UIImage], selectedImage: UIImage) {
        self.photos = photos
        self._selectedImage = State(initialValue: selectedImage)
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedImage) {
                ForEach(photos, id: \.self) { photo in
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .tag(photo)
                }
            }
            .tabViewStyle(PageTabViewStyle())
        }
        .gesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .global)
                .onEnded { value in
                    if value.translation.height > 50 {
                        dismiss()
                    }
                }
        )
        .background(Color.black)
        .ignoresSafeArea()
        .overlay(
            Button(action: {
                dismiss()
            }, label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.35))
                    .clipShape(Circle())
            })
                .padding()
            , alignment: .topLeading
        )
    }
    
}

struct ImageViewer_Previews: PreviewProvider {
    
    static var testPhoto = UIImage(named: "duck")!
    
    static var previews: some View {
        ImageViewer(photos: [UIImage(named: "duck")!, UIImage(named: "screen1")!, UIImage(named: "screen2")!], selectedImage: UIImage(named: "screen1")!)
    }
}
