//
//  NeuNavigationCloseButton.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 07/07/2022.
//

import SwiftUI

struct NeuNavigationCloseButton: View {
    
    let action: (()->())?
    
    var body: some View {
        Button {
            action?()
        } label: {
            Image(systemName: "xmark")
                .font(.footnote)
                .padding(7)
        }
        .buttonStyle(NeuCircleButtonStyle())
    }
}

struct NeuNavigationCloseButton_Previews: PreviewProvider {
    static var previews: some View {
        NeuNavigationCloseButton(action: nil)
    }
}
