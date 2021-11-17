//
//  BlurView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 16/11/2021.
//

import SwiftUI

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
