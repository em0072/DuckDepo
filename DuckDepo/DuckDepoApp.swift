//
//  DuckDepoApp.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import SwiftUI

@main
struct DuckDepoApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        InitialSetup.main.populateCoreDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
}
