//
//  ContextMenuView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/06/2024.
//

import Foundation
import SwiftUI

struct ContextMenuView: View {
    
    @Environment(\.openURL) private var openURL

    enum CopyType {
        case string(value: String)
        case image(value: UIImage)
        case link(value: URL)
    }
    
    let type: CopyType
    
    var body: some View {
        Button(action: {
            copyValue()
        }) {
            Text("dv_copy_to_clipboard")
            Image(systemName: "doc.on.doc")
        }
    
        
        if case .link(let value) = type {
            Button(action: {
                openURL(value)
            }) {
                Text("dv_open_website")
                Image(systemName: "network")
            }
        }
    }
    
    private func copyValue() {
        switch type {
        case .string(let value):
            ClipboardController.shared.copy(string: value)
        case .image(let value):
            ClipboardController.shared.copy(image: value)
        case .link(let value):
            ClipboardController.shared.copy(string: value.absoluteString)
        }
    }
}

#Preview {
    Text("Copy Me")
        .contextMenu {
            ContextMenuView(type: .string(value: "hello"))
        }
}
