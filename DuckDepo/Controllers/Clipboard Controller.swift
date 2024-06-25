//
//  Clipboard Controller.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/06/2024.
//

import Foundation
import UIKit

class ClipboardController {
    
    static let shared = ClipboardController()
    
    private init() {}

    func copy(string: String) {
        UIPasteboard.general.string = string
        postCopyNotification()
    }

    func copy(image: UIImage) {
        UIPasteboard.general.image = image
        postCopyNotification()
    }

    private func postCopyNotification() {
        NotificationCenter.default.post(name: .floatingTextFieldCopyNotification, object: nil, userInfo: nil)
    }

}
