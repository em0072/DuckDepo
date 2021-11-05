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
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true)], predicate: nil, animation: .default)
    private var folders: FetchedResults<DDFolder>
        
    @State var isAddingNewDocumentView: Bool = false
    @State var isAddingNewCategoryView: Bool = false

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
                            } header: {
                                Text(folderName)
                            }
                            
                        }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            self.isAddingNewDocumentView = true
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                .navigationBarTitle(Text("🦆 Depo"))
                .sheet(isPresented: $isAddingNewCategoryView) {
                    self.isAddingNewCategoryView = false
                } content: {
                    AddNewView(isPresented: $isAddingNewCategoryView, folderDoesExsistAlertShown: .constant(false), type: .folder) { name in
                        self.addFolder(name: name)
                        self.isAddingNewCategoryView = false
                    }
                }
                .fullScreenCover(isPresented: $isAddingNewDocumentView) {
                    EditDocumentView(isPresented: $isAddingNewDocumentView, type: .new)
                }

                
                // Initial Instructions
                InitialInstructionsView(folderCount: Binding(get: {
                    folders.count
                }, set:{ _ in return}), documentCount: Binding(get: {
                        folders.first?.fetchDocumentsCount() ?? 0
                }, set: { _ in return})) {
                    isAddingNewCategoryView = true
                }
            }
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
    
    @Binding var folderCount: Int
    @Binding var documentCount: Int
    var onNewCategorAdd: ()->()
    
    
    var body: some View {
        if folderCount == 0 {
            VStack(alignment: .center) {
                Text("Wow! It looks empty here. Press the button below to add your first category.")
                    .padding()
                    .multilineTextAlignment(.center)
                Button {
                    onNewCategorAdd()
                } label: {
                    Text("Add Category")
                }
            }
        } else if folderCount == 1 && documentCount == 0 {
                VStack {
                    Text("🎉")
                        .font(.largeTitle)
                        .padding()
                    Text("Nice, you have first category! Now press \"+\" button at the top to add your first document.")
                        .multilineTextAlignment(.center)
                }
//            }
        }
    }
}
