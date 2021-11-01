//
//  FloatingTextField.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 29/10/2021.
//

import SwiftUI

struct FloatingTextField: View {
    
    @State var text: String = ""
    var title: String

    var body: some View {
        List {
            ZStack(alignment: .leading) {
                if let title = title {
                    withAnimation {
                        Text(title)
                            .foregroundColor(text.isEmpty ? .gray : Color.accentColor)
                            .offset(y: text.isEmpty ? 0 : -25)
                            .scaleEffect(text.isEmpty ? 1 : 0.8, anchor: .leading)
                    }
                }
                TextField("", text: $text)
            }
            .padding(.top, text.isEmpty ? 0 : 15)
            .padding(.bottom, text.isEmpty ? 0 : 5)
            .animation(.default, value: text)
        }
    }
}

struct FloatingTextField_Previews: PreviewProvider {
    
    
    static var previews: some View {
        
        FloatingTextField(title: "Title")
        
    }
}

