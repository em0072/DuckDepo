//
//  AddDocumentButton.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI

struct AddButtonView: View {
    
    var action: (()->())?
    var title: LocalizedStringKey
    @Binding var isActive: Bool

    var body: some View {
            HStack {
                Spacer()
                Button {
                    action?()
                } label: {
                    Text(title)
                }
                Spacer()
            }
            .listRowBackground(!isActive ? Color.duckDisabledButton : Color.duckYellow)
            .foregroundColor(!isActive ? Color.duckDisabledText : Color.black)
            .disabled(!isActive)

    }
}

struct AddDocumentButton_Previews: PreviewProvider {
    static var previews: some View {
        AddButtonView(title: "Add New Document", isActive: .constant(true))
    }
}
