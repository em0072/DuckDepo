//
//  DepoListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI
import CoreData
import Combine

struct DepoListView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DDDocument.order, ascending: true)], predicate: nil, animation: .default)
    private var folders: FetchedResults<DDFolder>
    @StateObject private var viewModel: ViewModel = ViewModel()
        
    @State var isAddingNewDocumentView: Bool = false
    @State var isAddingNewCategoryView: Bool = false
    
    private var bindableNoFolders: Binding<Bool> { Binding (
        get: {self.folders.isEmpty},
        set: {_ in return}
        )
    }
    
    private var bindableNoDocument: Binding<Bool> { Binding (
        get: {self.folders.count == 1 && self.folders.first?.fetchDocumentsCount() ?? 0 == 0},
        set: {_ in return}
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                List(folders) { folder in
                        if let folderName = folder.name {
                            Section {
                                if let dddocuments = folder.fetchDocuments() {
                                    ForEach(dddocuments) { document in
                                        NavigationLink(destination: DocumentView(document: document)) {
                                            DocumentRow(document: document)
                                        }
                                    }
                                }
                                if folder.fetchDocumentsCount() == 0 {
                                    Button("Add New Document") {
                                        viewModel.folderNameToAddDoc = folderName
                                        isAddingNewDocumentView = true
                                    }
                                }
                            } header: {
                                Text(folderName)
                                    .font(.headline)
                                    .foregroundColor(Color(uiColor: .label))
                            }
                            .textCase(nil)

                        }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !folders.isEmpty {
                            Button(action: {
                                self.isAddingNewDocumentView = true
                            }) {
                                Label("Add Item", systemImage: "plus")
                            }
                        }
                    }
                    }

                // Initial Instructions
                InitialInstructionsView(noFolders: bindableNoFolders,
                                        noDocuments: bindableNoDocument,
                                        isShowingNewCategoryAdd: $isAddingNewCategoryView,
                                        isShowingNewDocumentAdd: $isAddingNewDocumentView)
            }
            .navigationTitle("🦆 Depo")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isAddingNewCategoryView) {
            self.isAddingNewCategoryView = false
        } content: {
            AddNewView(isPresented: $isAddingNewCategoryView, duplicateAlertPresented: .constant(false), type: .folder, onSave: { name in
                self.addFolder(name: name)
                self.isAddingNewCategoryView = false
            })
        }
        .fullScreenCover(isPresented: $isAddingNewDocumentView) {
            EditDocumentView(isPresented: $isAddingNewDocumentView, type: .new, selectedFolder: viewModel.folderNameToAddDoc, onDismiss: {
                viewModel.folderNameToAddDoc = nil
            })
        }
    }
        
    
    private func addFolder(name: String?) {
        guard let name = name else { return }
            withAnimation {
                let newFolder = DDFolder(context: viewContext)
                newFolder.name = name
                newFolder.order = Int32(DDFolder.fetchCount())
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
    }
}

//struct DepoListView_Previews: PreviewProvider {
//    static var previews: some View {
//        DepoListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}

struct DocumentRow: View {
    @ObservedObject var document: DDDocument
    
    var body: some View {
        Text(document.name ?? "")
    }
}

struct InitialInstructionsView: View {
    
    @Binding var noFolders: Bool
    @Binding var noDocuments: Bool
    @Binding var isShowingNewCategoryAdd: Bool
    @Binding var isShowingNewDocumentAdd: Bool
    
    var body: some View {
        if noFolders {
            VStack(alignment: .center) {
                VStack {
                Text("Yikes!")
                        .padding(.bottom, 5)
                Text("It looks empty here. Let's add a new category to store your documents in.")
                }
                .padding()
                .multilineTextAlignment(.center)
                Button {
                    isShowingNewCategoryAdd = true
                } label: {
                    Text("Add Category")
                }
                .padding(.bottom, 15)
                Text("If you already used DuckDepo on another device, please give it a moment to update the database.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(uiColor: .lightGray))
                    .padding()
            }
        } else if noDocuments {
            VStack {
                    VStack {
                    Text("🎉")
                        .font(.largeTitle)
                    Text("Congratulations!")
                            .padding(.bottom, 5)
                    Text("You created your first category and looks like you are ready to add your first document")
                    }
                    .multilineTextAlignment(.center)
                    .padding()
                    Button {
                        isShowingNewDocumentAdd = true
                    } label: {
                        Text("Add Document")
                    }
            }
        }
    }
}
