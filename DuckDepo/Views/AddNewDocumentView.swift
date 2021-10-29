//
//  AddNewDocumentView.swift
//  DuckDepo
//
//  Created by Evgeny Mitko on 27/10/2021.
//

import SwiftUI
import ImageViewer



struct AddNewDocumentView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var documentName: String = ""
    @State var selectedFolder: Int = 0
    @State var duplicateAlertIsShown: Bool = false
    @State var showingPhotoChooser = false
    @State var showingImagePicker = false
    @State var showingCameraView = false
    @State var imagePickerInputImage: UIImage?
    @State var imageViewerImage: Image?
    @State var cameraPickerInputImages: [UIImage]?
    @State var showingImageViewer = false
    @State var showingAddNewSectionView = false
    @State var showingAddNewInfoDuplicateWarning = false
    
    @Binding var isPresented: Bool
    var addAction: (() -> ())?
    @State var images: [UIImage] = []
    @State var sections: [DDSection] = []
    
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true)], predicate: nil, animation: .default)
    private var folders: FetchedResults<DDFolder>
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                VStack() {
                    Form {
                        NameAndFolderView(documentName: $documentName, selectedFolder: $selectedFolder, folders: folders)

                        AddPhotosView(images: $images, showingPhotoChooser: $showingPhotoChooser, showingImagePicker: $showingImagePicker, showingImageViewer: $showingImageViewer, imageViewerImage: $imageViewerImage, showingCameraView: $showingCameraView, imagePickerInputImage: $imagePickerInputImage, cameraPickerInputImages: $cameraPickerInputImages, onImagePickerAction: loadImagePickerImage, onCameraPickerAction: loadCameraPickerImage)

                        
                        SectionsView(sections: $sections, showingAddNewSectionView: $showingAddNewSectionView, deleteAction: deleteSection, addFieldAction: addField)

                        AddSectionButton(showingAddNewSectionView: $showingAddNewSectionView, duplicateCheck: checkSectionIfDuplicat, addNewSectionAction: addNewSection)
                        
                        AddDocumentButton(documentName: $documentName, duplicateAlertIsShown: $duplicateAlertIsShown, selectedFolder: $selectedFolder, folders: folders, action: saveDocument)
                            .foregroundColor(documentName.isEmpty ? Color(white: 0.5) : Color.black)
                            .listRowBackground(documentName.isEmpty ? Color(white: 0.9) : Color.duckYellow)

                    }
                    .sheet(isPresented: $showingAddNewSectionView) {
                        AddNewView(isPresented: $showingAddNewSectionView, folderDoesExsistAlertShown: $showingAddNewInfoDuplicateWarning, type: .section, addAction: addNewSection)
                    }
                }
            }
            .navigationTitle("New Document")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button {
                self.isPresented = false
            } label: {
                Text("Dismiss")
            })
        }
        .overlay(ImageViewer(image: self.$imageViewerImage, viewerShown: self.$showingImageViewer))
    }
    
    private func deleteSection(_ section: DDSection) {
        if let index = sections.firstIndex(of: section) {
            _ = withAnimation {
                sections.remove(at: index)
            }
        }
    }
    
    private func addField(_ field: Field, to section: DDSection) {
        withAnimation {
            let newField = DDField(context: viewContext)
            newField.title = field.title
            newField.section = section
            
            section.addToFields(newField)
        }
    }
    
    private func addNewSection(_ name: String) {
        guard !checkSectionIfDuplicat(with: name) else {
            self.showingAddNewInfoDuplicateWarning = true
            return
        }
        withAnimation {
            let newSection = DDSection(context: viewContext)
            newSection.name = name
            newSection.order = Int32(sections.count)
            sections.append(newSection)
            self.showingAddNewSectionView = false
        }
    }
    
    private func checkSectionIfDuplicat(with name: String) -> Bool {
        for section in sections {
            guard let sectionName = section.name else { continue }
            guard sectionName != name else {
                return true
            }
        }
        return false
    }
    
    private func saveDocument() {
        let folderToSave = folders[selectedFolder]
        let document = DDDocument(context: viewContext)
        document.name = documentName
        document.addToPhotos(images)
        document.folder = folderToSave
        
        folderToSave.addToDocumnets(document)
        
        do {
            try viewContext.save()
            self.isPresented = false
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func loadImagePickerImage() {
        guard let inputImage = imagePickerInputImage else { return }
        images.append(inputImage)
    }
    
    func loadCameraPickerImage() {
        guard let inputImages = cameraPickerInputImages, !inputImages.isEmpty else { return }
        inputImages.forEach { image in
            images.append(image)
        }
    }

    
}

struct AddNewDocumentVirew_Previews: PreviewProvider {
    
    static var previews: some View {
        AddNewDocumentView(isPresented: .constant(true))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

struct AddDocumentButton: View {
    
    @Binding var documentName: String
    @Binding var duplicateAlertIsShown: Bool
    @Binding var selectedFolder: Int
    var folders: FetchedResults<DDFolder>
    var action: () -> ()
    
    
    var body: some View {
        Section {
            HStack {
                Spacer()
                Button {
                    if folders[selectedFolder].getDocuments().map({ $0.name }).contains(documentName) {
                        self.duplicateAlertIsShown = true
                    } else {
                        action()
                    }
                } label: {
                    Text("Add new document")
                }
                
                .alert("Duplicate", isPresented: $duplicateAlertIsShown, actions: {
                    Button("Ok") {
                        self.duplicateAlertIsShown = false
                    }
                }, message: {
                    Text("The document with this name already exsists. Please choose a different name.")
                })
                .disabled(documentName.isEmpty)
                Spacer()
            }
        }
    }
}

struct NameAndFolderView: View {
    
    @Binding var documentName: String
    @Binding var selectedFolder: Int
    var folders: FetchedResults<DDFolder>
    
    var body: some View {
        Section("Main Info") {
            TextField("Add New Document", text: $documentName, prompt: Text("Document Name"))
            Picker(selection: $selectedFolder, label: Text("Category")) {
                ForEach(0..<folders.count, id: \.self) { index in
                    Text(folders[index].name ?? "").tag(index)
                }
            }
        }
    }
}

struct AddPhotosView: View {
    
    @Binding var images: [UIImage]
    @Binding var showingPhotoChooser: Bool
    @Binding var showingImagePicker: Bool
    @Binding var showingImageViewer: Bool
    @Binding var imageViewerImage: Image?
    @Binding var showingCameraView: Bool
    @Binding var imagePickerInputImage: UIImage?
    @Binding var cameraPickerInputImages: [UIImage]?
    var onImagePickerAction: (()->())?
    var onCameraPickerAction: (()->())?

    var body: some View {
        Section("Photos") {
            ScrollView(.horizontal) {
                ScrollViewReader { scrollProxy in
                    LazyHStack {
                        ForEach(images, id: \.self) { image in
                            PhotoCell(image: image)
                                .onTapGesture {
                                    self.imageViewerImage = Image(uiImage: image)
                                    self.showingImageViewer = true
                                }
                        }
                        
                        AddCell()
                            .onTapGesture {
                                showingPhotoChooser = true
                            }
                            .actionSheet(isPresented: $showingPhotoChooser) {
                                ActionSheet(title: Text("Do you want to scan a document or choose it from library?"), buttons: [
                                    .default(Text("Camera")) {
                                        self.showingCameraView = true
                                    },
                                    .default(Text("Photo Library")) {
                                        self.showingImagePicker = true
                                    },
                                    .cancel()
                                ])
                            }
                            .sheet(isPresented: $showingImagePicker, onDismiss: onImagePickerAction) {
                                ImagePicker(image: self.$imagePickerInputImage)
                            }
                            .sheet(isPresented: $showingCameraView, onDismiss: onCameraPickerAction) {
                                CameraPicker(imageArray: $cameraPickerInputImages)
                            }
                    }
                    .frame(height: 100)
                }
            }
            .padding([.leading, .trailing], -12)
            
        }
    }
}

struct AddSectionButton: View {
    
    
    @Binding var showingAddNewSectionView: Bool
    var duplicateCheck: ((String) -> (Bool))?
    var addNewSectionAction: (String) -> ()
    
    var body: some View {
            Menu {
                Button(role: .destructive) {
                    self.showingAddNewSectionView = true
                } label: {
                    Text("Custom")
                }
                ForEach(SectionOptions.allOptions, id: \.self) { section in
                    let dupCheck = duplicateCheck?(section) ?? false
                    if !dupCheck {
                        Button {
                            addNewSectionAction(section)
                        } label: {
                            Text(section)
                        }
                    }
                }
                

            } label: {
                Label("Add Section", systemImage: "plus.circle")
            }
            .frame(maxWidth: .infinity)
        
    }
}

struct SectionsView: View {
    
    @Binding var sections: [DDSection]
    @Binding var showingAddNewSectionView: Bool
    var deleteAction: ((DDSection)->())?
    var addFieldAction: ((Field, DDSection))->()
    @State var fieldValue: String = ""
    
    var body: some View {
        ForEach(sections) { section in
            Section {
                ForEach(section.getAllFields()) { field in
                    if let fieldTitle = field.title {
                    TextField(fieldTitle, text: $fieldValue)
                    }
                }
                Menu {
                    Button(role: .destructive) {
                        self.showingAddNewSectionView = true
                    } label: {
                        Text("Custom")
                    }
                    ForEach(FieldOptions.allOptions, id: \.title) { field in
//                        let dupCheck = duplicateCheck?(section) ?? false
//                        if !dupCheck {
                            Button {
                                addFieldAction((field, section))
                            } label: {
                                Text(field.title)
                            }
//                        }
                    }
                } label: {
                    Label("Add Field", systemImage: "plus.circle")
                }
                .frame(maxWidth: .infinity)
            } header: {
                HStack {
                    Text(section.name ?? "")
                    Spacer()
                    Button {
                        deleteAction?(section)
                    } label: {
                        Image(systemName: "multiply.circle.fill")
                            .foregroundColor(Color.red)
                    }
                }
            }
        }
    }
}
