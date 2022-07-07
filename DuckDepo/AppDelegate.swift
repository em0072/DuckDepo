//
//  AppDelegate.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 09/11/2021.
//

import UIKit
import CloudKit
import CoreData

//@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let shared: AppDelegate = AppDelegate()
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
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


