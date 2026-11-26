//
//  DeleteAllSection.swift
//  DuckDepo
//

import SwiftUI

/// Deletes every document and password, after asking.
struct DeleteAllSection: View {

    var onDeleteAction: () -> Void

    @State private var isShowingDeleteAlert = false

    var body: some View {
        Section {
            Button("sv_delete_all_button", role: .destructive) {
                isShowingDeleteAlert = true
            }
            .frame(maxWidth: .infinity)
            .confirmationDialog("sv_delete_all_confirm_title", isPresented: $isShowingDeleteAlert, titleVisibility: .visible) {
                Button("sv_delete_all_confirm_button", role: .destructive, action: onDeleteAction)
            } message: {
                Text("sv_delete_all_confirm_body")
            }
        } footer: {
            Text("sv_delete_all_footer")
        }
    }
}

#Preview {
    List {
        DeleteAllSection {}
    }
}
