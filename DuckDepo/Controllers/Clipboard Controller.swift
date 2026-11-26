//
//  Clipboard Controller.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/06/2024.
//

import UIKit
import UniformTypeIdentifiers

/// Copies values so they stay on this device and disappear from the clipboard after a short time.
final class ClipboardController {

    static let shared = ClipboardController()

    /// How long copied text stays on the clipboard.
    static let textLifetime: TimeInterval = 60
    /// How long a copied photo stays on the clipboard.
    static let imageLifetime: TimeInterval = 120

    private let pasteboard: UIPasteboard

    init(pasteboard: UIPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func copy(string: String) {
        pasteboard.setItems(
            [[UTType.utf8PlainText.identifier: string]],
            options: Self.options(lifetime: Self.textLifetime)
        )
        postCopyNotification()
    }

    func copy(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        pasteboard.setItems(
            [[UTType.jpeg.identifier: data]],
            options: Self.options(lifetime: Self.imageLifetime)
        )
        postCopyNotification()
    }

    /// `localOnly` keeps sensitive values off Universal Clipboard.
    static func options(lifetime: TimeInterval) -> [UIPasteboard.OptionsKey: Any] {
        [.localOnly: true, .expirationDate: Date().addingTimeInterval(lifetime)]
    }

    private func postCopyNotification() {
        NotificationCenter.default.post(name: .floatingTextFieldCopyNotification, object: nil, userInfo: nil)
    }
}
