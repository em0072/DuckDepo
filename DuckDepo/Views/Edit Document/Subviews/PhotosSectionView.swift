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
        Section {
            ZStack {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    // Add new photo cell
                    AddCell() {
                        showingPhotoChooser = true
                    }
//                    .frame(width: 50, height: 50)
                    // Photo cells
                    ForEach(images, id: \.self) { image in
                        ZStack(alignment: .topTrailing) {
                            //Photo
                            PhotoCell(image: image) {
                                    delegate?.select(photo: image)
                                }
                            //Delete photo button
                            Button {
                                delegate?.delete(photo: image)
                            } label: {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(Color.red)
                            }
                            .frame(width: 20)
                            .offset(x: -2, y: 2)
                            .buttonStyle(NeumorphicCircleButtonStyle())
                        }
                    }
                    
                }
                .padding(6)
            }
                NeuSectionBackground()
            }
            .actionSheet(isPresented: $showingPhotoChooser) {
                ActionSheet(title: Text("psv_photo_selection_body"), buttons: [
                    .default(Text("psv_camera")) {
                        showingCameraView = true
                    },
                    .default(Text("psv_photo_library")) {
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
            
        } header: {
            HStack {
                Text("psv_photos")
                    .font(.footnote)
                    .foregroundColor(.neumorphicText)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 16)
//            .padding(.bottom, -13)
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
    
    static let images = [UIImage(named: "duck")!, UIImage(named: "duck")!]

    static var previews: some View {
//        Form {
        ScrollView {
            HStack {
                PhotosSectionView(images: .constant(PhotosSectionView_Previews.images))
            }
        }
        
    }
}
