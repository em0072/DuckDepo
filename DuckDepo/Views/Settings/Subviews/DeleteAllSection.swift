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
                HStack {
                    Text("sv_delete_all_button")
                        .bold()
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .foregroundColor(.red)
            .buttonStyle(NeuRectButtonStyle())
            .confirmationDialog("sv_delete_all_confirm_title", isPresented: $isShowingDeleteAlert, titleVisibility: .visible, actions: {
                Button("sv_delete_all_confirm_button", role: .destructive, action: {onDeleteAction?()})
            }, message: {
                Text("sv_delete_all_confirm_body")
            })

            
        } header: {
            NeuSectionTitle(title: "sv_content_reset".localized())
        }
    }
    
}

struct DeleteAllSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            DeleteAllSection()
        }
    }
}
