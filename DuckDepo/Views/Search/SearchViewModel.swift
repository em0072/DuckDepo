//
//  SearchViewModel.swift
//  DuckDepo
//

import Combine
import Foundation

/// Finds documents and passwords together, for the search tab.
///
/// Cheap to create: the lists load in `start()`, when the search tab first appears.
@Observable
final class SearchViewModel {

    var query = ""
    private(set) var documents: [Document] = []
    private(set) var passwords: [Password] = []

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var documentsStorage: DocumentsStorage?
    @ObservationIgnored private var passwordsStorage: PasswordsStorage?
    @ObservationIgnored private let database: DataBase
    @ObservationIgnored private let keychain: KeychainStoring

    init(database: DataBase = .shared, keychain: KeychainStoring = Keychain.shared) {
        self.database = database
        self.keychain = keychain
    }

    /// Starts fetching documents and passwords. Safe to call more than once.
    func start() {
        guard documentsStorage == nil else { return }
        let documentsStorage = DocumentsStorage(database: database)
        // Search never saves, so it doesn't need the AutoFill identity store.
        let passwordsStorage = PasswordsStorage(database: database, keychain: keychain, identityStore: nil)
        self.documentsStorage = documentsStorage
        self.passwordsStorage = passwordsStorage
        documentsStorage.documents
            .sink { [weak self] documents in
                self?.documents = documents
            }
            .store(in: &cancellables)
        passwordsStorage.startObserving()
        passwordsStorage.passwords
            .sink { [weak self] passwords in
                self?.passwords = passwords
            }
            .store(in: &cancellables)
    }

    var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Documents whose name, description, type or any field matches. Empty until something is typed.
    var documentResults: [Document] {
        guard isSearching else { return [] }
        return documents.filter { DocumentSearch.matches($0, query: query) }
    }

    /// Passwords whose name, login or website matches. Empty until something is typed.
    var passwordResults: [Password] {
        guard isSearching else { return [] }
        return passwords.filter { $0.matches(query) }
    }

    func document(with id: Document.ID) -> Document? {
        documents.first { $0.id == id }
    }

    func password(with id: Password.ID) -> Password? {
        passwords.first { $0.id == id }
    }

    /// Whether the item a result led to still exists (it may be deleted here or on another device).
    func exists(_ destination: SearchDestination) -> Bool {
        switch destination {
        case .document(let id): document(with: id) != nil
        case .password(let id): password(with: id) != nil
        }
    }
}

/// A search result's detail screen.
enum SearchDestination: Hashable {
    case document(Document.ID)
    case password(Password.ID)
}
