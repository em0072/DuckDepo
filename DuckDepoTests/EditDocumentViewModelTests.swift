//
//  EditDocumentViewModelTests.swift
//  DuckDepoTests
//

import Testing
@testable import DuckDepo

@MainActor
struct EditDocumentViewModelTests {

    private let database = TestStack.makeDatabase()

    private func makeViewModel() -> EditDocumentViewModel {
        let viewModel = EditDocumentViewModel(type: .new, database: database)
        viewModel.document.name = "Licence"
        viewModel.addNewSection("Document Info")
        let sectionID = viewModel.document.sections[0].id
        for title in ["A", "B", "C"] {
            viewModel.addField(named: title, toSection: sectionID)
        }
        for index in 0..<3 {
            viewModel.document.sections[0].fields[index].value = "value-\(index)"
        }
        return viewModel
    }

    /// Fields used to be identified by position, so deleting one could show or save the wrong values.
    @Test func deletingAFieldKeepsOtherValuesInPlace() {
        let viewModel = makeViewModel()
        let section = viewModel.document.sections[0]

        viewModel.deleteField(section.fields[1].id, inSection: section.id)

        let fields = viewModel.document.sections[0].fields
        #expect(fields.map(\.title) == ["A", "C"])
        #expect(fields.map(\.value) == ["value-0", "value-2"])
    }

    @Test func detectsUnsavedChanges() {
        let viewModel = EditDocumentViewModel(type: .new, database: database)
        #expect(!viewModel.hasChanges)

        viewModel.document.name = "Licence"

        #expect(viewModel.hasChanges)
    }

    @Test func blankNameCannotBeSaved() {
        let viewModel = EditDocumentViewModel(type: .new, database: database)
        viewModel.document.name = "   "
        #expect(!viewModel.canSave)
    }

    @Test func editingAnExistingDocumentStartsFromStoredPhotos() throws {
        let photo = DocumentPhoto.sample()
        let document = Document(name: "Passport", photos: [photo])
        #expect(database.save(document))
        // The list hands over a copy without photos.
        var listItem = document
        listItem.photos = []

        let viewModel = EditDocumentViewModel(type: .existing(listItem), database: database)

        #expect(viewModel.document.photos.map(\.data) == [photo.data])
        #expect(!viewModel.hasChanges)
    }

    @Test func sectionEqualityComparesContents() {
        var section = DocSection(name: "Info", fields: [Field(title: "Number", value: "1")])
        let original = section
        section.fields[0].value = "2"
        #expect(section != original)
        #expect(Set([section, original]).count == 2)
    }
}
