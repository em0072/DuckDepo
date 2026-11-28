//
//  ExpiryReminders.swift
//  DuckDepo
//

import Combine
import Foundation
import UserNotifications

/// When to be reminded before a document expires.
enum ReminderSchedule: Int, CaseIterable, Identifiable {
    case ninetyThirtySevenDays = 0
    case thirtySevenDays = 1
    case sevenDays = 2

    static let `default` = ReminderSchedule.ninetyThirtySevenDays

    var id: Int { rawValue }

    /// Days before the expiry day to remind; 0 is the day itself.
    var daysBefore: [Int] {
        switch self {
        case .ninetyThirtySevenDays: [90, 30, 7, 0]
        case .thirtySevenDays: [30, 7, 0]
        case .sevenDays: [7, 0]
        }
    }

    var title: String {
        switch self {
        case .ninetyThirtySevenDays: String(localized: "reminder_schedule_90")
        case .thirtySevenDays: String(localized: "reminder_schedule_30")
        case .sevenDays: String(localized: "reminder_schedule_7")
        }
    }
}

/// One reminder to schedule.
struct PlannedReminder: Equatable {
    let identifier: String
    let documentName: String
    /// Days from the reminder to the expiry day; 0 on the day itself.
    let daysLeft: Int
    /// The local day and hour it goes off.
    let fireDate: DateComponents
    /// Whose document it is, so a family's passports can be told apart.
    var personName: String? = nil
}

/// Notifications before documents expire. They show only the document's name and whose it is, so nothing
/// sensitive appears on the lock screen. Rescheduled whenever documents or people change, here or through
/// iCloud.
final class ExpiryReminders {

    static let shared = ExpiryReminders()

    static let identifierPrefix = "expiry."
    /// iOS keeps at most 64 pending notifications per app; the nearest ones matter most.
    static let maximumPending = 60
    /// Reminders go off in the morning.
    static let hour = 9

    private let center: UNUserNotificationCenter
    private let defaults: DefaultsController
    private var storage: DocumentsStorage?
    private var peopleStorage: PeopleStorage?
    private var subscription: AnyCancellable?
    private var documents: [Document] = []
    private var people: [Person] = []

    init(center: UNUserNotificationCenter = .current(), defaults: DefaultsController = .shared) {
        self.center = center
        self.defaults = defaults
    }

    var isEnabled: Bool {
        defaults.areExpiryRemindersEnabled
    }

    var schedule: ReminderSchedule {
        ReminderSchedule(rawValue: defaults.reminderSchedule) ?? .default
    }

    /// Starts watching documents. Safe to call more than once; does nothing while reminders are off.
    func start() {
        guard isEnabled, storage == nil else { return }
        let storage = DocumentsStorage()
        let peopleStorage = PeopleStorage()
        self.storage = storage
        self.peopleStorage = peopleStorage
        subscription = storage.documents.combineLatest(peopleStorage.people)
            // A sync delivers documents in batches; schedule once they've settled.
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] documents, people in
                self?.documents = documents
                self?.people = people
                self?.reschedule()
            }
    }

    /// Asks for permission and turns reminders on. Returns whether they're on.
    @discardableResult
    func enable() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        await MainActor.run {
            defaults.areExpiryRemindersEnabled = granted
            if granted {
                start()
                reschedule()
            }
        }
        return granted
    }

    func disable() {
        defaults.areExpiryRemindersEnabled = false
        subscription = nil
        storage = nil
        peopleStorage = nil
        documents = []
        people = []
        Task {
            await removeScheduled()
        }
    }

    func setSchedule(_ schedule: ReminderSchedule) {
        defaults.reminderSchedule = schedule.rawValue
        reschedule()
    }

    /// Whether the system lets DuckDepo show notifications (the user can turn them off in Settings).
    func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    private func reschedule() {
        guard isEnabled else { return }
        let names = Dictionary(people.map { ($0.id, $0.name) }, uniquingKeysWith: { first, _ in first })
        let plan = Self.plan(for: documents, schedule: schedule, now: .now, personNames: names)
        Task {
            await removeScheduled()
            for reminder in plan {
                try? await center.add(Self.request(for: reminder))
            }
        }
    }

    private func removeScheduled() async {
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Plan

    /// The reminders still ahead for `documents`, nearest first, at most `limit`.
    static func plan(for documents: [Document], schedule: ReminderSchedule, now: Date,
                     calendar: Calendar = FieldDate.localCalendar, limit: Int = maximumPending,
                     personNames: [Person.ID: String] = [:]) -> [PlannedReminder] {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        var planned: [(date: Date, reminder: PlannedReminder)] = []
        for document in documents {
            guard let expiryDay = document.expiryDate else { continue }
            for days in schedule.daysBefore {
                guard let day = utc.date(byAdding: .day, value: -days, to: expiryDay) else { continue }
                var components = utc.dateComponents([.year, .month, .day], from: day)
                components.hour = hour
                guard let date = calendar.date(from: components), date > now else { continue }
                let reminder = PlannedReminder(identifier: "\(identifierPrefix)\(document.id.uuidString).\(days)",
                                               documentName: document.name, daysLeft: days, fireDate: components,
                                               personName: document.personID.flatMap { personNames[$0] })
                planned.append((date, reminder))
            }
        }
        return planned.sorted { $0.date < $1.date }.prefix(limit).map(\.reminder)
    }

    static func request(for reminder: PlannedReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        let documentName = reminder.documentName.isEmpty ? String(localized: "reminder_untitled_document") : reminder.documentName
        if let personName = reminder.personName?.trimmingCharacters(in: .whitespacesAndNewlines), !personName.isEmpty {
            content.title = String(localized: "reminder_title_person \(documentName) \(personName)")
        } else {
            content.title = documentName
        }
        content.body = reminder.daysLeft == 0
            ? String(localized: "expiry_today")
            : String(localized: "expiry_in_days \(reminder.daysLeft)")
        content.sound = .default
        content.threadIdentifier = "expiry"
        // Gregorian like the stored day, whatever calendar the user picked.
        var fireDate = reminder.fireDate
        fireDate.calendar = FieldDate.localCalendar
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireDate, repeats: false)
        return UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
    }
}
