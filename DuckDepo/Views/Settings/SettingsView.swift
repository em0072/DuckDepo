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
            listView
                .navigationTitle("sv_title")
        }
        .onAppear(perform: updateDocumentsCount)
        .sheet(isPresented: $showAutofillInfo, content: {
            AutofillInfoView()
                .presentationDragIndicator(.visible)
        })
        .navigationViewStyle(StackNavigationViewStyle())
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

extension SettingsView {
    private var listView: some View {
        List {
            BiometricSection(isBiometryEnabled: $biometricController.isBiometryEnabled, biometryDelay: $biometricController.biometricDelay)
            
            OverviewSection(documentCount: $documentsCount, passwordCount: $passwordsCount)
            
            HelpSection(showAutofillInfo: $showAutofillInfo)
            
            DeleteAllSection(onDeleteAction: deleteEverything)
        }
    }
}

#Preview {
    
    struct PreviewWrapper: View {
        var body: some View {
            SettingsView()
                .preferredColorScheme(.dark)
        }
    }
    
    return SettingsView()
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
