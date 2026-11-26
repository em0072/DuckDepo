//
//  AppDelegate.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 09/11/2021.
//

import CloudKit
import os
import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {

    private let logger = Logger(subsystem: "DuckDepo", category: "App")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        guard !AppEnvironment.isRunningTests else { return true }
        // Create the CloudKit container at launch so it can handle the push that woke the app.
        _ = PersistenceController.shared
        _ = SyncMonitor.shared
        return true
    }

    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        let persistence = PersistenceController.shared
        guard let sharedStore = persistence.sharedPersistentStore else {
            logger.error("Received a CloudKit share, but sharing isn't set up")
            return
        }
        persistence.container.acceptShareInvitations(from: [cloudKitShareMetadata], into: sharedStore) { [logger] _, error in
            if let error {
                logger.error("Could not accept share: \(String(describing: error), privacy: .public)")
            }
        }
    }
}
