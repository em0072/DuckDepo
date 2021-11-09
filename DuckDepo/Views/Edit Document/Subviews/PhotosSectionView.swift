//
//  PhotosSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI

protocol PhotosSectionViewDelegate {
    func select(photo: UIImage)
    func photoPicked(didPickPhoto photo: UIImage)
    func cameraPicker(didPickPhotos photos: [UIImage])
    func delete(photo: UIImage)
}

struct PhotosSectionView: View {
        
    @Binding var images: [UIImage]
    var delegate: PhotosSectionViewDelegate?
    
    @State var showingPhotoChooser = false
    @State var showingCameraView = false
    @State var showingImagePicker = false
    @State var imagePickerSelectedImage: UIImage?
    @State var cameraPickerSelectedImages: [UIImage]?

    var body: some View {
        Section("Photos") {
            ScrollView(.horizontal) {
                ScrollViewReader { scrollProxy in
                    LazyHStack {
                        AddCell()
                            .onTapGesture {
                                showingPhotoChooser = true
                            }

                        ForEach(images, id: \.self) { image in
                            ZStack(alignment: .topTrailing) {
                                PhotoCell(image: image)
                                    .onTapGesture {
                                        delegate?.select(photo: image)
                                    }
                                Image(systemName: "multiply.circle.fill")
                                    .background(
                                      Color.white.mask(Circle())
                                    )
                                    .foregroundColor(Color.red)
                                    .frame(width: 20)
                                    .offset(x: 5, y: -5)
                                    .onTapGesture {
                                        delegate?.delete(photo: image)
                                    }
                            }
                        }
                        
                    }
                    .padding([.top, .bottom], 5)
                    .frame(height: 75)
                }
            }
            .padding([.leading, .trailing], -12)
            .actionSheet(isPresented: $showingPhotoChooser) {
                ActionSheet(title: Text("Do you want to scan a document with camera or choose it from photo library?"), buttons: [
                    .default(Text("Camera")) {
                        showingCameraView = true
                    },
                    .default(Text("Photo Library")) {
                        showingImagePicker = true
                    },
                    .cancel()
                ])
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: onImagePickerAction) {
                ImagePickerView(image: $imagePickerSelectedImage)
            }
            .sheet(isPresented: $showingCameraView, onDismiss: onCameraPickerAction) {
                CameraPickerView(imageArray: $cameraPickerSelectedImages)
            }
            
        }
    }
    
    func onImagePickerAction() {
        guard let selectedImage = imagePickerSelectedImage else { return }
        delegate?.photoPicked(didPickPhoto: selectedImage)
    }
    
    func onCameraPickerAction() {
        guard let selectedImages = cameraPickerSelectedImages, !selectedImages.isEmpty else { return }
        delegate?.cameraPicker(didPickPhotos: selectedImages)
    }
    
}

struct PhotosSectionView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            let images = [UIImage(named: "duck")!, UIImage(named: "duck")!]
            PhotosSectionView(images: .constant(images))
        }
        
    }
}
