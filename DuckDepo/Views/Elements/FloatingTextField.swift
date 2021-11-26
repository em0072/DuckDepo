//
//  FloatingTextField.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 29/10/2021.
//

import SwiftUI
import Combine

protocol FloatingTextFieldDelegate {
    func valueChangedForField(with id: UUID, newValue: String)
}

struct FloatingTextField: View {
    
    var title: String
    var value: String = ""
    @State var textFieldValue: String = ""
    var id: UUID = UUID()
    var delegate: FloatingTextFieldDelegate?

    var body: some View {
//        List {
            ZStack(alignment: .leading) {
                if let title = title {
                        Text(title)
                        .foregroundColor(textFieldValue.isEmpty ? .gray : Color(white: 0.3))
                        .offset(y: textFieldValue.isEmpty ? -5 : -25)
                        .scaleEffect(textFieldValue.isEmpty ? 1 : 0.8, anchor: .leading)
                }
                TextField("", text: $textFieldValue)
                    .offset(y: textFieldValue.isEmpty ? -5 : 0)
            }
            .padding(.top, 15)
            .padding(.bottom, 5)
            .animation(.easeInOut(duration: 0.2), value: textFieldValue)
//        }
        .onAppear {
            textFieldValue = value
        }
        .onChange(of: textFieldValue) { newValue in
            delegate?.valueChangedForField(with: id, newValue: newValue)
        }
        
    }
    
    
}

struct FloatingTextField_Previews: PreviewProvider {
    
    
    static var previews: some View {
        
        FloatingTextField(title: "Title", id: UUID())
        
    }
}

