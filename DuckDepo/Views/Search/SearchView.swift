//
//  SearchView.swift
//  DuckDepo
//

import SwiftUI

/// The search tab's content. `ContentView` adds the search field, which the tab bar shows in place of
/// its search button.
struct SearchView: View {

    let viewModel: SearchViewModel
    @State private var path: [SearchDestination] = []

    var body: some View {
        NavigationStack(path: $path) {
            content
                .animation(.default, value: viewModel.isSearching)
                .navigationTitle("search_title")
                .navigationDestination(for: SearchDestination.self, destination: destination)
        }
        .onAppear(perform: viewModel.start)
        .onChange(of: viewModel.documents) {
            removeDeletedDestinations()
        }
        .onChange(of: viewModel.passwords) {
            removeDeletedDestinations()
        }
    }

    @ViewBuilder
    private var content: some View {
        let documents = viewModel.documentResults
        let photoMatches = viewModel.photoMatches
        let passwords = viewModel.passwordResults
        if !viewModel.isSearching {
            ContentUnavailableView("search_empty_title", systemImage: "magnifyingglass",
                                   description: Text("search_empty_body"))
        } else if documents.isEmpty && passwords.isEmpty {
            ContentUnavailableView.search(text: viewModel.query)
        } else {
            List {
                if !documents.isEmpty {
                    Section("search_documents") {
                        ForEach(documents) { document in
                            NavigationLink(value: SearchDestination.document(document.id)) {
                                DocumentRow(document: document,
                                            photoMatch: photoMatches[document.id].map { ($0, viewModel.query) })
                            }
                        }
                    }
                }
                if !passwords.isEmpty {
                    Section("plv_title") {
                        ForEach(passwords) { password in
                            NavigationLink(value: SearchDestination.password(password.id)) {
                                PasswordRow(name: password.name, login: password.login)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(_ destination: SearchDestination) -> some View {
        switch destination {
        case .document(let id):
            if let document = viewModel.document(with: id) {
                DocumentView(document: document)
            }
        case .password(let id):
            if let password = viewModel.password(with: id) {
                PasswordView(password: password)
            }
        }
    }

    /// Leaves a detail screen whose item was deleted, here or on another device.
    private func removeDeletedDestinations() {
        path.removeAll { !viewModel.exists($0) }
    }
}
