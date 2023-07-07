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
            Button {
                isShowingDeleteAlert = true
            } label: {
                Text("sv_delete_all_button")
            }
            .foregroundColor(.red)
            .bold()
            .confirmationDialog("sv_delete_all_confirm_title", isPresented: $isShowingDeleteAlert, titleVisibility: .visible) {
                Button("sv_delete_all_confirm_button", role: .destructive, action: {onDeleteAction?()})
            } message: {
                Text("sv_delete_all_confirm_body")
            }
        } header: {
            Text("sv_content_reset")
        }
    }
    
}

struct DeleteAllSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            DeleteAllSection()
        }
    }
}
