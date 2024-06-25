//
//  FloatingTextView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 02/11/2021.
//

import SwiftUI
import Foundation

protocol FloatingTextViewDelegate {
    func copied(text: String, withTaps: Bool)
}

struct FloatingTextView: View {

    var title: String
    var value: String
    var url: URL?
    @Binding var isVisible: Bool
    var delegate: FloatingTextViewDelegate?
    
    
    init(title: String, value: String, url: URL? = nil, isVisible: Binding<Bool>? = nil, delegate: FloatingTextViewDelegate? = nil) {
        self.title = title
        self.value = value
        self.url = url
        self._isVisible = isVisible ?? .constant(true)
        self.delegate = delegate
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .foregroundColor(Color(white: 0.3))
                .scaleEffect(0.8, anchor: .leading)
                .padding(.top, 5)
            HStack {
                Group {
                    if let url = url {
                        Link(proccessedValue, destination: url)
                    } else {
                        Text(proccessedValue)
                    }
                }
                .padding(.bottom, 5)
                .contextMenu {
                    if let url {
                        ContextMenuView(type: .link(value: url))
                    } else {
                        ContextMenuView(type: .string(value: value))
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                ClipboardController.shared.copy(string: value)
            }
        }
    }
    
    var proccessedValue: String {
        return isVisible ? value : String(repeating: "•", count: value.count)
    }
    
}

struct FloatingTextView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FloatingTextView(title: "Title", value: "Value")
        }
    }
}
