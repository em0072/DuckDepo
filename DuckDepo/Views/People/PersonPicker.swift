//
//  PersonPicker.swift
//  DuckDepo
//

import SwiftUI

/// "Belongs To": whose a document or password is, with a way to add someone new.
struct PersonPicker: View {

    @Binding var personID: Person.ID?
    /// While the choice is a scan's suggestion.
    var isSuggested = false

    private var directory = PeopleDirectory.shared
    @State private var isAddingPerson = false
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 22

    init(personID: Binding<Person.ID?>, isSuggested: Bool = false) {
        _personID = personID
        self.isSuggested = isSuggested
    }

    var body: some View {
        LabeledContent {
            HStack(spacing: 6) {
                if isSuggested {
                    ScanMarker(confidence: .suggested)
                        .transition(.opacity)
                }
                Menu {
                    PersonChoices(selection: $personID.animation(), people: directory.people)
                    Divider()
                    Button("person_new", systemImage: "person.badge.plus") {
                        isAddingPerson = true
                    }
                } label: {
                    // Like a menu picker's value: in the accent color.
                    HStack(spacing: 6) {
                        if let person = directory.person(with: personID) {
                            PersonAvatar(person: person)
                                .frame(width: avatarSize, height: avatarSize)
                            Text(person.name)
                                .lineLimit(1)
                        } else {
                            Text("person_no_one")
                        }
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.footnote.weight(.medium))
                    }
                }
                .accessibilityLabel(Text("person_belongs_to"))
                .accessibilityValue(Text(directory.person(with: personID)?.name ?? String(localized: "person_no_one")))
            }
        } label: {
            // The menu says it, with the value: VoiceOver would read it twice.
            Text("person_belongs_to")
                .accessibilityHidden(true)
        }
        .onAppear(perform: directory.start)
        .sheet(isPresented: $isAddingPerson) {
            EditPersonView(mode: .new) { person in
                withAnimation {
                    personID = person.id
                }
            }
        }
    }
}

/// No one, then everyone, to pick from: in a menu, or a row's context menu.
struct PersonChoices: View {

    @Binding var selection: Person.ID?
    let people: [Person]

    var body: some View {
        Picker(selection: $selection) {
            Text("person_no_one")
                .tag(Person.ID?.none)
            ForEach(people) { person in
                Text(person.name)
                    .tag(Person.ID?.some(person.id))
            }
        } label: {
            Label("person_belongs_to", systemImage: "person.crop.circle")
        }
    }
}

extension PersonChoices {

    /// For a row's context menu: a "Belongs To" submenu, when there's anyone to choose.
    @ViewBuilder
    static func menu(personID: Person.ID?, people: [Person], onChange: @escaping (Person.ID?) -> Void) -> some View {
        if !people.isEmpty {
            PersonChoices(selection: Binding { personID } set: { onChange($0) }, people: people)
                .pickerStyle(.menu)
        }
    }
}
