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
    /// Bumped when photo text changes, so results that depend on it are worked out again.
    private var photoTextVersion = 0

    @ObservationIgnored private let database: DataBase
    @ObservationIgnored private let keychain: KeychainStoring
    @ObservationIgnored private let photoText: PhotoTextIndex
    @ObservationIgnored private let people: PeopleDirectory

    init(database: DataBase = .shared, keychain: KeychainStoring = Keychain.shared, photoText: PhotoTextIndex = .shared,
         people: PeopleDirectory = .shared) {
        self.database = database
        self.keychain = keychain
        self.photoText = photoText
        self.people = people
    }

    /// Starts fetching documents and passwords. Safe to call more than once.
    func start() {
        people.start()
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
        NotificationCenter.default.publisher(for: .photoTextIndexDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.photoTextVersion += 1
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

    /// Documents whose name, description, type, any field, person or the text in a photo matches. Empty
    /// until something is typed.
    var documentResults: [Document] {
        guard isSearching else { return [] }
        let inPhotos = photoMatches
        let people = matchingPeople
        return documents.filter { document in
            DocumentSearch.matches(document, query: query) || inPhotos[document.id] != nil
                || document.personID.map(people.contains) == true
        }
    }

    /// The people whose name matches: everything of theirs is found too.
    private var matchingPeople: Set<Person.ID> {
        Set(people.people.filter { $0.matches(query) }.map(\.id))
    }

    /// Whose a result is.
    func person(with id: Person.ID?) -> Person? {
        people.person(with: id)
    }

    /// For documents found only by the text in a photo, an excerpt of that text, to show why they're here.
    var photoMatches: [Document.ID: String] {
        _ = photoTextVersion
        guard isSearching else { return [:] }
        return photoText.matches(query).filter { id, _ in
            guard let document = document(with: id) else { return false }
            return !DocumentSearch.matches(document, query: query)
        }
    }

    /// Passwords whose name, login, website or person matches. Empty until something is typed.
    var passwordResults: [Password] {
        guard isSearching else { return [] }
        let people = matchingPeople
        return passwords.filter { $0.matches(query) || $0.personID.map(people.contains) == true }
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
