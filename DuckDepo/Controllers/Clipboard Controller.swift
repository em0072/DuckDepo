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

    private let pasteboard: UIPasteboard
    private let lifetime: () -> TimeInterval

    /// `lifetime` is how long a copy stays on the clipboard; the user picks it in Settings.
    init(pasteboard: UIPasteboard = .general,
         lifetime: @escaping () -> TimeInterval = { TimeInterval(DefaultsController.shared.clipboardLifetime) }) {
        self.pasteboard = pasteboard
        self.lifetime = lifetime
    }

    func copy(string: String) {
        pasteboard.setItems(
            [[UTType.utf8PlainText.identifier: string]],
            options: Self.options(lifetime: lifetime())
        )
        postCopyNotification()
    }

    func copy(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        pasteboard.setItems(
            [[UTType.jpeg.identifier: data]],
            options: Self.options(lifetime: lifetime())
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

/// How long a copied value stays on the clipboard.
enum ClipboardLifetime: Int, CaseIterable, Identifiable {
    case thirtySeconds = 30
    case oneMinute = 60
    case twoMinutes = 120
    case fiveMinutes = 300

    static let `default` = ClipboardLifetime.oneMinute

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .thirtySeconds: String(localized: "clipboard_after_30_seconds")
        case .oneMinute: String(localized: "clipboard_after_1_minute")
        case .twoMinutes: String(localized: "clipboard_after_2_minutes")
        case .fiveMinutes: String(localized: "clipboard_after_5_minutes")
        }
    }
}
