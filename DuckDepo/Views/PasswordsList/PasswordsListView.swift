//
//  PasswordsView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct PasswordsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DDPassword.name, ascending: true)], predicate: nil, animation: .default)
    private var passwords: FetchedResults<DDPassword>
    @StateObject private var viewModel: ViewModel = ViewModel()

    @State private var isAddingNewPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if !passwords.isEmpty {
                    List(passwords) { password in
                        NavigationLink {
                            PasswordView(password: password)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(password.name)
                                if !password.login.isEmpty {
                                    Text(password.login)
                                        .font(.caption)
                                }
                            }

                        }
                    }
                } else {
                    InitialInstructionsView(type: .passwords)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingNewPassword = true
                    }) {
                            Image(systemName: "plus")
                        }
                }
            }
            .navigationTitle("plv_title")
            .fullScreenCover(isPresented: $isAddingNewPassword) {
                EditPasswordView(isPresented: $isAddingNewPassword, type: .new)
            }
            NoSelectionViewView(type: .password)
        }
    }
}

struct PasswordsListView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordsListView()
            .environment(\.managedObjectContext, PersistenceController.shared.context)
    }
}
