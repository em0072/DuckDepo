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
        ZStack {
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
            .padding(16)
            NeuSectionBackground()
        }
        .padding(16)
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
            return "ii_headline_documents".localized()
        case .passwords:
            return "ii_headline_passwords".localized()
        }

    }
    
    private var caption: String {
        switch type {
        case .documents:
            return "ii_caption_documents".localized()
        case .passwords:
            return "ii_caption_passwords".localized()
        }

    }


}

struct InitialInstructionsView_Preview: PreviewProvider {
    static var previews: some View {
        InitialInstructionsView(type: .documents)
    }

}
