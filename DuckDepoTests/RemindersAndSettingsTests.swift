//
//  RemindersAndSettingsTests.swift
//  DuckDepoTests
//

import Foundation
import Testing
@testable import DuckDepo

struct ExpiryReminderPlanTests {

    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        return calendar
    }()

    private func now(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func document(_ name: String, expiring storedValue: String) -> Document {
        var field = FieldKey.expiryDate.makeField()
        field.value = storedValue
        return Document(name: name, sections: [DocSection(name: "Info", fields: [field])])
    }

    @Test func remindsOnEachDayBeforeAndOnTheDayAtNine() {
        let passport = document("Passport", expiring: "2027-06-30")
        let plan = ExpiryReminders.plan(for: [passport], schedule: .ninetyThirtySevenDays,
                                        now: now(2027, 1, 1), calendar: calendar)
        #expect(plan.map(\.daysLeft) == [90, 30, 7, 0])
        #expect(plan.map { [$0.fireDate.month!, $0.fireDate.day!] } == [[4, 1], [5, 31], [6, 23], [6, 30]])
        #expect(plan.allSatisfy { $0.fireDate.hour == ExpiryReminders.hour && $0.documentName == "Passport" })
        #expect(plan.allSatisfy { $0.identifier.hasPrefix(ExpiryReminders.identifierPrefix) })
    }

    @Test func skipsRemindersAlreadyPast() {
        let licence = document("Licence", expiring: "2027-06-30")
        // 10 days to go: only the 7-day reminder and the day itself are ahead.
        let plan = ExpiryReminders.plan(for: [licence], schedule: .ninetyThirtySevenDays,
                                        now: now(2027, 6, 20), calendar: calendar)
        #expect(plan.map(\.daysLeft) == [7, 0])
        // After nine on the day itself, nothing is left.
        let late = ExpiryReminders.plan(for: [licence], schedule: .sevenDays,
                                        now: now(2027, 6, 30, hour: 10), calendar: calendar)
        #expect(late.isEmpty)
    }

    @Test func keepsTheNearestRemindersUpToTheLimit() {
        let documents = [document("Later", expiring: "2028-01-15"), document("Sooner", expiring: "2027-03-01"),
                         Document(name: "No expiry")]
        let plan = ExpiryReminders.plan(for: documents, schedule: .sevenDays, now: now(2027, 1, 1),
                                        calendar: calendar, limit: 3)
        #expect(plan.map(\.documentName) == ["Sooner", "Sooner", "Later"])
        #expect(Set(plan.map(\.identifier)).count == 3)
    }

    @Test func theNotificationShowsOnlyTheName() {
        let reminder = PlannedReminder(identifier: "expiry.x.30", documentName: "Passport", daysLeft: 30,
                                       fireDate: DateComponents(year: 2027, month: 5, day: 31, hour: 9))
        let request = ExpiryReminders.request(for: reminder)
        #expect(request.content.title == "Passport")
        #expect(request.content.body == String(localized: "expiry_in_days \(30)"))
        #expect(request.identifier == "expiry.x.30")
    }
}

struct ClipboardLifetimeTests {

    @Test func defaultsToOneMinute() {
        let defaults = UserDefaults(suiteName: "ClipboardLifetimeTests")!
        defaults.removePersistentDomain(forName: "ClipboardLifetimeTests")
        let controller = DefaultsController(defaults: defaults, legacyDefaults: nil)
        #expect(controller.clipboardLifetime == 60)
        controller.clipboardLifetime = ClipboardLifetime.fiveMinutes.rawValue
        #expect(controller.clipboardLifetime == 300)
    }
}

@MainActor
struct SettingsCountTests {

    private let database = TestStack.makeDatabase()

    @Test func countsDocumentsPasswordsAndThoseToRenew() {
        func document(_ name: String, expiring storedValue: String?) -> Document {
            guard let storedValue else { return Document(name: name) }
            var field = FieldKey.expiryDate.makeField()
            field.value = storedValue
            return Document(name: name, sections: [DocSection(name: "Info", fields: [field])])
        }
        let today = FieldDate.storedValue(fromLocalDate: .now)!
        let soon = FieldDate.storedValue(fromLocalDate: Calendar.current.date(byAdding: .day, value: 20, to: .now)!)!
        for doc in [document("Expired", expiring: "2001-01-01"), document("Today", expiring: today),
                    document("Soon", expiring: soon), document("Valid", expiring: "2099-01-01"),
                    document("No expiry", expiring: nil)] {
            #expect(database.save(doc))
        }
        let viewModel = SettingsViewModel(database: database)
        viewModel.start()
        #expect(viewModel.documentCount == 5)
        #expect(viewModel.renewalCount == 3)
        #expect(viewModel.passwordCount == 0)
    }
}
