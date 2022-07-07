//
//  LinearGradient Extension.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 01/07/2022.
//

import SwiftUI

extension LinearGradient {
    init(_ neuColors: Color...) {
        self.init(gradient: Gradient(colors: neuColors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

