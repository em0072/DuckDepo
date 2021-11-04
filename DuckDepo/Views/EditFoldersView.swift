//
//  EditCategoriesView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI
import UIKit
import CoreData

struct EditFoldersView: View {
    
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true)], predicate: nil, animation: .default)
    private var folders: FetchedResults<DDFolder>
    
    @State var AddCategoryAlertIsPresented: Bool = false
    @State var isAddingMode: Bool = false
    @State var folderDoesExsistAlertShown: Bool = false
    @State var isShownDeleteConfirmation: Bool = false


    var body: some View {
        ZStack(alignment: .center) {
            List {
                ForEach(folders) { folder in
                    if let folderName = folder.name {
                        HStack {
                            Text(folderName)
                            Spacer()
                            Text("\(folder.documnets?.count ?? 0) items")
                        }
                    }
                }
                .onDelete(perform: deleteFolder)
                
            }
            if folders.count == 0 {
                Text("Seems like you don't have any categories. press \"+\" button at the top to add your first category.")
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    self.isAddingMode = true
                }) {
                    Label("Add Item", systemImage: "plus")
                }
                EditButton()
            }
        }
        .navigationTitle("Edit Categories")
        .sheet(isPresented: $isAddingMode) {
            self.isAddingMode = false
        } content: {
            AddNewView(isPresented: $isAddingMode, folderDoesExsistAlertShown: $folderDoesExsistAlertShown, type: .folder) { name in
                if folders.map({ $0.name }).contains(name) {
                    self.folderDoesExsistAlertShown = true
                } else {
                    self.addFolder(name: name)
                    self.isAddingMode = false
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
    
    
    private func deleteFolder(offsets: IndexSet) {
        
        withAnimation {
            offsets.map { folders[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    
}

//struct EditFoldersView_Previews: PreviewProvider {
//    static var previews: some View {
//        EditFoldersView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
