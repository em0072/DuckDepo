//
//  SettingsView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject private var biometricController = BiometricController.shared
    @ObservedObject private var db: DataBase = DataBase.shared
    @State var documentsCount: Int = 0
    @State var passwordsCount: Int = 0

    
    var body: some View {
        NavigationView {
            Form {
                BiometricSection(isBiometryEnabled: $biometricController.isBiometryEnabled, biometryDelay: $biometricController.biometricDelay)
////                CategorySection()
                OverviewSection(documentCount: $documentsCount, passwordCount: $passwordsCount)
//                
                DeleteAllSection(onDeleteAction: deleteEverything)
            }.navigationBarTitle(Text("sv_title"))
        }
        .onAppear(perform: updateDocumentsCount)
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func updateDocumentsCount() {
        documentsCount = db.fetchDocumentCount()
        passwordsCount = db.fetchPasswordCount()
    }
    
    private func deleteEverything() {
        db.deleteEverything()
        updateDocumentsCount()
    }

}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}




//struct CategorySection: View {
//    var body: some View {
//        Section {
//            NavigationLink {
//                EditFoldersView()
//            } label: {
//                Text("Edit Categories")
//            }
//        } header: {
//            Text("Categories")
//        }
//    }
//}
