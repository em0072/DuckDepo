////
////  FloatingPickerView.swift
////  DuckDepo
////
////  Created by Evgeny Mitko on 16/06/2022.
////
//
//
//import SwiftUI
//
//protocol StringRepresentable {
//    var rawValue: String { get }
//}
//
//protocol Pickable: StringRepresentable, Identifiable, Codable, Equatable, CaseIterable where AllCases: RandomAccessCollection {
//    }
//
//extension Pickable where Self: RawRepresentable, Self.RawValue == String {
//    var value: String {
//        return self.rawValue
//    }
//}
//
//
//struct FloatingPickerView<Data: Pickable>: View {
//    
//    var title: String
////    var placeholder: String
//
//    @Binding var selected: Data
//    
//    var emptyState: Data? = nil
//
//    var body: some View {
//        ZStack(alignment: .leading) {
////            if isEmpty {
//                    Text(title)
//                    .foregroundColor(isEmpty ? .gray : Color(white: 0.3))
//                    .offset(x: isEmpty ? 10 : 0 , y: isEmpty ? -5 : -25)
//                    .scaleEffect(isEmpty ? 1 : 0.8, anchor: .leading)
////            }
//            pickerView
//        }
//        .padding(.top, 15)
//        .padding(.bottom, 5)
//        .animation(.easeInOut(duration: 0.2), value: selected)
////        }
//    }
//    
//    private var pickerView: some View {
//        ZStack {
//                Menu {
//                    ForEach(Data.allCases) { item in
//                        if item != emptyState {
//                            Button {
//                                selected = item
//                            } label: {
//                                HStack {
//                                    Text(item == emptyState ? "" : item.rawValue.capitalized)
//                                    if item == selected {
//                                        Image(systemName: "checkmark")
//                                    }
//                                    
//                                }
//                            }
//                        }
//                    }
//                } label: {
//                    Text("") //isEmpty ? title : selected.rawValue.capitalized)
////                        .font(.TLBody.weight(.medium))
//                        .foregroundColor(color)
//                    Spacer()
////                    SelectorIconView()
////                        .iconText(color)
//                }
//            
////            }
//        }
//        .padding()
//        .accentColor(.black)
//    }
//    
//    private var color: Color {
//        isEmpty ? .gray : .black
//    }
//    
//    private var isEmpty: Bool {
//        if let emptyState = emptyState {
//            return selected == emptyState
//        } else {
//            return false
//        }
//    }
//
//    
//}
//
//struct TLPickerView_Previews: PreviewProvider {
//    static var previews: some View {
//        FloatingPickerView(title: "Category", selected: .constant(DocumentType.work), emptyState: DocumentType.none)
////        TLPickerView(title: "Title", placeholder: "Select Option", selected: .constant(DocumentType.other), emptyState: DocumentType.other)
//    }
//}
