//
//  ContentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import SwiftUI
import CoreData
import LocalAuthentication

struct ContentView: View {
    
    @State var isShowingCopyNotification: Bool = false
    @State var copyNotificationText: String = "Copied"
   
    var body: some View {
            TabView {
                DepoListView(viewModel: DepoListViewModel())
                    .tabItem {
                        Label("Depo", systemImage: "archivebox")
                    }.tag(1)
                PasswordsListView(viewModel: PasswordsListViewModel())
                    .tabItem {
                        Label("Passwords", systemImage: "key.fill")
                    }.tag(2)
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }.tag(3)
            }
            .tint(.duckYellow)
            .onReceive(NotificationCenter.default.publisher(for: .floatingTextFieldCopyNotification)) { _ in
                isShowingCopyNotification = true
            }
            .pillNotification(text: copyNotificationText, show: $isShowingCopyNotification)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
