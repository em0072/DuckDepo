//
//  NeuNavigationCloseButton.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 07/07/2022.
//

import SwiftUI

struct CloseButton: View {
    
    let action: (()->())
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: "xmark")
        }
    }
}

struct CloseButton_Previews: PreviewProvider {
    static var previews: some View {
        CloseButton(action: {})
    }
}
