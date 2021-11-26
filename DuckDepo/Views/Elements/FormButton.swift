//
//  FormButton.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct FormButton: View {
    
    var action: ()->()
    var imageSystemName: String
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: imageSystemName)
                .padding(8)
        }
        .buttonStyle(BorderlessButtonStyle())
        .background(.ultraThinMaterial, in: Circle())
        .aspectRatio(1, contentMode: .fit)
    }
}

struct FormButton_Previews: PreviewProvider {
    static var previews: some View {
        FormButton(action: {
            
        }, imageSystemName: "heart.fill")
    }
}
