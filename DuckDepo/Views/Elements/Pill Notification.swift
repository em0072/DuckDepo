//
//  Pill Notification.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 04/11/2021.
//

import SwiftUI

struct Pill_Notification: ViewModifier {
    
    @Binding var text: String
    @Binding var show: Bool

    func body(content: Content) -> some View {
            ZStack {
                content
                withAnimation {
                VStack(alignment: .center) {
                    Text(text)
                        .bold()
                        .foregroundColor(Color(uiColor: .label))
                        .padding([.top, .bottom], 7)
                        .padding([.leading, .trailing], 25)
                        .background(Color(uiColor: .systemGray5))
                        .clipShape(Capsule())
                    Spacer()
                }
                .onTapGesture {
                    withAnimation {
                        self.show = false
                    }
                }
                .padding()
                .offset(y: show ? -10 : -50)
                .opacity(show ? 1 : 0)
                .animation(.default, value: show)
                .onChange(of: show, perform: { newValue in
                    if newValue == true {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                self.show = false
                            }
                        }
                    }
                })
            }
            }
        }

}

extension View {
    func pillNotification(text: Binding<String>, show: Binding<Bool>) -> some View {
        self.modifier(Pill_Notification(text: text, show: show))
    }
}


struct Pill_Notification_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button {
                
            } label: {
                Text("Click Me")
            }
        }
    }
}
