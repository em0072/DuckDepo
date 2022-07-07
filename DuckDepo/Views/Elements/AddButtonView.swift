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
                    ZStack {
                        if isEnabled {
                            Color.duckYellow
                                .layoutPriority(-1)
                                .cornerRadius(10)
                        }
                    HStack {
                        Spacer()
                    Text(title)
                            .foregroundColor(isEnabled ? .black : .duckDisabledText)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    }
                }
                .buttonStyle(NeuRectButtonStyle())
                .disabled(!isEnabled)
    }
}


struct AddDocumentButton_Previews: PreviewProvider {
    static var previews: some View {
        AddButtonView(title: "Add New Document")
            .disabled(false)
    }
}
