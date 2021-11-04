//
//  PhotosSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI

protocol PhotosSectionViewDelegate {
    func select(photo: UIImage, at index: Int?)
    func photoPicked(didPickPhoto photo: UIImage)
    func cameraPicker(didPickPhotos photos: [UIImage])
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
                        ForEach(images, id: \.self) { image in
                            PhotoCell(image: image)
                                .onTapGesture {
                                    delegate?.select(photo: image, at: images.firstIndex(of: image))
                                }
                        }
                        
                        AddCell()
                            .onTapGesture {
                                showingPhotoChooser = true
                            }
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
                    .frame(height: 100)
                }
            }
            .padding([.leading, .trailing], -12)
            
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
