//
//  DuckDepoApp.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import SwiftUI

enum AppEnvironment {
    /// Unit tests run inside the app; skip the real data stack and UI then.
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}

@main
struct DuckDepoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            if AppEnvironment.isRunningTests {
                Color.clear
            } else {
                ContentView()
                    .environment(\.managedObjectContext, PersistenceController.shared.context)
                    .background {
                        WindowSceneReader { scene in
                            LockWindowPresenter.shared.attach(to: scene)
                        }
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard !AppEnvironment.isRunningTests else { return }
            let lock = BiometricController.shared
            switch newPhase {
            case .active:
                lock.sceneDidBecomeActive()
                appDidBecomeActive()
            case .inactive:
                lock.sceneWillResignActive()
            case .background:
                lock.sceneDidEnterBackground()
            @unknown default:
                break
            }
        }
    }

    private func appDidBecomeActive() {
        let persistence = PersistenceController.shared
        guard persistence.isLoaded else { return }
        persistence.mergeChangesFromOtherProcesses()
        ExpiryReminders.shared.start()
        // Converting photos reads every photo, so do it once per launch. Until then a document shows
        // its old photo data whenever that is newer (see `DDDocument.photos()`).
        let convertPhotos = !LaunchState.didConvertPhotos
        LaunchState.didConvertPhotos = true
        persistence.performMaintenance { context in
            LegacyDataMigration.run(in: context, keychain: Keychain.shared, convertPhotos: convertPhotos)
            DispatchQueue.main.async {
                CredentialIdentityStoreController.shared.refresh()
            }
        }
    }
}

private enum LaunchState {
    static var didConvertPhotos = false
}
