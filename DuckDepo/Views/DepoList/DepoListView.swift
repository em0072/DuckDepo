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
    private var documents: FetchedResults<DDDocument>
    @StateObject private var viewModel: ViewModel = ViewModel()
        
    @State var isAddingNewDocumentView: Bool = false
//    @State var isAddingNewCategoryView: Bool = false
    
    
    private var bindableNoDocument: Binding<Bool> { Binding (
        get: {documents.isEmpty},
        set: {_ in return}
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
            if !documents.isEmpty {
                List(documents) { document in
                    NavigationLink(destination: DocumentView(document: document)) {
                        DocumentRow(document: document, isShared: viewModel.isShared(document))
                    }
                }
            } else {
                //Initial Instructions
                InitialInstructionsView(isShowingNewDocumentAdd: $isAddingNewDocumentView)
            }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            self.isAddingNewDocumentView = true
                        }) {
                            Image(systemName: "plus")
                        }
                }
            }
            .navigationTitle("🦆 Depo")
            NoDocumentSelectedView()

        }
//        .navigationViewStyle(StackNavigationViewStyle())
//        .sheet(isPresented: $isAddingNewCategoryView) {
//            self.isAddingNewCategoryView = false
//        } content: {
//            AddNewView(isPresented: $isAddingNewCategoryView, duplicateAlertPresented: .constant(false), type: .folder, onSave: { name in
////                self.addFolder(name: name)
//                self.isAddingNewCategoryView = false
//            })
//        }
        .fullScreenCover(isPresented: $isAddingNewDocumentView) {
            EditDocumentView(isPresented: $isAddingNewDocumentView, type: .new, selectedFolder: viewModel.folderNameToAddDoc, onDismiss: {
                viewModel.folderNameToAddDoc = nil
            })
        }
        

    }
        
    
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
}

//struct DepoListView_Previews: PreviewProvider {
//    static var previews: some View {
//        DepoListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}

struct DocumentRow: View {
    
    @ObservedObject var document: DDDocument
    var isShared: Bool

    var body: some View {
        if isShared {
            Label(document.name ?? "", systemImage: "person.2.circle")
                .foregroundColor(Color.duckText)
        } else {
            Text(document.name ?? "")
        }
    }
}

struct InitialInstructionsView: View {
    
    @Binding var isShowingNewDocumentAdd: Bool
    
    var body: some View {
            VStack {
                    VStack {
                        Image(systemName: "lock.doc")
                            .font(.largeTitle)
                            .padding()
                        Text("You'll find you documents here!")
                            .font(.headline)
                            .padding(.bottom, 5)
                        Text("Your documents are stored encrypted on your device and your iCloud account, which means that your information is fully encrypted and available only for you.")
                            .font(.caption)
                    }
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing], 15)
            }
    }
}
