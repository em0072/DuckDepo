//
//  ContentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

struct ContentView: View {

    @State private var isShowingCopyNotification = false

    var body: some View {
        TabView {
            Tab("Depo", systemImage: "archivebox") {
                DepoListView(viewModel: DepoListViewModel())
            }
            Tab("Passwords", systemImage: "key") {
                PasswordsListView(viewModel: PasswordsListViewModel())
            }
            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
        .tint(.duckYellow)
        .onReceive(NotificationCenter.default.publisher(for: .floatingTextFieldCopyNotification)) { _ in
            isShowingCopyNotification = true
        }
        .pillNotification(text: "copied_notification".localized(), show: $isShowingCopyNotification)
    }
}

#Preview {
    ContentView()
}
