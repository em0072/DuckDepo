//
//  LockScreenView.swift
//  DuckDepo
//

import Combine
import SwiftUI
import UIKit

/// Opaque cover shown above everything (including sheets) while the app is locked or inactive.
struct LockScreenView: View {
    @ObservedObject var controller: BiometricController

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                // The app icon in miniature: same duck and background as the icon and launch screen.
                Image(.launchDuck)
                    .resizable()
                    .scaledToFit()
                    .padding(18)
                    .frame(width: 120, height: 120)
                    .background(Color(.launchBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .accessibilityHidden(true)
                if controller.isLocked {
                    Text("lock_title")
                        .font(.title2.bold())
                    Button {
                        controller.unlock()
                    } label: {
                        Label(unlockTitle, systemImage: unlockSymbol)
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.duckYellow)
                    .foregroundStyle(.black)
                    .controlSize(.large)
                    .disabled(controller.isAuthenticating)
                }
            }
            .padding()
        }
    }

    private var unlockTitle: LocalizedStringKey {
        switch controller.biometricType() {
        case .face: return "lock_unlock_faceid"
        case .touch: return "lock_unlock_touchid"
        case .opticId: return "lock_unlock_opticid"
        case .none: return "lock_unlock_passcode"
        }
    }

    private var unlockSymbol: String {
        switch controller.biometricType() {
        case .face: return "faceid"
        case .touch: return "touchid"
        case .opticId: return "opticid"
        case .none: return "lock.open"
        }
    }
}

/// Shows `LockScreenView` in its own window above the app's window, so it also covers
/// sheets and full-screen editors that SwiftUI presents above the root view.
@MainActor
final class LockWindowPresenter {

    static let shared = LockWindowPresenter()

    private var windows: [ObjectIdentifier: UIWindow] = [:]
    private var cancellable: AnyCancellable?

    func attach(to scene: UIWindowScene, controller: BiometricController = .shared) {
        let key = ObjectIdentifier(scene)
        guard windows[key] == nil else { return }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        let host = UIHostingController(rootView: LockScreenView(controller: controller))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = !controller.isContentHidden
        windows[key] = window

        if cancellable == nil {
            // `@Published` emits synchronously, so the cover is in place before the app-switcher snapshot.
            cancellable = Publishers.CombineLatest(controller.$isLocked, controller.$isObscured)
                .map { $0 || $1 }
                .removeDuplicates()
                .sink { [weak self] isContentHidden in
                    self?.update(hidden: !isContentHidden)
                }
        }
        update(hidden: !controller.isContentHidden)
    }

    private func update(hidden: Bool) {
        windows = windows.filter { $0.value.windowScene != nil }
        for window in windows.values where window.isHidden != hidden {
            window.isHidden = hidden
            if hidden {
                // Give keyboard focus back to the app's own window.
                window.windowScene?.windows.first { $0 !== window && !$0.isHidden }?.makeKey()
            } else {
                window.makeKeyAndVisible()
            }
        }
    }
}

/// Reports the `UIWindowScene` that hosts a SwiftUI view.
struct WindowSceneReader: UIViewRepresentable {
    let onScene: (UIWindowScene) -> Void

    func makeUIView(context: Context) -> SceneView {
        SceneView(onScene: onScene)
    }

    func updateUIView(_ uiView: SceneView, context: Context) {}

    final class SceneView: UIView {
        let onScene: (UIWindowScene) -> Void

        init(onScene: @escaping (UIWindowScene) -> Void) {
            self.onScene = onScene
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let scene = window?.windowScene {
                onScene(scene)
            }
        }
    }
}

#Preview {
    LockScreenView(controller: .shared)
}
