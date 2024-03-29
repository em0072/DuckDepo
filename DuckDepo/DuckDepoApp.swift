//
//  DuckDepoApp.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import SwiftUI
import LocalAuthentication

@main
struct DuckDepoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    //Migration Properties
    @AppStorage("manualMigrationV1toV2") private var manualMigrationV1toV2: Bool = true
    @StateObject var migrationManager = ManualMigrationV1toV2()
    
    
    @ObservedObject var biometricController = BiometricController.shared

    var body: some Scene {
        WindowGroup {
            if manualMigrationV1toV2 && DataBase.shared.fetchCount(for: DDPassword.self) > 0 {
                AppProgressView(progressValue: $migrationManager.progress)
                    .onAppear(perform: {
                        if manualMigrationV1toV2 {
                            migrationManager.onMigrationEnd = {
                                manualMigrationV1toV2 = false
                            }
                            migrationManager.startMigration()
                        }
                    })
            } else {
                
                ZStack {
                    ContentView()
                        .environment(\.managedObjectContext, PersistenceController.shared.context)
                        .overlay(
                            .ultraThinMaterial
                            .opacity(biometricController.isUnlocked ? 0 : 1)
                        )
                }
                .animation(.default, value: biometricController.isUnlocked)
                
            }
        }
        .onChange(of: scenePhase) { (newScenePhase) in
            switch newScenePhase {
            case .active:
                biometricController.onActiveState()
                onActiveActions()
            case .inactive:
                biometricController.onInactiveState()
            case .background:
                biometricController.onBackgroundState()
            @unknown default:
                print("Apple must have added something new!")
            }
        }

    }
    
    
    func onActiveActions() {
        CredentialIdentityStoreController.shared.checkState()
    }    
}
