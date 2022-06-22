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
                    ScrollView {
                        VStack {
                            ForEach(documents) { document in
                                NavigationLink(destination: DocumentView(document: document)) {
                                    DocumentRow(document: document, isShared: viewModel.isShared(document))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .onMove(perform: move)
                            
                        }
                    }
                    .padding(.horizontal)
//                    .listStyle(.plain)
                    .environment(\.editMode, viewModel.isReordering ? .constant(.active) : .constant(.inactive))
                } else {
                    //Initial Instructions
                    InitialInstructionsView(type: .documents)
                }
            }
            .background(Color(.systemGray6))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.isAddingNewDocumentView = true
                    }) {
                            Image(systemName: "plus")
                        }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Toggle(isOn: $viewModel.isReordering) {
                        Image(systemName: "shuffle")

                    }
                }
            }
            .navigationTitle("🦆 Depo")
            .navigationBarTitleDisplayMode(.large)
            .animation(.default, value: viewModel.isReordering)
            NoSelectionViewView(type: .document)

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
            EditDocumentView(isPresented: $isAddingNewDocumentView, type: .new)
        }
        

    }
    
    private func move(from index: IndexSet, to destination: Int) {
        let docList = documents.map{$0}
        viewModel.move(from: index, to: destination, in: docList)
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

struct DepoListView_Previews: PreviewProvider {
    static var previews: some View {
        DepoListView()
            .environment(\.managedObjectContext, PersistenceController.shared.context)
    }
}

struct DocumentRow: View {
    
    @ObservedObject var document: DDDocument
    var isShared: Bool

    var body: some View {
        
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
            HStack {
                document.convert().documentType.image
                    .frame(width: 40, height: 40)
                VStack {
                    Text(document.name ?? "")
                }
            }
            .padding(15)
        }
        
//        if isShared {
//            Label(document.name ?? "", systemImage: "person.2.circle")
//                .foregroundColor(Color.duckText)
//        } else {
//            Text(document.name ?? "")
//        }
    }
}
