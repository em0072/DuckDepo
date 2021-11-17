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

    
    @ObservedObject var biometricController = BiometricController.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environment(\.managedObjectContext, PersistenceController.shared.context)
                VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    .ignoresSafeArea()
                    .opacity(biometricController.isUnlocked ? 0 : 1)
            }
            .animation(.default, value: biometricController.isUnlocked)

        }
        .onChange(of: scenePhase) { (newScenePhase) in
            switch newScenePhase {
            case .active:
                print("scene is now active!")
                biometricController.onActiveState()
            case .inactive:
                print("scene is now inactive!")
                biometricController.onInactiveState()
            case .background:
                print("scene is now in the background!")
                biometricController.onBackgroundState()
            @unknown default:
                print("Apple must have added something new!")
            }
        }

    }
    

    
}
