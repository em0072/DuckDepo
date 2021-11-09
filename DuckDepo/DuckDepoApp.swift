//
//  DuckDepoApp.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import SwiftUI

@main
struct DuckDepoApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
//            TestView()
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.context)
        }
        .onChange(of: scenePhase) { (newScenePhase) in
            switch newScenePhase {
            case .active:
                print("scene is now active!")
            case .inactive:
                print("scene is now inactive!")
            case .background:
                print("scene is now in the background!")
            @unknown default:
                print("Apple must have added something new!")
            }
        }

    }
    
}
