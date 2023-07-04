//
//  NeuDepoListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

struct DepoListView: View {
    
    @StateObject private var viewModel: DepoListViewModel = DepoListViewModel()
    
    @State var position: CGSize = CGSize.zero
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neumorphicBackground
                    .ignoresSafeArea()

                if viewModel.documents.isEmpty {
                    InitialInstructionsView(type: .documents)
                } else {
                    listView
                }
            }
            .navigationTitle("🦆 Depo")
            .navigationBarTitleDisplayMode(.large)
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

            NoSelectionViewView(type: .document)
        }

        .fullScreenCover(isPresented: $viewModel.isAddingNewDocument) {
            EditDocumentView(type: .new)
        }

    }
}

extension DepoListView {
    private var listView: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(viewModel.documents) { document in
                    NavigationLink(tag: document, selection: $viewModel.selectedDocument) {
                        DocumentView(document: document)
                    } label: {
                        EmptyView()
                    }
                    DepoListRowView(image: document.documentType.image,
                                    iconColor: document.documentType.iconColor,
                                    name: document.name,
                                    description: document.description) {
                        viewModel.selectedDocument = document
                    }
                }
                FixedSpacer(16)
            }
        }
    }
}


struct DepoListView_Previews: PreviewProvider {
    static var previews: some View {
        DepoListView()
    }
}
