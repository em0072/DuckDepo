//
//  OneTimeCodeSetupSection.swift
//  DuckDepo
//

import PhotosUI
import SwiftUI
import VisionKit

/// What the code setup is showing. Owned by the editor, which presents the pickers and alerts from its
/// form: presented from a row inside the form, they closed the whole editor.
@Observable
final class OneTimeCodeSetup {
    var isEnteringKey = false
    var setupKey = ""
    var isScanning = false
    var isPickingPhoto = false
    var pickedItem: PhotosPickerItem?
}

/// Sets up an account's one-time codes from its setup QR code (camera or a screenshot) or its setup key.
/// The app's editor only: the AutoFill extension has no camera or photo picker.
struct OneTimeCodeSetupSection: View {

    @Bindable var viewModel: EditPasswordViewModel
    let setup: OneTimeCodeSetup

    var body: some View {
        Section {
            if let code = viewModel.oneTimeCode {
                OneTimeCodeRow(code: code) { value in
                    ClipboardController.shared.copy(string: value)
                }
                Button("otp_remove", role: .destructive) {
                    withAnimation {
                        viewModel.removeOneTimeCode()
                    }
                }
            } else {
                Menu {
                    if QRCodeScannerView.isAvailable {
                        Button("otp_scan_qr", systemImage: "qrcode.viewfinder") {
                            setup.isScanning = true
                        }
                    }
                    Button("otp_qr_from_photos", systemImage: "photo") {
                        setup.isPickingPhoto = true
                    }
                    Button("otp_enter_key", systemImage: "keyboard") {
                        setup.setupKey = ""
                        setup.isEnteringKey = true
                    }
                } label: {
                    Label("otp_set_up", systemImage: "plus.circle.fill")
                }
            }
        } header: {
            Text("otp_title")
        } footer: {
            Text("otp_footer")
        }
    }
}

extension View {
    /// The pickers, camera and alerts of `OneTimeCodeSetupSection`, presented from the editor's form.
    func oneTimeCodeSetupPresentations(_ setup: OneTimeCodeSetup, viewModel: EditPasswordViewModel) -> some View {
        modifier(OneTimeCodeSetupPresentations(setup: setup, viewModel: viewModel))
    }
}

private struct OneTimeCodeSetupPresentations: ViewModifier {

    @Bindable var setup: OneTimeCodeSetup
    @Bindable var viewModel: EditPasswordViewModel

    func body(content: Content) -> some View {
        content
            .alert("otp_enter_key", isPresented: $setup.isEnteringKey) {
                TextField("otp_key_placeholder", text: $setup.setupKey)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                Button("add_button") {
                    withAnimation {
                        viewModel.setUpOneTimeCode(from: setup.setupKey)
                    }
                }
                Button("cancel_button", role: .cancel) {}
            } message: {
                Text("otp_enter_key_message")
            }
            .alert("otp_invalid_title", isPresented: $viewModel.oneTimeCodeError) {
                Button("Ok", role: .cancel) {}
            } message: {
                Text("otp_invalid_body")
            }
            .photosPicker(isPresented: $setup.isPickingPhoto, selection: $setup.pickedItem, matching: .images)
            .onChange(of: setup.pickedItem) { _, item in
                guard let item else { return }
                setup.pickedItem = nil
                Task {
                    await readQRCode(from: item)
                }
            }
            .fullScreenCover(isPresented: $setup.isScanning) {
                QRCodeScannerView { payload in
                    setup.isScanning = false
                    withAnimation {
                        viewModel.setUpOneTimeCode(from: payload)
                    }
                }
            }
    }

    private func readQRCode(from item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
            viewModel.oneTimeCodeError = true
            return
        }
        let codes = await DocumentReader.qrCodes(in: image)
        // A screenshot may hold other QR codes too; take the setup one.
        withAnimation {
            viewModel.setUpOneTimeCode(from: codes.first { OneTimeCode(text: $0) != nil } ?? "")
        }
    }
}

/// The camera, looking for a setup QR code. Calls `onFound` with the first one it reads.
struct QRCodeScannerView: View {

    static var isAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    let onFound: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Scanner(onFound: onFound)
                .ignoresSafeArea()
                .overlay(alignment: .bottom) {
                    Text("otp_scan_hint")
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect()
                        .padding(.bottom, 40)
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                }
        }
    }

    private struct Scanner: UIViewControllerRepresentable {

        let onFound: (String) -> Void

        func makeUIViewController(context: Context) -> DataScannerViewController {
            let scanner = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])],
                                                    qualityLevel: .balanced, isHighlightingEnabled: true)
            scanner.delegate = context.coordinator
            return scanner
        }

        func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
            if !scanner.isScanning {
                try? scanner.startScanning()
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(onFound: onFound)
        }

        final class Coordinator: NSObject, DataScannerViewControllerDelegate {

            let onFound: (String) -> Void
            private var didFind = false

            init(onFound: @escaping (String) -> Void) {
                self.onFound = onFound
            }

            func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem],
                             allItems: [RecognizedItem]) {
                guard !didFind else { return }
                for case .barcode(let barcode) in addedItems {
                    if let payload = barcode.payloadStringValue, OneTimeCode(text: payload) != nil {
                        didFind = true
                        dataScanner.stopScanning()
                        onFound(payload)
                        return
                    }
                }
            }
        }
    }
}
