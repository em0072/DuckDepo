//
//  CloudShareView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 08/11/2021.
//

import Foundation
import SwiftUI
import UIKit
import CloudKit

/// This struct wraps a `UICloudSharingController` for use in SwiftUI.
struct CloudSharingView: UIViewControllerRepresentable {

    // MARK: - Properties

//    @Environment(\.presentationMode) var presentationMode
    var container: CKContainer
    var share: CKShare
//    var delegate: UICloudSharingControllerDelegate

    // MARK: - UIViewControllerRepresentable

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeUIViewController(context: Context) -> some UIViewController {
        let sharingController = UICloudSharingController(share: share, container: container)
        sharingController.availablePermissions = [.allowReadOnly, .allowReadWrite, .allowPrivate]
        sharingController.delegate = context.coordinator
        sharingController.modalPresentationStyle = .formSheet
        return sharingController
    }

    func makeCoordinator() -> CloudSharingView.Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            debugPrint("Error saving share: \(error)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Sharing Example"
        }
//
        //Optional
        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            return nil
        }

        func itemType(for csc: UICloudSharingController) -> String? {
            return nil
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("Did save share")
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("Did stop sharing")
        }

        
    }
}
