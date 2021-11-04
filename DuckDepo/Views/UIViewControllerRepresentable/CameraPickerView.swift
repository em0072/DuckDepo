//
//  CameraScanController.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 28/10/2021.
//

import SwiftUI
import VisionKit

struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var imageArray: [UIImage]?
    
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
          
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
//            errorMessage = error.localizedDescription
        }
          
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
          print("Did Finish With Scan.")
            var images = [UIImage]()
            for i in 0..<scan.pageCount {
                
                images.append(scan.imageOfPage(at:i))
            }
            parent.imageArray = images
            parent.presentationMode.wrappedValue.dismiss()
        }

        
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }


    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraPickerView>) -> VNDocumentCameraViewController {
        let camera = VNDocumentCameraViewController()
        camera.delegate = context.coordinator
        return camera
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: UIViewControllerRepresentableContext<CameraPickerView>) {

    }
}
