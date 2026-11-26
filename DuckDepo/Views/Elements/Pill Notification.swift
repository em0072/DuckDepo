//
//  Pill Notification.swift
//  DuckDepo
//

import SwiftUI

/// A short confirmation at the top of the screen, like "Copied".
private struct PillNotification: ViewModifier {

    let text: String
    @Binding var show: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if show {
                    Label(text, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: .capsule)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture {
                            show = false
                        }
                        .task {
                            AccessibilityNotification.Announcement(text).post()
                            try? await Task.sleep(for: .seconds(2))
                            show = false
                        }
                }
            }
            .animation(.snappy, value: show)
    }
}

extension View {
    func pillNotification(text: String, show: Binding<Bool>) -> some View {
        modifier(PillNotification(text: text, show: show))
    }
}

#Preview {
    @Previewable @State var show = true
    Button("Copy") { show = true }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pillNotification(text: "Copied", show: $show)
}
