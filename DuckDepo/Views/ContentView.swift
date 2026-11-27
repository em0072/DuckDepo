//
//  ContentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import AuthenticationServices
import SwiftUI

struct ContentView: View {

    @State private var isShowingCopyNotification = false
    @State private var searchViewModel = SearchViewModel()
    @State private var importer = CredentialImporter()

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
            // One search for documents and passwords: the separate button at the end of the tab bar.
            // The search field belongs to this tab only; on the tab view it showed on every tab.
            Tab(role: .search) {
                SearchView(viewModel: searchViewModel)
                    .searchable(text: $searchViewModel.query, prompt: Text("search_prompt"))
            }
        }
        .tabViewSearchActivation(.searchTabSelection)
        .tint(.duckYellow)
        .onReceive(NotificationCenter.default.publisher(for: .floatingTextFieldCopyNotification)) { _ in
            isShowingCopyNotification = true
        }
        .pillNotification(text: "copied_notification".localized(), show: $isShowingCopyNotification)
        // Another password manager sending its passwords and documents here.
        .onContinueUserActivity(ASCredentialExchangeActivity, perform: importer.receive)
        .sheet(item: $importer.plan) { plan in
            ImportSheet(plan: plan, isImporting: importer.isImporting, progress: importer.progress) {
                importer.perform(plan)
            }
        }
        .alert("import_failed_title", isPresented: isShowingImportFailure) {
            Button("OK") {}
        } message: {
            Text(importer.failure ?? "")
        }
        .pillNotification(text: importer.doneMessage, show: $importer.isShowingDone)
    }

    private var isShowingImportFailure: Binding<Bool> {
        Binding { importer.failure != nil } set: { if !$0 { importer.failure = nil } }
    }
}

#Preview {
    ContentView()
}
