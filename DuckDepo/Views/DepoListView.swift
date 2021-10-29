//
//  DepoListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI
import CoreData

struct DepoListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true)], predicate: nil, animation: .default)
    private var folders: FetchedResults<DDFolder>
    
    @State var isaddingNewDocumentView: Bool = false
    
    var body: some View {
        NavigationView {
            ListView(folders: folders, isAddingNewDocumentView: $isaddingNewDocumentView)
            .navigationBarTitle(Text("🦆 Depo"))
        }
    }
}

struct DepoListView_Previews: PreviewProvider {
    static var previews: some View {
        DepoListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct ListView: View {
    
    var folders: FetchedResults<DDFolder>
    @Binding var isAddingNewDocumentView: Bool
    
    var body: some View {
        List {
            ForEach(folders) { folder in
                if let folderName = folder.name {
                    Section {
                        if let dddocuments = folder.getDocuments() {
                            ForEach(dddocuments) { document in
                                if let documentName = document.name {
                                    NavigationLink(destination: DocumentView(document: document)) {
                                        Text(documentName)
                                    }
                                    
                                    
                                }
                            }
                        }
                    } header: {
                        Text(folderName)
                    }
                    
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    self.isAddingNewDocumentView = true
                }) {
                    Label("Add Item", systemImage: "plus")
                }
                .sheet(isPresented: $isAddingNewDocumentView) {
                    AddNewDocumentView(isPresented: $isAddingNewDocumentView)
                }
                
            }
        }
    }
}
