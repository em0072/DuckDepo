////
////  EditCategoriesView.swift
////  DuckDepo
////
////  Created by Evgeny Mitko on 26/10/2021.
////
//
//import SwiftUI
//import UIKit
//import CoreData
//
//struct EditFoldersView: View {
//    
//    @Environment(\.managedObjectContext) private var viewContext
//
//    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true)], predicate: nil, animation: .default)
//    private var folders: FetchedResults<DDFolder>
//    
//    @StateObject var viewState: ViewState = ViewState()
//    
//    @State var AddCategoryAlertIsPresented: Bool = false
//    @State var isAddingMode: Bool = false
//    @State var isEditingMode: Bool = false
//    @State var folderDoesExsistAlertShown: Bool = false
//    @State var isShownDeleteConfirmation: Bool = false
//    
//    
//    var body: some View {
//        ZStack(alignment: .center) {
//            VStack {
//                List {
//                    ForEach(folders) { folder in
//                        if let folderName = folder.name {
//                            HStack {
//                                Text(folderName)
//                                Spacer()
//                                Text("\(folder.documnets?.count ?? 0) items")
//                            }
//                            .swipeActions(content: {
//                                Button("Delete") {
//                                    checkIfDeletePossible(for: folder)
//                                }
//                                .tint(.red)
//                                Button("Edit") {
//                                    viewState.folderToEdit = folder
//                                    self.isEditingMode = true
//                                }
//                                .tint(.blue)
//                            })
//                        }
//                    }
//                    if folders.count != 0 {
//                        Text("You can swipe a row from right to left to edit or delete a category")
//                            .font(.caption2)
//                            .multilineTextAlignment(.center)
//                            .foregroundColor(Color(uiColor: .lightGray))
//                            .padding([.top, .bottom], 20)
//                    }
//                }
//            }
//            if folders.count == 0 {
//                Text("Seems like you don't have any categories. press \"+\" button at the top to add your first category.")
//                    .padding()
//                    .multilineTextAlignment(.center)
//            }
//        }
//        .toolbar {
//            ToolbarItemGroup(placement: .navigationBarTrailing) {
//                Button(action: {
//                    self.isAddingMode = true
//                }) {
//                    Label("Add Item", systemImage: "plus")
//                }
//            }
//        }
//        .navigationTitle("Edit Categories")
//        .sheet(isPresented: $isAddingMode, content: {
//            AddNewView(isPresented: $isAddingMode, duplicateAlertPresented: $folderDoesExsistAlertShown, type: .folder, onSave: { name in
//                if folders.map({ $0.name }).contains(name) {
//                    self.folderDoesExsistAlertShown = true
//                } else {
//                    self.addFolder(name: name)
//                    self.isAddingMode = false
//                }
//            })
//        })
//        .sheet(isPresented: $isEditingMode, content: {
//            AddNewView(isPresented: $isEditingMode, duplicateAlertPresented: $folderDoesExsistAlertShown, type: .editFolder(name: viewState.folderToEdit?.name ?? ""), onSave: { name in
//                guard let editedFolder = viewState.folderToEdit else {return}
//                for folder in folders {
//                    if folder.name == editedFolder.name ?? "" {
//                        continue
//                    }
//                    if folder.name == name {
//                        self.folderDoesExsistAlertShown = true
//                        return
//                    }
//                }
//                update(editedFolder, with: name)
//                self.isAddingMode = false
//            })
//        })
//        .alert("Delete confirmation", isPresented: $isShownDeleteConfirmation) {
//            Button("Delete", role: .destructive) {
//                if let folder = viewState.folderToDelete {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        delete(folder)
//                        viewState.folderToDelete = nil
//                    }
//                }
//            }
//        } message: {
//            Text("This category contains \(viewState.folderToDelete?.fetchDocumentsCount() ?? 0) document(s) in it. Deleting it will also delete all doocuments inside.\nAre you sure you want do proceed?")
//        }
//
//    }
//    
//    
//    
//    private func addFolder(name: String?) {
//        guard let name = name else { return }
//            withAnimation {
//                let newFolder = DDFolder(context: viewContext)
//                newFolder.name = name
//                newFolder.order = Int32(DDFolder.fetchCount())
//                do {
//                    try viewContext.save()
//                } catch {
//                    let nsError = error as NSError
//                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//                }
//            }
//    }
//    
//    
//    func checkIfDeletePossible(for folder: DDFolder) {
//        if folder.fetchDocumentsCount() == 0 {
//            delete(folder)
//        } else {
//           self.isShownDeleteConfirmation = true
//            viewState.folderToDelete = folder
//        }
//    }
//    
//    private func delete(_ folder: DDFolder) {
//        withAnimation {
//            viewContext.delete(folder)
//            do {
//                try viewContext.save()
//            } catch {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                let nsError = error as NSError
//                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//            }
//        }
//    }
//    
//    private func update(_ folder: DDFolder, with name: String) {
//        folder.name = name
//        PersistenceController.shared.saveContext()
//        isEditingMode = false
//    }
//    
//    
//}
//
////struct EditFoldersView_Previews: PreviewProvider {
////    static var previews: some View {
////        EditFoldersView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
////    }
////}
