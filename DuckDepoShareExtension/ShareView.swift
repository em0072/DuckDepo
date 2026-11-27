//
//  ShareView.swift
//  DuckDepoShareExtension
//

import SwiftUI

/// What was shared, and where it goes: a new document or one the user has.
struct ShareView: View {

    @Bindable var model: ShareViewModel

    @Environment(\.displayScale) private var displayScale

    private static let pageHeight: CGFloat = 140

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("share_title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close, action: model.cancel)
                    }
                }
                .navigationDestination(isPresented: $model.isPicking) {
                    DocumentPicker(model: model)
                }
        }
        .task {
            await model.start()
        }
        .sheet(isPresented: isEditing, onDismiss: model.editorDismissed) {
            if let editor = model.editor {
                EditDocumentView(viewModel: editor)
            }
        }
        .alert("share_failed_title", isPresented: isShowingFailure) {
            Button("Ok") {}
        } message: {
            Text(model.failure ?? "")
        }
        // Outside the sheet and the alert, so they're tinted too.
        .tint(.duckYellow)
    }

    @ViewBuilder
    private var content: some View {
        switch model.stage {
        case .loading:
            ProgressView("share_loading")
        case .reading:
            ProgressView("share_reading")
        case .appNotOpened:
            ContentUnavailableView("share_open_app_title", systemImage: "archivebox",
                                   description: Text("share_open_app_body"))
        case .nothingToSave:
            ContentUnavailableView("share_nothing_title", systemImage: "photo.badge.exclamationmark",
                                   description: Text("share_nothing_body"))
        case .choosing:
            choices
        }
    }

    private var choices: some View {
        List {
            Section {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(model.photos) { photo in
                            Image(uiImage: PhotoThumbnails.image(for: photo, filling: CGSize(width: 0, height: Self.pageHeight),
                                                                 scale: displayScale))
                                .resizable()
                                .scaledToFit()
                                .frame(height: Self.pageHeight)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(.separator, lineWidth: 0.5)
                                }
                        }
                    }
                    .padding(.vertical, 12)
                }
                .scrollIndicators(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            } footer: {
                if model.isTruncated {
                    Text("share_pages_truncated \(ShareViewModel.maximumPages)")
                }
            }
            Section {
                Button {
                    Task {
                        await model.newDocument()
                    }
                } label: {
                    choice("share_new_document", detail: "share_new_document_detail", systemImage: "doc.badge.plus", color: .orange)
                }
                Button {
                    Task {
                        await model.chooseExisting()
                    }
                } label: {
                    choice("share_add_to_existing", detail: "share_add_to_existing_detail",
                           systemImage: "rectangle.stack.badge.plus", color: .blue)
                }
            }
            .foregroundStyle(.primary)
        }
    }

    private func choice(_ title: LocalizedStringKey, detail: LocalizedStringKey, systemImage: String, color: Color) -> some View {
        HStack(spacing: 14) {
            IconTile(color: color) {
                Image(systemName: systemImage)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var isEditing: Binding<Bool> {
        Binding { model.editor != nil } set: { if !$0 { model.editor = nil } }
    }

    private var isShowingFailure: Binding<Bool> {
        Binding { model.failure != nil } set: { if !$0 { model.failure = nil } }
    }
}

/// The user's documents, to add the pages to one.
private struct DocumentPicker: View {

    @Bindable var model: ShareViewModel

    var body: some View {
        List(model.filteredDocuments) { document in
            Button {
                model.add(to: document)
            } label: {
                DocumentRow(document: document)
            }
            .foregroundStyle(.primary)
        }
        .disabled(model.isSaving)
        .overlay {
            if model.isSaving {
                ProgressView()
            } else if model.filteredDocuments.isEmpty {
                ContentUnavailableView.search(text: model.query)
            }
        }
        .searchable(text: $model.query)
        .navigationTitle("share_choose_document")
        .navigationBarTitleDisplayMode(.inline)
    }
}
