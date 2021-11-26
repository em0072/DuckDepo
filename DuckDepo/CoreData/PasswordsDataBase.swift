//
//  PasswordsDataBase.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation
import CoreData

extension DataBase {

//    static var shared: PasswordsDataBase = PasswordsDataBase()
    
    
    public func save(_ password: Password) {
        let passwordToSave = DDPassword(context: context)
        passwordToSave.name = password.name
        passwordToSave.login = password.login
        passwordToSave.value = password.value
        passwordToSave.website = password.website
        save()
    }
    
    public func delete(_ password: DDPassword) {
        context.delete(password)
        save()
    }
    
    public func fetchPasswordCount() -> Int {
        return fetchCount(for: DDPassword.self)
    }


}
