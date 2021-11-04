//
//  FloatingTextView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 02/11/2021.
//

import SwiftUI

protocol FloatingTextViewDelegate {
    func copied(text: String, withTaps: Bool)
}

struct FloatingTextView: View {
    
    var title: String
    var value: String
    var delegate: FloatingTextViewDelegate?
        
    var body: some View {
            ZStack(alignment: .leading) {
                if let title = title {
                        Text(title)
                        .foregroundColor(Color(white: 0.3))
                        .offset(y: -25)
                        .scaleEffect(0.8, anchor: .leading)
                }
                Text(value)
                    .contextMenu {
                            Button(action: {
                                postCopyNotification()
                                UIPasteboard.general.string = value
                            }) {
                                Text("Copy to clipboard")
                                Image(systemName: "doc.on.doc")
                            }
                         }
                    .onTapGesture(count: 2) {
                        postCopyNotification()
                        UIPasteboard.general.string = value
                    }
                    
//                    .pillNotification(text: $copyNotificationText, show: $isShowingCopyNotification)
            }
            .padding(.top, 15)
            .padding(.bottom, 5)
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
