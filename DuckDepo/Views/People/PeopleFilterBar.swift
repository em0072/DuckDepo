//
//  PeopleFilterBar.swift
//  DuckDepo
//

import SwiftUI

/// Everyone, then each person, to show only what belongs to them; and a button to add someone.
/// Goes at the top of a list, on the page rather than on a card.
struct PeopleFilterBar: View {

    @Binding var selection: PersonFilter
    let people: [Person]

    @State private var editing: EditPersonView.Mode?
    @State private var personToDelete: Person?
    @ScaledMetric(relativeTo: .subheadline) private var avatarSize: CGFloat = 22

    /// A person who's gone (deleted here or on another device) leaves everything shown.
    private var selectedID: Person.ID? {
        selection.personID.flatMap { id in people.contains { $0.id == id } ? id : nil }
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                // Flat: `onDuckYellow` is made for this color exactly.
                chip(isSelected: selectedID == nil, fill: AnyShapeStyle(Color.duckYellow), foreground: .onDuckYellow) {
                    Text("people_all")
                } action: {
                    select(.everyone)
                }
                ForEach(people) { person in
                    chip(isSelected: selectedID == person.id, fill: AnyShapeStyle(person.color.fill), foreground: .white) {
                        HStack(spacing: 6) {
                            PersonAvatar(person: person)
                                .frame(width: avatarSize, height: avatarSize)
                                // On a chip of the same color.
                                .overlay {
                                    if selectedID == person.id {
                                        Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1.5)
                                    }
                                }
                            Text(person.name)
                        }
                    } action: {
                        select(selectedID == person.id ? .everyone : .person(person.id))
                    }
                    .contextMenu {
                        Button("person_edit", systemImage: "pencil") {
                            editing = .existing(person)
                        }
                        Button("person_delete", systemImage: "trash", role: .destructive) {
                            personToDelete = person
                        }
                    }
                }
                Button {
                    editing = .new
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(minWidth: avatarSize, minHeight: avatarSize)
                        .padding(7)
                        .background(Color(.tertiarySystemFill), in: .circle)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("person_add"))
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .sheet(item: $editing) { mode in
            EditPersonView(mode: mode) { person in
                if case .new = mode {
                    select(.person(person.id))
                }
            }
        }
        .alert(Text("person_delete_title \(personToDelete?.name ?? "")"), isPresented: isConfirmingDelete, presenting: personToDelete) { person in
            Button("delete", role: .destructive) {
                PeopleDirectory.shared.delete(person)
            }
        } message: { _ in
            Text("person_delete_body")
        }
    }

    private func select(_ filter: PersonFilter) {
        withAnimation(.snappy) {
            selection = filter
        }
    }

    private func chip<Label: View>(isSelected: Bool, fill: AnyShapeStyle, foreground: Color,
                                   @ViewBuilder label: () -> Label, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label()
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .frame(minHeight: avatarSize + 14)
                .foregroundStyle(isSelected ? foreground : .primary)
                .background {
                    Capsule()
                        .fill(isSelected ? fill : AnyShapeStyle(Color(.tertiarySystemFill)))
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding {
            personToDelete != nil
        } set: { isPresented in
            if !isPresented {
                personToDelete = nil
            }
        }
    }
}

extension View {

    /// For the filter bar as a list's first row: edge to edge, with no card behind it.
    func peopleFilterRow() -> some View {
        listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

#Preview {
    @Previewable @State var selection = PersonFilter.everyone
    List {
        Section {
            PeopleFilterBar(selection: $selection,
                            people: [Person(name: "Anna", color: .pink), Person(name: "Max Lee", color: .teal)])
                .peopleFilterRow()
        }
        Section {
            Text("Passport")
        }
    }
}
