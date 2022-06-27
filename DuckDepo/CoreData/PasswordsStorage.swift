//
//  PasswordsDataBase.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation
import CoreData
import Combine

class PasswordsStorage: NSObject {
    
    let database = DataBase.shared
    var passwords = CurrentValueSubject<[Password], Never>([])
    private var fetchedRequestController: NSFetchedResultsController<DDPassword>
    
    override init() {

        let fetchRequest = DDPassword.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DDPassword.name, ascending: true)]
        fetchedRequestController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataBase.shared.context, sectionNameKeyPath: nil, cacheName: nil)
        super.init()
        
        fetchedRequestController.delegate = self
        do {
            try fetchedRequestController.performFetch()
            controllerDidChangeContent(fetchedRequestController as! NSFetchedResultsController<NSFetchRequestResult>)
        } catch {
            print("Oops, could not fetch passwords")
        }
    }
    
    func fetch(with id: UUID) -> DDPassword? {
        let fetchRequest = DDPassword.fetchRequest()
        fetchRequest.predicate = DDPassword.predicate(for: id)
        fetchRequest.fetchLimit = 1
        return try? database.context.fetch(fetchRequest).first
    }
    
    func update(_ password: Password) {
        let ddPassword = fetch(with: password.id)
        if let ddPassword = ddPassword {
            ddPassword.update(name: password.name, login: password.login, website: password.website)
            setPasswordValue(password.value, for: password.id)
            database.save()
            
        }
    }
    
    func saveNewPassword(_ password: Password) {
        let ddPassword = DDPassword(context: database.context)
        ddPassword.id = password.id
        ddPassword.update(name: password.name, login: password.login, website: password.website)
        setPasswordValue(password.value, for: password.id)
        database.save()
    }
    
    func delete(_ password: Password) {
        if let ddPassword = fetch(with: password.id) {
            database.context.delete(ddPassword)
        }
    }

    func count() -> Int {
        return database.fetchCount(for: DDPassword.self)
    }
    
    func getPasswordValue(for id: UUID) -> String {
        Keychain.shared.get(id.uuidString) ?? ""
    }
    
    func setPasswordValue(_ value: String, for id: UUID) {
        Keychain.shared.set(value, forKey: id.uuidString)
    }
    
}

extension PasswordsStorage: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let passwords = controller.fetchedObjects as? [DDPassword] else {
            return
        }
        self.passwords.value = passwords.map({ ddPassword in
            var password = ddPassword.convert()
            password.value = getPasswordValue(for: password.id)
            return password
        })
    }
}
