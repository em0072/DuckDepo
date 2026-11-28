//
//  PeopleStorage.swift
//  DuckDepo
//

import Combine
import CoreData

/// Publishes the people in order, and how much belongs to each.
final class PeopleStorage: NSObject {

    let people = CurrentValueSubject<[Person], Never>([])
    let counts = CurrentValueSubject<[Person.ID: PersonCounts], Never>([:])

    private let database: DataBase
    private let fetchedResultsController: NSFetchedResultsController<DDFolder>
    private var storeObserver: NSObjectProtocol?

    init(database: DataBase = .shared) {
        self.database = database
        let request = DDFolder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true),
                                   NSSortDescriptor(key: "encryptedName", ascending: true,
                                                    selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                              managedObjectContext: database.context,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        super.init()
        fetchedResultsController.delegate = self
        performFetch()
        // The store may load later than this object is created (device was locked).
        storeObserver = NotificationCenter.default.addObserver(forName: .persistentStoresDidLoad, object: nil, queue: .main) { [weak self] _ in
            self?.performFetch()
        }
    }

    /// Fetches again: for a context that doesn't merge other processes' changes, after it moved to the
    /// latest stored data.
    func refetch() {
        performFetch()
    }

    deinit {
        if let storeObserver {
            NotificationCenter.default.removeObserver(storeObserver)
        }
    }

    private func performFetch() {
        do {
            try fetchedResultsController.performFetch()
            publish()
        } catch {
            database.logger.error("Fetching people failed: \(String(describing: error), privacy: .public)")
        }
    }

    private func publish() {
        let folders = fetchedResultsController.fetchedObjects ?? []
        var seen = Set<Person.ID>()
        var people: [Person] = []
        var counts: [Person.ID: PersonCounts] = [:]
        for folder in folders {
            guard let person = folder.convert(), seen.insert(person.id).inserted else { continue }
            people.append(person)
            counts[person.id] = folder.counts
        }
        if people != self.people.value {
            self.people.value = people
        }
        if counts != self.counts.value {
            self.counts.value = counts
        }
    }
}

extension PeopleStorage: NSFetchedResultsControllerDelegate {
    // A document or password moving to or from someone changes that person's relationship, so this
    // also runs then, and the counts follow.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        publish()
    }
}

extension DataBase {

    // MARK: - People

    /// Everyone, in order.
    func allPeople() -> [Person] {
        let request = DDFolder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true)]
        return ((try? context.fetch(request)) ?? []).compactMap { $0.convert() }
    }

    /// Adds a person after the others.
    @discardableResult
    func add(_ person: Person) -> Bool {
        guard DDFolder.fetch(with: person.id, in: context) == nil else { return false }
        let request = DDFolder.fetchRequest()
        let last = ((try? context.fetch(request)) ?? []).map(\.order).max() ?? -1
        let folder = DDFolder(context: context)
        folder.identifier = person.id
        folder.personName = person.name
        folder.color = person.color.rawValue
        folder.order = last + 1
        return saveOrRollBack()
    }

    /// Saves a person's name and color. A color a newer version wrote, which this one shows as
    /// `PersonColor.fallback(for:)`, stays unless another one was picked.
    @discardableResult
    func update(_ person: Person) -> Bool {
        guard let folder = DDFolder.fetch(with: person.id, in: context) else { return false }
        if folder.personName != person.name || folder.name != nil {
            folder.personName = person.name
        }
        let isUnknownColorKept = folder.color.flatMap(PersonColor.init(rawValue:)) == nil
            && folder.color != nil && person.color == .fallback(for: person.id)
        if folder.color != person.color.rawValue && !isUnknownColorKept {
            folder.color = person.color.rawValue
        }
        return context.hasChanges ? saveOrRollBack() : true
    }

    /// Their documents and passwords stay, belonging to no one.
    @discardableResult
    func deletePerson(with id: Person.ID) -> Bool {
        guard let folder = DDFolder.fetch(with: id, in: context) else { return false }
        context.delete(folder)
        return saveOrRollBack()
    }

    /// Puts people in this order. Anyone not listed (added on another device meanwhile) goes after them.
    @discardableResult
    func reorderPeople(_ ids: [Person.ID]) -> Bool {
        let request = DDFolder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DDFolder.order, ascending: true)]
        let folders = (try? context.fetch(request)) ?? []
        let position = Dictionary(ids.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        let ordered = folders.enumerated().sorted { lhs, rhs in
            let left = lhs.element.identifier.flatMap { position[$0] } ?? ids.count + lhs.offset
            let right = rhs.element.identifier.flatMap { position[$0] } ?? ids.count + rhs.offset
            return left < right
        }
        for (index, entry) in ordered.enumerated() where entry.element.order != Int64(index) {
            entry.element.order = Int64(index)
        }
        return saveOrRollBack()
    }

    /// Gives a document to a person, or to no one (nil, or a person who's gone).
    @discardableResult
    func setPerson(_ personID: Person.ID?, forDocumentWith id: UUID) -> Bool {
        guard let stored = DDDocument.fetchDocument(with: id, viewContext: context) else { return false }
        let person = personID.flatMap { DDFolder.fetch(with: $0, in: context) }
        guard stored.folder != person else { return true }
        stored.folder = person
        return saveOrRollBack()
    }

    /// Gives a password to a person, or to no one. Only the record changes, not the keychain.
    @discardableResult
    func setPerson(_ personID: Person.ID?, forPasswordWith id: UUID) -> Bool {
        let request = DDPassword.fetchRequest()
        request.predicate = DDPassword.predicate(for: id)
        request.fetchLimit = 1
        guard let stored = try? context.fetch(request).first else { return false }
        stored.setPerson(personID)
        return context.hasChanges ? saveOrRollBack() : true
    }

    @discardableResult
    func setFavorite(_ isFavorite: Bool, forDocumentWith id: UUID) -> Bool {
        guard let stored = DDDocument.fetchDocument(with: id, viewContext: context) else { return false }
        guard stored.isFavorite != isFavorite else { return true }
        stored.isFavorite = isFavorite
        return saveOrRollBack()
    }
}
