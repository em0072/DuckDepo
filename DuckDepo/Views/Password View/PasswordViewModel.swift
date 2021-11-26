//
//  PasswordViewModel.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import Foundation

extension PasswordView {
    class ViewModel: ObservableObject {
        
        @Published var showShareAlert = false
        @Published var showShareSheetView = false
        @Published var isEditingPassword = false
        
        var itemsToShare: [Any]?

    }
}
