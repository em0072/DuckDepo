//
//  ImageViewer.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 20/06/2022.
//

import SwiftUI

struct ImageViewer: View {
    @Environment(\.dismiss) private var dismiss

    var photos: [UIImage]
    
    let maxZoomValue: CGFloat = 2.5
    @State var selectedImage: UIImage
    @State var scale: CGFloat = 1
    @State var offset: CGSize = .zero

    @State private var accumulatedScale: CGFloat = 1
    @State private var accumulatedOffset: CGSize = .zero
    @State private var imageSize: CGSize = .zero

    @State var showZoomImage = false
    
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
                        .opacity(showZoomImage ? 0 : 1)
                        .aspectRatio(contentMode: .fit)
                        .tag(photo)
                }

            }
            .tabViewStyle(PageTabViewStyle())
            .allowsHitTesting(!showZoomImage)
            
            if showZoomImage {
                imageZoomView
            }

        }
        .gesture(dragGesture)
        .gesture(doubleTapGesture)
        .gesture(magnificationGesture)
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

extension ImageViewer {
    
    private var imageZoomView: some View {
        Image(uiImage: selectedImage)
            .resizable()
            .scaleEffect(scale)
            .offset(offset)
            .aspectRatio(contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            imageSize = proxy.size
                        }
                }
            }
    }
        
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                showZoomImage = true
                print(accumulatedScale * scale.magnitude)
                withAnimation(.linear(duration: 0.05)) {
                    self.scale = accumulatedScale * scale.magnitude
                }
            }
            .onEnded { scale in
                let totalScale = min(maxZoomValue, accumulatedScale * scale.magnitude)
                self.accumulatedScale = totalScale
                if accumulatedScale < 1 {
                    resetZoomedImage()
                } else {
                    withAnimation {
                        self.scale = accumulatedScale
                    }
                }
            }
    }
    
    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded { _ in
                if scale <= 1 {
                    showZoomImage = true
                    accumulatedScale = maxZoomValue
                    withAnimation {
                        scale = maxZoomValue
                    }
                } else {
                    resetZoomedImage()
                }
            }
    }
    
    private func resetZoomedImage() {
        self.accumulatedScale = 1
        self.accumulatedOffset = .zero
        withAnimation(.easeInOut(duration: 0.2)) {
            self.scale = 1
            self.offset = .zero
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.showZoomImage = false
        }

    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1 {
                    offset.width = accumulatedOffset.width + value.translation.width
                    offset.height = accumulatedOffset.height + value.translation.height
                }
            }
            .onEnded { value in
                if scale == 1 && value.translation.height > 50 {
                    dismiss()
                } else {
                    let totalWidthOffset = accumulatedOffset.width + value.translation.width
                    let totalHeightOffset = accumulatedOffset.height + value.translation.height
                    let multipliers = CGSize(width: imageSize.width * scale / totalWidthOffset, height: imageSize.height * scale / totalHeightOffset)
                    var resultOffset = CGSize(width: totalWidthOffset,
                                              height: totalHeightOffset)
                    
                    if abs(multipliers.width) < 3 {
                        let widthMultiplier: CGFloat = multipliers.width > 0 ? 3 : -3
                        resultOffset.width = imageSize.width * scale / widthMultiplier
                    }
                    if abs(multipliers.height) < 3 {
                        let heightMultiplier: CGFloat = multipliers.height > 0 ? 3 : -3
                        resultOffset.height = imageSize.height * scale / heightMultiplier
                    }
                    self.accumulatedOffset = resultOffset
                        withAnimation {
                            self.offset = resultOffset
                        }
                }
            }
    }
}

struct ImageViewer_Previews: PreviewProvider {
    
    static var testPhoto = UIImage(named: "duck")!
    
    static var previews: some View {
        ImageViewer(photos: [UIImage(named: "duck")!, UIImage(named: "screen1")!, UIImage(named: "screen2")!], selectedImage: UIImage(named: "screen1")!)
    }
}
