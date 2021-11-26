//
//  BindableFloatingTextField.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI
import Combine

struct BindableFloatingTextField: View {
    
    var title: String
    @Binding var value: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
            ZStack(alignment: .leading) {
//                if let title = title {
                        Text(title)
                        .foregroundColor(value.isEmpty ? .gray : Color(white: 0.3))
                        .offset(y: value.isEmpty ? -5 : -25)
                        .scaleEffect(value.isEmpty ? 1 : 0.8, anchor: .leading)
//                }
                TextField("", text: $value)
                    .offset(y: value.isEmpty ? -5 : 0)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .URL ? .none : .words)
            }
            .padding(.top, 15)
            .padding(.bottom, 5)
            .animation(.easeInOut(duration: 0.2), value: value)
    }
    
}

struct BindableFloatingTextField_Previews: PreviewProvider {
    static var previews: some View {
        BindableFloatingTextField(title: "Title", value: .constant("Hello"))
    }
}

