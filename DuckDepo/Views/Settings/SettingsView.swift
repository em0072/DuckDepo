//
//  SettingsView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI

struct SettingsView: View {
    
    @StateObject private var biometricController = BiometricController.shared
    @State var documentsCount: Int = 0
    @State var passwordsCount: Int = 0
    
    @State var showAutofillInfo: Bool = false

    private var db: DataBase = DataBase.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neumorphicBackground
                    .ignoresSafeArea()
                
                listView()
            }
            .navigationTitle("sv_title")
        }
        .onAppear(perform: updateDocumentsCount)
        .sheet(isPresented: $showAutofillInfo, content: { AutofillInfoView() })
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func listView() -> some View {
        ScrollView {
            VStack {
                BiometricSection(isBiometryEnabled: $biometricController.isBiometryEnabled, biometryDelay: $biometricController.biometricDelay)
                FixedSpacer(25)
                
                OverviewSection(documentCount: $documentsCount, passwordCount: $passwordsCount)
                FixedSpacer(25)
                
                HelpSection(showAutofillInfo: $showAutofillInfo)
                FixedSpacer(25)
                
                DeleteAllSection(onDeleteAction: deleteEverything)
                FixedSpacer(25)
            }
            .padding(16)
        }
    }
    
    private func updateDocumentsCount() {
        documentsCount = DataBase.shared.fetchDocumentCount()
        passwordsCount = PasswordsStorage().count()
    }
    
    private func deleteEverything() {
        db.deleteEverything()
        updateDocumentsCount()
    }

}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
            SettingsView()
//        }
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
