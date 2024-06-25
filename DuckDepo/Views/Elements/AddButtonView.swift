//
//  AddDocumentButton.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/11/2021.
//

import SwiftUI

struct AddButtonView: View {
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    var title: String
    var action: (()->())?
    
    var body: some View {
        Button {
            action?()
        } label: {
                HStack {
                    Spacer()
                    
                    Text(title)
                        .foregroundColor(isEnabled ? .black : .disabledText)
                    
                    Spacer()
                }
        }
        .listRowBackground(Color.duckYellow.opacity(isEnabled ? 1 : 0.3))
        .opacity(isEnabled ? 1 : 0.3)
        .disabled(!isEnabled)
    }
}


struct AddDocumentButton_Previews: PreviewProvider {
    static var previews: some View {
        List {
            AddButtonView(title: "Add New Document")
                .disabled(false)
        }
    }
}
