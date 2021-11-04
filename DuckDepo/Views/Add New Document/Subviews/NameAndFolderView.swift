//
//  NameAndFolder.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI
import CoreData

struct NameAndFolderView: View {
    
    @Binding var name: String
    @Binding var selectedFolder: Int
    @Binding var folders: [DDFolder]
    
    var body: some View {
        Section("Main Info") {
            TextField("Add New Document", text: $name, prompt: Text("Document Name"))
            Picker(selection: $selectedFolder, label: Text("Category")) {
                ForEach(0..<folders.count, id: \.self) { index in
                    Text(folders[index].name ?? "").tag(index)
                }
            }
        }
    }
}

struct NameAndFolderView_Previews: PreviewProvider {
    
    static func folders() -> [DDFolder] {
        let container = PersistenceController.preview
        let folderController = NSFetchedResultsController(fetchRequest: DDFolder.fetchRequest(), managedObjectContext: container.container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        try? folderController.performFetch()
        return folderController.fetchedObjects ?? []
    }
    
    static var previews: some View {
        Form {
            NameAndFolderView(name: .constant(""), selectedFolder: .constant(0), folders: .constant(folders()))
        }
    }
}

