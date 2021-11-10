//
//  AppDelegate.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 08/11/2021.
//

import SwiftUI
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = ContentView()
            .environment(\.managedObjectContext, PersistenceController.shared.context)

//        let contentView = TestView()
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    
      func sceneWillEnterForeground(_ scene: UIScene) {
          print("sceneWillEnterForeground")
      }

      func sceneDidBecomeActive(_ scene: UIScene) {
          print("sceneDidBecomeActive")
      }

      func sceneWillResignActive(_ scene: UIScene) {
          print("sceneWillResignActive")
      }
    
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        let sharedStore = PersistenceController.shared.sharedPersistentStore
        let container = PersistenceController.shared.container
        container.acceptShareInvitations(from: [cloudKitShareMetadata], into: sharedStore) { shareMetas, error in
            if let shareAcceptenceError = error {
                print("Could not accept share - \(shareAcceptenceError)")
            } else {
                print("Accepted share with metadata - \(String(describing: shareMetas))")
            }
        }
    }
}
