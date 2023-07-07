//
//  NeuDepoListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

struct DepoListView: View {
    
    @StateObject var viewModel: DepoListViewModel
    
    var body: some View {
        NavigationSplitView {
            ZStack {
                if viewModel.documents.isEmpty {
                    InitialInstructionsView(type: .documents)
                } else {
                    listView
                }
            }
            .navigationTitle("🦆 Depo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.addNewDocumentButtonPressed) {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            NoSelectionViewView(type: .document)
        }
        .fullScreenCover(isPresented: $viewModel.isAddingNewDocument) {
            EditDocumentView(type: .new)
        }
    }

}

extension DepoListView {
    
    private var listView: some View {
        List(viewModel.documents) { document in
            VStack(spacing: 6) {
                    NavigationLink(value: document) {
                        DepoListRowView(icon: document.documentType.image,
                                        iconColor: document.documentType.iconColor,
                                        name: document.name,
                                        description: document.description)
                    }
                    .navigationDestination(for: Document.self) { document in
                        DocumentView(document: document)
                    }
            }
        }
    }
    
}

struct DepoListView_Previews: PreviewProvider {
    
    static var viewModel: DepoListViewModel {
        let viewModel = DepoListViewModel()
        viewModel.documents = Array(repeating: Document.test, count: 2)
        return viewModel
    }
    
    static var previews: some View {
        DepoListView(viewModel: Self.viewModel)
    }
}
