//
//  DepoListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

struct DepoListView: View {

    @State var viewModel: DepoListViewModel
    @State private var selection: Document.ID?
    @State private var documentToEdit: Document?
    @State private var documentToDelete: Document?
    private var syncMonitor = SyncMonitor.shared

    init(viewModel: DepoListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationTitle("🦆 Depo")
                .syncActivitySubtitle(syncMonitor)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: viewModel.addNewDocumentButtonPressed) {
                            Label("add_new_doc", systemImage: "plus")
                        }
                    }
                }
                .onAppear(perform: viewModel.start)
        } detail: {
            if let document = viewModel.document(with: selection) {
                DocumentView(document: document)
                    .id(document.id)
            } else {
                ContentUnavailableView("dl_no_selection_title",
                                       systemImage: "doc.text",
                                       description: Text("no_doc_view_body_docs"))
            }
        }
        .sheet(isPresented: $viewModel.isAddingNewDocument) {
            EditDocumentView(viewModel: viewModel.editDocumentViewModel)
        }
        .sheet(item: $documentToEdit) { document in
            EditDocumentView(viewModel: EditDocumentViewModel(type: .existing(document)))
        }
        .alert("delete_confirmation_title", isPresented: isConfirmingDelete, presenting: documentToDelete) { document in
            Button("delete", role: .destructive) {
                viewModel.delete(document)
            }
        } message: { _ in
            Text("delete_confirmation_body")
        }
        .onChange(of: viewModel.documents) { _, documents in
            // The selected document was deleted, here or on another device.
            if let selection, !documents.contains(where: { $0.id == selection }) {
                self.selection = nil
            }
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if viewModel.documents.isEmpty {
            if syncMonitor.showsActivity && syncMonitor.isDownloading {
                DownloadingFromICloudView(type: .documents)
            } else {
                ContentUnavailableView {
                    Label("ii_headline_documents", systemImage: "doc.text")
                } description: {
                    Text("ii_caption_documents")
                } actions: {
                    Button("add_new_doc", action: viewModel.addNewDocumentButtonPressed)
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(.onDuckYellow)
                }
            }
        } else {
            listView
                .searchable(text: $viewModel.searchText, prompt: Text("dl_search_prompt"))
        }
    }

    private var listView: some View {
        List(selection: $selection) {
            ForEach(viewModel.groups) { group in
                Section(group.type.localizedName) {
                    ForEach(group.documents) { document in
                        DocumentRow(document: document)
                            .tag(document.id)
                            .swipeActions(edge: .trailing) {
                                // Not the destructive role: that removes the row before the deletion is confirmed.
                                Button {
                                    documentToDelete = document
                                } label: {
                                    Label("delete", systemImage: "trash")
                                }
                                .tint(.red)
                                Button {
                                    documentToEdit = document
                                } label: {
                                    Label("edit_button", systemImage: "pencil")
                                }
                                .tint(.gray)
                            }
                            .contextMenu {
                                Button {
                                    documentToEdit = document
                                } label: {
                                    Label("edit_button", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    documentToDelete = document
                                } label: {
                                    Label("delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .overlay {
            if viewModel.groups.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding {
            documentToDelete != nil
        } set: { isPresented in
            if !isPresented {
                documentToDelete = nil
            }
        }
    }
}

#Preview {
    DepoListView(viewModel: DepoListViewModel())
}
