//
//  AppDelegate.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 08/11/2021.
//

import UIKit
import CloudKit

//@main
class SceneDelegate: NSObject, UIWindowSceneDelegate {
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
    }

    }
