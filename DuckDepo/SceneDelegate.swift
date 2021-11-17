////
////  AppDelegate.swift
////  DuckDepo
////
////  Created by Evgeny Mitko on 08/11/2021.
////
//
//import SwiftUI
//import CloudKit
//import LocalAuthentication
//import Combine
//
//extension SceneDelegate {
//    static let didAuthenticate = Notification.Name(rawValue: "didAuthenticate")
//}
//
//class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//    
//    var window: UIWindow?
//    private var authenticateObserver: AnyCancellable?
//
//    @State private var isUnlocked = false
//
//    
//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        let contentView = ContentView(blured: .constant(false))
//            .environment(\.managedObjectContext, PersistenceController.shared.context)
//
////        let contentView = TestView()
//        if let windowScene = scene as? UIWindowScene {
//            self.authenticateObserver = NotificationCenter.default.publisher(for: SceneDelegate.didAuthenticate)
//                .sink { _ in
//                    self.window?.rootViewController?.dismiss(animated: true)
//                }
//
//            let window = UIWindow(windowScene: windowScene)
//            window.rootViewController = UIHostingController(rootView: contentView)
//            self.window = window
//            window.makeKeyAndVisible()
//        }
//    }
//
//    
//      func sceneWillEnterForeground(_ scene: UIScene) {
//          print("sceneWillEnterForeground")
////          authenticate()
//      }
//    
//    func sceneDidEnterBackground(_ scene: UIScene) {
//        print("sceneDidEnterBackground")
//    }
//
//      func sceneDidBecomeActive(_ scene: UIScene) {
////          NotificationCenter.default.post(name: SceneDelegate.didAuthenticate, object: nil)
////          if !isUnlocked {
////              authenticate()
////          }
//          print("sceneDidBecomeActive")
//      }
//
//      func sceneWillResignActive(_ scene: UIScene) {
//          let controller = UIHostingController(rootView: TestView())
//          controller.modalPresentationStyle = .fullScreen
//          self.window?.rootViewController?.present(controller, animated: true)
//          print("sceneWillResignActive")
//      }
//    
////    func authenticate() {
////        let context = LAContext()
////        var error: NSError?
////
////        // check whether biometric authentication is possible
////        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
////            // it's possible, so go ahead and use it
////            let reason = "We need to unlock your data."
////
////            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
////                // authentication has now completed
////                DispatchQueue.main.async {
////                    if success {
//////                        self.isUnlocked = true
////                        NotificationCenter.default.post(name: SceneDelegate.didAuthenticate, object: nil)
////                        // authenticated successfully
////                    } else {
////                        // there was a problem
////                    }
////                }
////            }
////        } else {
////            // no biometrics
////        }
////    }
//
//    
//    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
//        let sharedStore = PersistenceController.shared.sharedPersistentStore
//        let container = PersistenceController.shared.container
//        container.acceptShareInvitations(from: [cloudKitShareMetadata], into: sharedStore) { shareMetas, error in
//            if let shareAcceptenceError = error {
//                print("Could not accept share - \(shareAcceptenceError)")
//            } else {
//                print("Accepted share with metadata - \(String(describing: shareMetas))")
//            }
//        }
//    }
//}
