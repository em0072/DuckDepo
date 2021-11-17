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
    var delegate: FloatingTextViewDelegate?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let title = title {
                    Text(title)
                    .foregroundColor(Color(white: 0.3))
                    .scaleEffect(0.8, anchor: .leading)
                    .padding(.top, 5)
            }
            HStack {
            Text(value)
                .padding(.bottom, 5)
                .contextMenu {
                        Button(action: {
                            postCopyNotification()
                            UIPasteboard.general.string = value
                        }) {
                            Text("Copy to clipboard")
                            Image(systemName: "doc.on.doc")
                        }
                     }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                postCopyNotification()
                UIPasteboard.general.string = value
            }
        }
//        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    


    
    private func postCopyNotification() {
        NotificationCenter.default.post(name: .floatingTextFieldCopyNotification, object: nil, userInfo: nil)
    }
}

struct FloatingTextView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FloatingTextView(title: "Title", value: "Value")
        }
    }
}
