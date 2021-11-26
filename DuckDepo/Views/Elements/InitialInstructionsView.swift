//
//  InitialInstructionsView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 25/11/2021.
//

import SwiftUI

struct InitialInstructionsView: View {
    
    enum ViewType {
        case documents
        case passwords
    }
        
    var type: ViewType
    
    var body: some View {
            VStack {
                    VStack {
                        Image(systemName: imageName)
                            .font(.largeTitle)
                            .padding()
                        Text(headline)
                            .font(.headline)
                            .padding(.bottom, 5)
                        Text(caption)
                            .font(.caption)
                    }
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing], 15)
            }
    }
    
    private var imageName: String {
        switch type {
        case .documents:
            return "lock.doc"
        case .passwords:
            return "lock.circle"
        }
    }
    
    private var headline: String {
        switch type {
        case .documents:
            return "You'll find you documents here!"
        case .passwords:
            return "You'll find you passwords here!"
        }

    }
    
    private var caption: String {
        switch type {
        case .documents:
            return "Your documents are stored encrypted on your device and your iCloud account, which means that your information is fully encrypted and available only for you."
        case .passwords:
            return "Your passwords are stored encrypted on your device and your iCloud account, which means that your information is fully encrypted and available only for you."
        }

    }


}
