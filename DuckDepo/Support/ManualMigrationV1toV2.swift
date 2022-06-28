//
//  ManualMigrationV1toV2.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import SwiftUI
import KeychainSwift

class ManualMigrationV1toV2: ObservableObject {
    
    @Published var progress: CGFloat = 0
    
    let context = DataBase.shared.context
    lazy var keychain = Keychain.shared
    
    var onMigrationEnd: (()->())?
    
    
    func startMigration() {
        Task {
            do {
                try await wait(sec: 1)
                let passwords = try self.getAllPasswords()
                self.setProgress(to: 0.2)
                try await wait(sec: 1)
                self.process(passwords)
                self.setProgress(to: 1)
                try self.context.save()
                try await wait(sec: 1)
                self.onMigrationEnd?()
            } catch(let error) {
                fatalError("Error while manualy migrating - \(error.localizedDescription)")
            }
            
        }
    }
    
    private func getAllPasswords() throws -> [DDPassword] {
        let fetchRequest = DDPassword.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DDPassword.name, ascending: true)]
        let passwords = try context.fetch(fetchRequest)
        return passwords
    }
    
    private func process(_ passwords: [DDPassword]) {
        let onePasswordProgress = 0.8 / Double(passwords.count)
        for password in passwords {
            let id = UUID()
            let passwordValue = password.value
            password.id = id
            keychain.set(passwordValue, forKey: id.uuidString)
//            password.value = ""
            addToProgress(onePasswordProgress)
        }
    }
    
    private func wait(sec: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(sec * Double(1000000000)))
    }
    
    private func setProgress(to value: CGFloat) {
        DispatchQueue.main.async {
            self.progress = value
        }
    }
    
    private func addToProgress(_ vlaue: CGFloat) {
        DispatchQueue.main.async {
            self.progress = min(self.progress + vlaue, 1)
        }
    }
    
}
