//
//  AddDocumentButton.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI

struct AddDocumentButton: View {
    
    var action: (()->())?
    var title: String

    var body: some View {
        Section {
            HStack {
                Spacer()
                Button {
                    action?()
                } label: {
                    Text(title)
                }
                Spacer()
            }
        }
    }
}

struct AddDocumentButton_Previews: PreviewProvider {
    static var previews: some View {
        AddDocumentButton(title: "Add New Document")
    }
}
