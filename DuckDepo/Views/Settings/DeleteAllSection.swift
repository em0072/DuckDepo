//
//  DeleteAllSection.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 16/11/2021.
//

import SwiftUI

struct DeleteAllSection: View {
    
    @State private var isShowingDeleteAlert: Bool = false
    var onDeleteAction: (()->())?
    
    var body: some View {
        Section {
        Button("Delete All Data", role: .destructive, action: showDeleteAllAlert)
            .confirmationDialog("Are you sure?", isPresented: $isShowingDeleteAlert, titleVisibility: .visible, actions: {
                Button("Yes, I am sure!", role: .destructive, action: {onDeleteAction?()})
            }, message: {
                Text("This action will delete all data and it cannot be undone. Are you sure you want to proceed?")
            })
        } header: {
            Text("Reset Content")
        }
    }
    
    private func showDeleteAllAlert() {
        isShowingDeleteAlert = true
    }
}

struct DeleteAllSection_Previews: PreviewProvider {
    static var previews: some View {
        DeleteAllSection()
    }
}
