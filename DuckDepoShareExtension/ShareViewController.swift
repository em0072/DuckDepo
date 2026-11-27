//
//  ShareViewController.swift
//  DuckDepoShareExtension
//

import SwiftUI
import UIKit

/// Hosts the share sheet's screen. Images and PDFs shared from other apps become a document's photos.
final class ShareViewController: UIViewController {

    private var model: ShareViewModel?
    /// Over the documents list while the app it was shared from isn't active. A UIKit view, so it's in
    /// place before the app-switcher snapshot; SwiftUI would draw it a moment later.
    private let cover = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
        let model = ShareViewModel(providers: providers) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        } cancel: { [weak self] in
            self?.extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
        }
        self.model = model
        let host = UIHostingController(rootView: ShareView(model: model))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        addCover()
        observeHostApp()
    }

    private func addCover() {
        cover.backgroundColor = .systemBackground
        cover.frame = view.bounds
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cover.isHidden = true
        let symbol = UIImageView(image: UIImage(systemName: "lock.fill"))
        symbol.tintColor = .secondaryLabel
        symbol.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44)
        symbol.translatesAutoresizingMaskIntoConstraints = false
        cover.addSubview(symbol)
        NSLayoutConstraint.activate([
            symbol.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: cover.centerYAnchor),
        ])
        view.addSubview(cover)
    }

    private func observeHostApp() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(hostWillResignActive), name: .NSExtensionHostWillResignActive, object: nil)
        center.addObserver(self, selector: #selector(hostDidEnterBackground), name: .NSExtensionHostDidEnterBackground, object: nil)
        center.addObserver(self, selector: #selector(hostDidBecomeActive), name: .NSExtensionHostDidBecomeActive, object: nil)
    }

    @objc private func hostWillResignActive() {
        if model?.shouldCoverContent == true {
            cover.isHidden = false
        }
    }

    @objc private func hostDidEnterBackground() {
        model?.hostDidEnterBackground()
    }

    @objc private func hostDidBecomeActive() {
        model?.hostDidBecomeActive()
        cover.isHidden = true
    }
}
