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
                Color.neumorphicBackground
                    .ignoresSafeArea()
                
                if viewModel.documents.isEmpty {
                    InitialInstructionsView(type: .documents)
                } else {
                    listView()
                }
            }
            .navigationTitle("🦆 Depo")
            .toolbarBackground(Color.neumorphicBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.addNewDocumentButtonPressed()
                    }) {
                        Image(systemName: "plus")
                            .font(.footnote)
                            .padding(7)
                    }
                    .buttonStyle(NeuCircleButtonStyle())
                }
            }
        } detail: {
            NoSelectionViewView(type: .document)
        }
        .fullScreenCover(isPresented: $viewModel.isAddingNewDocument) {
            EditDocumentView(type: .new)
        }
        
    }
    
    private func listView() -> some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(viewModel.documents) { document in
                    NavigationLink(value: document) {
                        DepoListRowView(icon: document.documentType.image,
                                        iconColor: document.documentType.iconColor,
                                        name: document.name,
                                        description: document.description)
                    }
                    .navigationDestination(for: Document.self) { document in
                        DocumentView(document: document)
                    }
                    .buttonStyle(NeuRectButtonStyle())
                    .padding()
                    
                }
            }
        }
        .listStyle(.plain)
    }
}

struct DepoListView_Previews: PreviewProvider {
    
    static var viewModel: DepoListViewModel {
        let viewModel = DepoListViewModel()
        viewModel.documents = [
            Document(id: .init(),
                     name: "Name",
                     description: "Description",
                     documentType: .identification,
                     photos: [],
                     sections: [],
                     folder: nil),
        ]
        return viewModel
    }
    
    static var previews: some View {
        DepoListView(viewModel: Self.viewModel)
    }
}
