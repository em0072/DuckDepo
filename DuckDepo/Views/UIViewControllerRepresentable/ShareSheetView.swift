//
//  ShareSheetView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/11/2021.
//

import SwiftUI

struct ShareSheetView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var items: [Any]
    
    
    class Coordinator: NSObject {
    }

    func makeCoordinator() -> ShareSheetView.Coordinator {
        Coordinator()
    }


    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheetView>) -> UIActivityViewController {
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheetView>) {}
}
