//
//  NeuDepoListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

struct DepoListView: View {

    @StateObject var viewModel: DepoListViewModel
    @ObservedObject private var syncMonitor = SyncMonitor.shared

    var body: some View {
        NavigationSplitView {
            Group {
                if !viewModel.documents.isEmpty {
                    listView
                } else if syncMonitor.showsActivity && syncMonitor.isDownloading {
                    DownloadingFromICloudView(type: .documents)
                } else {
                    InitialInstructionsView(type: .documents)
                }
            }
            .navigationTitle("🦆 Depo")
            .syncActivitySubtitle(syncMonitor)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.addNewDocumentButtonPressed) {
                        Label("add_new_doc", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Document.self) { document in
                DocumentView(document: document)
            }
        } detail: {
            NoSelectionViewView(type: .document)
        }
        .fullScreenCover(isPresented: $viewModel.isAddingNewDocument) {
            EditDocumentView(viewModel: viewModel.editDocumentViewModel)
        }
    }
}

extension DepoListView {

    private var listView: some View {
        List(viewModel.documents) { document in
            NavigationLink(value: document) {
                DepoListRowView(icon: document.documentType.image,
                                iconColor: document.documentType.iconColor,
                                name: document.name,
                                description: document.description)
            }
        }
    }
}

#Preview {
    DepoListView(viewModel: DepoListViewModel())
}
