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
    @State private var scanSource: ScanSource?
    @State private var scanDraft: ScanDraft?
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
                        Menu {
                            addDocumentActions
                        } label: {
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
        .scanFlow(source: $scanSource) { draft in
            scanDraft = draft
        }
        .sheet(item: $scanDraft) { draft in
            EditDocumentView(viewModel: viewModel.scannedDocumentViewModel(for: draft))
        }
        .alert("delete_confirmation_title", isPresented: isConfirmingDelete, presenting: documentToDelete) { document in
            Button("delete", role: .destructive) {
                withAnimation {
                    viewModel.delete(document)
                }
            }
        } message: { _ in
            Text("delete_confirmation_body")
        }
        .onChange(of: viewModel.documents) { _, documents in
            guard let selection else { return }
            if !documents.contains(where: { $0.id == selection }) {
                // The selected document was deleted, here or on another device.
                self.selection = nil
            } else if !viewModel.shownDocuments.contains(where: { $0.id == selection }) {
                // It now belongs to someone else: show everyone's, so the open document is still listed.
                withAnimation {
                    viewModel.filter = .everyone
                }
            }
        }
        .onChange(of: viewModel.filter) {
            // Someone else's document stays open no longer.
            if let selection, !viewModel.shownDocuments.contains(where: { $0.id == selection }) {
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
                    Menu {
                        addDocumentActions
                    } label: {
                        Text("add_new_doc")
                            .foregroundStyle(.onDuckYellow)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } else {
            listView
        }
    }

    private var listView: some View {
        List(selection: $selection) {
            if !viewModel.people.people.isEmpty {
                Section {
                    PeopleFilterBar(selection: $viewModel.filter, people: viewModel.people.people)
                        .peopleFilterRow()
                }
            }
            if !viewModel.favorites.isEmpty {
                Section("dl_favorites") {
                    ForEach(viewModel.favorites) { document in
                        documentRow(document)
                    }
                }
            }
            ForEach(viewModel.groups) { group in
                Section(group.type.localizedName) {
                    ForEach(group.documents) { document in
                        documentRow(document)
                    }
                }
            }
            if viewModel.shownDocuments.isEmpty, let person = viewModel.people.person(with: viewModel.selectedPersonID) {
                ContentUnavailableView {
                    Label("dl_no_person_documents_title", systemImage: "doc.text")
                } description: {
                    Text("dl_no_person_documents_body \(person.name)")
                } actions: {
                    Menu {
                        addDocumentActions
                    } label: {
                        Text("add_new_doc")
                    }
                }
                .listRowBackground(Color.clear)
                .transition(.opacity)
            }
        }
    }

    private func documentRow(_ document: Document) -> some View {
        DocumentRow(document: document, person: viewModel.person(for: document))
            .tag(document.id)
            .swipeActions(edge: .leading) {
                Button {
                    toggleFavorite(document)
                } label: {
                    favoriteLabel(for: document)
                }
                .tint(Self.favoriteTint)
            }
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
                Button {
                    toggleFavorite(document)
                } label: {
                    favoriteLabel(for: document)
                }
                PersonChoices.menu(personID: document.personID, people: viewModel.people.people) { personID in
                    withAnimation {
                        viewModel.setPerson(personID, for: document)
                    }
                }
                Divider()
                Button(role: .destructive) {
                    documentToDelete = document
                } label: {
                    Label("delete", systemImage: "trash")
                }
            }
    }

    /// Deep amber in both modes (duck yellow's light-mode shade): swipe actions draw white on their tint,
    /// which bright yellow can't carry.
    private static let favoriteTint = Color(red: 0x9E / 255, green: 0x6C / 255, blue: 0)

    private func toggleFavorite(_ document: Document) {
        withAnimation {
            viewModel.toggleFavorite(document)
        }
    }

    private func favoriteLabel(for document: Document) -> some View {
        document.isFavorite
            ? Label("dl_remove_favorite", systemImage: "star.slash")
            : Label("dl_add_favorite", systemImage: "star")
    }

    /// Scan from the camera, Photos or Files, or fill in a blank document.
    @ViewBuilder
    private var addDocumentActions: some View {
        if ScanSource.isCameraAvailable {
            Button("scan_camera", systemImage: "doc.viewfinder") {
                scanSource = .camera
            }
        }
        Button("scan_photos", systemImage: "photo.on.rectangle") {
            scanSource = .photos
        }
        Button("scan_files", systemImage: "folder") {
            scanSource = .files
        }
        Divider()
        Button("scan_manual", systemImage: "square.and.pencil", action: viewModel.addNewDocumentButtonPressed)
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
