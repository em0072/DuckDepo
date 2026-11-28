//
//  PeopleView.swift
//  DuckDepo
//

import SwiftUI

/// Settings › People: add, rename, recolor, reorder and delete people.
struct PeopleView: View {

    private var directory = PeopleDirectory.shared
    @State private var editing: EditPersonView.Mode?
    @State private var personToDelete: Person?
    /// Owned here so it can end when there's nobody left to reorder (the Edit button goes then).
    @State private var editMode = EditMode.inactive

    var body: some View {
        List {
            if !directory.people.isEmpty {
                Section {
                    ForEach(directory.people) { person in
                        Button {
                            editing = .existing(person)
                        } label: {
                            PersonListRow(person: person, counts: directory.counts[person.id] ?? PersonCounts())
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing) {
                            Button {
                                personToDelete = person
                            } label: {
                                Label("delete", systemImage: "trash")
                            }
                            .tint(.red)
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
                    .onMove(perform: directory.move)
                } footer: {
                    Text("people_footer")
                }
            }
        }
        .overlay {
            if directory.people.isEmpty {
                ContentUnavailableView {
                    Label("people_empty_title", systemImage: "person.2")
                } description: {
                    Text("people_empty_body")
                } actions: {
                    Button("person_add") {
                        editing = .new
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(.onDuckYellow)
                }
                .transition(.opacity)
            }
        }
        .navigationTitle("people_title")
        .toolbar {
            if directory.people.count > 1 {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editing = .new
                } label: {
                    Label("person_add", systemImage: "plus")
                }
            }
        }
        .onAppear(perform: directory.start)
        .sheet(item: $editing) { mode in
            EditPersonView(mode: mode)
        }
        .alert(Text("person_delete_title \(personToDelete?.name ?? "")"), isPresented: isConfirmingDelete, presenting: personToDelete) { person in
            Button("delete", role: .destructive) {
                directory.delete(person)
            }
        } message: { _ in
            Text("person_delete_body")
        }
        .onChange(of: directory.people.count) { _, count in
            if count <= 1 && editMode.isEditing {
                withAnimation {
                    editMode = .inactive
                }
            }
        }
        // Outside the toolbar too, so its Edit button uses this one.
        .environment(\.editMode, $editMode)
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

/// A person with how much belongs to them.
private struct PersonListRow: View {

    let person: Person
    let counts: PersonCounts

    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 40

    var body: some View {
        HStack(spacing: 12) {
            PersonAvatar(person: person)
                .frame(width: avatarSize, height: avatarSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .foregroundStyle(.primary)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        "\(String(localized: "people_documents_count \(counts.documents)")) · \(String(localized: "people_passwords_count \(counts.passwords)"))"
    }
}

/// The People row in Settings.
struct PeopleSection: View {

    private var directory = PeopleDirectory.shared

    var body: some View {
        Section {
            NavigationLink {
                PeopleView()
            } label: {
                LabeledContent {
                    Text(directory.people.count, format: .number)
                        .contentTransition(.numericText())
                } label: {
                    Label("people_title", systemImage: "person.2.fill")
                        .labelStyle(.tile(.blue))
                }
            }
        } footer: {
            Text("people_section_footer")
        }
        .onAppear(perform: directory.start)
    }
}

#Preview {
    NavigationStack {
        PeopleView()
    }
}
