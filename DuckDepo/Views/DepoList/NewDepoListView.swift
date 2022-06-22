//
//  NewDepoListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 17/06/2022.
//

import SwiftUI

struct NewDepoListView: View {
    
    @StateObject private var viewModel: NewDepoListViewModel = NewDepoListViewModel()
            
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if viewModel.documents.isEmpty {
                    InitialInstructionsView(type: .documents)
                } else {
                    listView()
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
                        }
                }
            }

            NoSelectionViewView(type: .document)
        }
        

        .fullScreenCover(isPresented: $viewModel.isAddingNewDocumentView) {
            EditDocumentView(isPresented: $viewModel.isAddingNewDocumentView, type: .new)
        }

    }
    
    private func listView() -> some View {
        ScrollView {
            VStack {
                ForEach(viewModel.documents) { document in
                    NavigationLink(tag: document, selection: $viewModel.selectedDocument) {
                        NewDocumentView(document: document)
                    } label: {
                        EmptyView()
                    }

                    DepoListRowView(document: document, selectedDocument: $viewModel.selectedDocument)
                }
            }
        }
    }
    
}

struct NewDepoListView_Previews: PreviewProvider {
    static var previews: some View {
        NewDepoListView()
    }
}
