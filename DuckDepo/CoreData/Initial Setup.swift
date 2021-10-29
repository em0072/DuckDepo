//
//  Initial Setup.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import Foundation
import SwiftUI
import CloudKit

enum InitialKeys {
    static let coreDataPopulated = "coreDataPopulated"
}

class InitialSetup {
    
    static let main = InitialSetup()
    
    private var viewContext = PersistenceController.shared.container.viewContext

    
    private init() {}
    
    func populateCoreDataIfNeeded() {
        return
        let coreDataIsPopulated = UserDefaults.standard.bool(forKey: InitialKeys.coreDataPopulated)
        guard !coreDataIsPopulated else { return }
        
                
        let idsFolder = DDFolder(context: viewContext)
        idsFolder.name = "Ids"
        idsFolder.order = 0
        
        let document = DDDocument(context: viewContext)
        document.name = "Passport"
        document.number = "8482 920239"
        document.folder = idsFolder
        
        let document2 = DDDocument(context: viewContext)
        document2.name = "Birth Certificate"
        document2.number = "BH384882"
        document2.folder = idsFolder
        
        [document, document2].forEach {
            idsFolder.addToDocumnets($0)
        }
        
        
        let transportFolder = DDFolder(context: viewContext)
        transportFolder.name = "Transport"
        idsFolder.order = 1

        let transportDoc = DDDocument(context: viewContext)
        transportDoc.name = "Car passport"
        transportDoc.number = "24 2445"
        transportDoc.folder = transportFolder
        
        transportFolder.addToDocumnets(transportDoc)
    
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        UserDefaults.standard.set(true, forKey: InitialKeys.coreDataPopulated)
    }
    
}
