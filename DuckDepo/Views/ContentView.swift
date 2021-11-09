//
//  ContentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/10/2021.
//

import SwiftUI
import CoreData
import LocalAuthentication

struct ContentView: View {
    
    @State var isShowingCopyNotification: Bool = false
    @State var copyNotificationText: String = "Copied"
    @State private var isUnlocked = false

   
    var body: some View {
            TabView {
                DepoListView().tabItem {
                    Label("Depo", systemImage: "archivebox")
                }.tag(1)
                SettingsView().tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(2)
            }
            .onReceive(NotificationCenter.default.publisher(for: .floatingTextFieldCopyNotification)) { _ in
                isShowingCopyNotification = true
            }
            .pillNotification(text: $copyNotificationText, show: $isShowingCopyNotification)
        
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        // check whether biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // it's possible, so go ahead and use it
            let reason = "We need to unlock your data."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                // authentication has now completed
                DispatchQueue.main.async {
                    if success {
                        self.isUnlocked = true
                        // authenticated successfully
                    } else {
                        // there was a problem
                    }
                }
            }
        } else {
            // no biometrics
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
