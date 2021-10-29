//
//  ContentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import SwiftUI
import CoreData

struct ContentView: View {
   
    var body: some View {
//        NavigationView {
            TabView {
                DepoListView().tabItem {
                    Label("Depo", systemImage: "archivebox")
                }.tag(1)
                SettingsView().tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(2)
            }
//        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
