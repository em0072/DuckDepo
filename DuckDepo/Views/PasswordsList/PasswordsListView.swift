//
//  PasswordsListView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/06/2022.
//

import SwiftUI

struct PasswordsListView: View {

    @State var viewModel: PasswordsListViewModel
    @State private var selection: Password.ID?
    @State private var passwordToDelete: Password?
    @State private var passkeyToDelete: PasskeySummary?
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    private var syncMonitor = SyncMonitor.shared
    private var health = PasswordHealthMonitor.shared

    init(viewModel: PasswordsListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationTitle("plv_title")
                .syncActivitySubtitle(syncMonitor)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: viewModel.addNewPasswordButtonPressed) {
                            Label("epv_new_password_title", systemImage: "plus")
                        }
                    }
                }
                .onAppear {
                    viewModel.start()
                    health.start()
                }
        } detail: {
            if selection == PasswordHealthView.selectionID {
                NavigationStack {
                    PasswordHealthView()
                }
            } else if let password = viewModel.password(with: selection) {
                PasswordView(password: password)
                    .id(password.id)
            } else if let passkey = viewModel.passkey(with: selection) {
                PasskeyView(passkey: passkey) {
                    passkeyToDelete = passkey
                }
                .id(passkey.id)
            } else {
                ContentUnavailableView("pl_no_selection_title",
                                       systemImage: "key",
                                       description: Text("no_doc_view_body_passwords"))
            }
        }
        .sheet(isPresented: $viewModel.isAddingNewPassword) {
            EditPasswordView(type: .new, personID: viewModel.selectedPersonID)
        }
        .alert("epv_delete_alert_title", isPresented: isConfirmingDelete, presenting: passwordToDelete) { password in
            Button("epv_delete_alert_delete", role: .destructive) {
                withAnimation {
                    viewModel.delete(password)
                }
            }
        } message: { _ in
            Text("epv_delete_alert_body")
        }
        .alert("passkey_delete_title", isPresented: isConfirmingPasskeyDelete, presenting: passkeyToDelete) { passkey in
            Button("delete", role: .destructive) {
                withAnimation {
                    viewModel.delete(passkey)
                }
            }
        } message: { passkey in
            Text("passkey_delete_body \(passkey.relyingParty)")
        }
        .onChange(of: viewModel.passwords) {
            clearDeletedSelection()
            // The open password now belongs to someone else: show everyone's, so it's still listed.
            if let password = viewModel.password(with: selection), !viewModel.shownPasswords.contains(password) {
                withAnimation {
                    viewModel.filter = .everyone
                }
            }
        }
        .onChange(of: viewModel.passkeys) {
            clearDeletedSelection()
        }
        // Passkeys are made in AutoFill, another process; look again when coming back. A password changed
        // on another device changes only the keychain.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.reloadPasskeys()
                health.refresh()
            }
        }
        .onChange(of: health.showsInPasswords) {
            clearDeletedSelection()
        }
        .onChange(of: viewModel.filter) {
            // Someone else's password stays open no longer.
            if let password = viewModel.password(with: selection), !viewModel.shownPasswords.contains(password) {
                selection = nil
            } else if viewModel.passkey(with: selection) != nil, viewModel.shownPasskeys.isEmpty {
                selection = nil
            }
        }
    }

    private func clearDeletedSelection() {
        if selection == PasswordHealthView.selectionID {
            if !health.showsInPasswords {
                selection = nil
            }
        } else if viewModel.password(with: selection) == nil && viewModel.passkey(with: selection) == nil {
            selection = nil
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if viewModel.passwords.isEmpty && viewModel.passkeys.isEmpty {
            if syncMonitor.showsActivity && syncMonitor.isDownloading {
                DownloadingFromICloudView(type: .passwords)
            } else {
                ContentUnavailableView {
                    Label("ii_headline_passwords", systemImage: "key")
                } description: {
                    Text("ii_caption_passwords")
                } actions: {
                    Button("epv_add_new_password_button", action: viewModel.addNewPasswordButtonPressed)
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(.onDuckYellow)
                }
            }
        } else {
            listView
        }
    }

    private var listView: some View {
        List(selection: $selection) {
            if !viewModel.people.people.isEmpty {
                Section {
                    PeopleFilterBar(selection: $viewModel.filter, people: viewModel.people.people)
                        .peopleFilterRow()
                }
            }
            if health.showsInPasswords {
                Section {
                    PasswordHealthLabel(toFixCount: health.report.toFixCount, isLoaded: health.isLoaded)
                        .tag(PasswordHealthView.selectionID)
                }
            }
            if !viewModel.shownPasswords.isEmpty {
                Section {
                    ForEach(viewModel.shownPasswords) { password in
                        passwordRow(password)
                    }
                }
            } else if let person = viewModel.people.person(with: viewModel.selectedPersonID) {
                ContentUnavailableView {
                    Label("pl_no_person_passwords_title", systemImage: "key")
                } description: {
                    Text("pl_no_person_passwords_body \(person.name)")
                } actions: {
                    // Borderless: otherwise the whole row would be the button.
                    Button("epv_add_new_password_button", action: viewModel.addNewPasswordButtonPressed)
                        .buttonStyle(.borderless)
                }
                .listRowBackground(Color.clear)
                .transition(.opacity)
            }
            if !viewModel.shownPasskeys.isEmpty {
                Section("pl_passkeys") {
                    ForEach(viewModel.shownPasskeys) { passkey in
                        PasskeyRow(passkey: passkey)
                            .tag(passkey.id)
                            .swipeActions(edge: .trailing) {
                                Button {
                                    passkeyToDelete = passkey
                                } label: {
                                    Label("delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    passkeyToDelete = passkey
                                } label: {
                                    Label("delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }

    private func passwordRow(_ password: Password) -> some View {
        PasswordRow(name: password.name, login: password.login, person: viewModel.person(for: password))
            .tag(password.id)
            .swipeActions(edge: .leading) {
                Button {
                    viewModel.copyValue(of: password)
                } label: {
                    Label("copy_password", systemImage: "key.fill")
                }
                .tint(.indigo)
                if !password.login.isEmpty {
                    Button {
                        viewModel.copyLogin(of: password)
                    } label: {
                        Label("copy_login", systemImage: "person.fill")
                    }
                    .tint(.gray)
                }
            }
            .swipeActions(edge: .trailing) {
                Button {
                    passwordToDelete = password
                } label: {
                    Label("delete", systemImage: "trash")
                }
                .tint(.red)
            }
            .contextMenu {
                contextMenu(for: password)
            }
    }

    @ViewBuilder
    private func contextMenu(for password: Password) -> some View {
        if !password.login.isEmpty {
            Button {
                viewModel.copyLogin(of: password)
            } label: {
                Label("copy_login", systemImage: "person")
            }
        }
        Button {
            viewModel.copyValue(of: password)
        } label: {
            Label("copy_password", systemImage: "key")
        }
        if let url = password.websiteURL {
            Button {
                openURL(url)
            } label: {
                Label("dv_open_website", systemImage: "safari")
            }
        }
        PersonChoices.menu(personID: password.personID, people: viewModel.people.people) { personID in
            withAnimation {
                viewModel.setPerson(personID, for: password)
            }
        }
        Divider()
        Button(role: .destructive) {
            passwordToDelete = password
        } label: {
            Label("delete", systemImage: "trash")
        }
    }

    private var isConfirmingPasskeyDelete: Binding<Bool> {
        Binding {
            passkeyToDelete != nil
        } set: { isPresented in
            if !isPresented {
                passkeyToDelete = nil
            }
        }
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding {
            passwordToDelete != nil
        } set: { isPresented in
            if !isPresented {
                passwordToDelete = nil
            }
        }
    }
}

#Preview {
    PasswordsListView(viewModel: PasswordsListViewModel())
}
