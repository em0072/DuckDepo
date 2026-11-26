//
//  SettingsView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 26/10/2021.
//

import SwiftUI

struct SettingsView: View {

    @ObservedObject private var biometricController = BiometricController.shared
    @ObservedObject private var syncMonitor = SyncMonitor.shared
    @State private var documentsCount = 0
    @State private var passwordsCount = 0
    @State private var showAutofillInfo = false

    private let db = DataBase.shared

    var body: some View {
        NavigationStack {
            List {
                BiometricSection(isBiometryEnabled: $biometricController.isBiometryEnabled,
                                 biometryDelay: $biometricController.biometricDelay)
                ICloudSection(monitor: syncMonitor)
                OverviewSection(documentCount: $documentsCount, passwordCount: $passwordsCount)
                HelpSection(showAutofillInfo: $showAutofillInfo)
                DeleteAllSection(onDeleteAction: deleteEverything)
            }
            .navigationTitle("sv_title")
        }
        .onAppear(perform: updateCounts)
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: db.context)) { _ in
            updateCounts()
        }
        .sheet(isPresented: $showAutofillInfo) {
            AutofillInfoView()
                .presentationDragIndicator(.visible)
        }
    }

    private func updateCounts() {
        documentsCount = db.fetchDocumentCount()
        passwordsCount = db.fetchCount(for: DDPassword.self)
    }

    private func deleteEverything() {
        db.deleteEverything()
        updateCounts()
    }
}

#Preview {
    SettingsView()
}
