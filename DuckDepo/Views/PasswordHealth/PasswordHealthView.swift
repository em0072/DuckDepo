//
//  PasswordHealthView.swift
//  DuckDepo
//

import SwiftUI

/// Passwords to fix, each under its most serious issue: leaked, reused, easy to guess. Hidden ones are
/// listed apart. Shown from Settings, and from Passwords when the user turns that on.
struct PasswordHealthView: View {

    /// What the Passwords list selects to show this screen in its detail column.
    static let selectionID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AE")!

    @Bindable private var monitor = PasswordHealthMonitor.shared
    @State private var isShowingHidden = false
    /// The password opened from a row. By ID rather than by the row's link: rows move between sections as
    /// the report changes (a warning hidden, a leak found), and the screen they opened must stay.
    @State private var openedID: Password.ID?

    var body: some View {
        List {
            Section {
                PasswordHealthSummary(report: monitor.report, isLoaded: monitor.isLoaded, leakCheck: monitor.leakCheck)
            }
            itemSection(monitor.report.leaked, title: "ph_section_leaked", footer: "ph_leaked_footer")
            itemSection(monitor.report.reused, title: "ph_section_reused", footer: "ph_reused_footer")
            itemSection(monitor.report.weak, title: "ph_section_weak", footer: "ph_weak_footer")
            leakCheckSection
            if !monitor.report.hiddenItems.isEmpty {
                Section {
                    DisclosureGroup(isExpanded: $isShowingHidden.animation()) {
                        ForEach(monitor.report.hiddenItems) { item in
                            row(for: item)
                        }
                    } label: {
                        Text("ph_section_hidden \(monitor.report.hiddenItems.count)")
                            .contentTransition(.numericText())
                    }
                }
            }
        }
        .navigationTitle("ph_title")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $openedID) { id in
            if let password = monitor.password(with: id) {
                PasswordView(password: password)
            }
        }
        .onAppear(perform: monitor.start)
        .refreshable {
            monitor.refresh(immediately: true)
            await monitor.waitForRefresh()
        }
    }

    @ViewBuilder
    private func itemSection(_ items: [PasswordHealth.Item], title: LocalizedStringKey, footer: LocalizedStringKey) -> some View {
        if !items.isEmpty {
            Section {
                ForEach(items) { item in
                    row(for: item)
                }
            } header: {
                Text(title)
            } footer: {
                Text(footer)
            }
        }
    }

    private func row(for item: PasswordHealth.Item) -> some View {
        Button {
            openedID = item.id
        } label: {
            HStack {
                PasswordHealthRow(item: item)
                Spacer(minLength: 8)
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .tint(.primary)
        .accessibilityAddTraits(.isLink)
    }

    private var leakCheckSection: some View {
        Section {
            Toggle(isOn: $monitor.checksLeakedPasswords.animation()) {
                Label("ph_check_leaks", systemImage: "network.badge.shield.half.filled")
                    .labelStyle(.tile(.red))
            }
            switch monitor.leakCheck {
            case .checking:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("ph_leaks_checking")
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            case .failed:
                VStack(alignment: .leading, spacing: 6) {
                    Label("ph_leaks_failed", systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                    Button("ph_try_again") {
                        monitor.refresh(immediately: true)
                    }
                }
                .transition(.opacity)
            case .off, .checked:
                EmptyView()
            }
        } footer: {
            Text("ph_leaks_footer")
        }
    }
}

/// The count to fix, or that all is well, and what was checked. While the passwords are still being read,
/// or leaks couldn't be checked, it doesn't claim there are no issues.
private struct PasswordHealthSummary: View {

    let report: PasswordHealth
    let isLoaded: Bool
    let leakCheck: PasswordHealthMonitor.LeakCheck

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 40))
                .foregroundStyle(color)
                .contentTransition(.symbolEffect(.replace))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                title
                    .font(.headline)
                    .contentTransition(.numericText())
                detail
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        if !isLoaded {
            return "shield"
        }
        if report.toFixCount > 0 {
            return "exclamationmark.shield.fill"
        }
        return leakCheck == .checking || leakCheck == .failed ? "shield.fill" : "checkmark.shield.fill"
    }

    private var color: Color {
        if !isLoaded {
            return .secondary
        }
        if report.toFixCount > 0 {
            return .orange
        }
        return leakCheck == .checking || leakCheck == .failed ? .secondary : .green
    }

    private var title: Text {
        if !isLoaded {
            return Text("ph_summary_loading")
        }
        return report.toFixCount > 0 ? Text("ph_summary_to_fix \(report.toFixCount)") : Text("ph_summary_ok")
    }

    private var detail: Text {
        switch leakCheck {
        case .checking: Text("ph_leaks_checking")
        case .failed: Text("ph_summary_leaks_failed")
        case .checked: Text("ph_summary_checks_leaks")
        case .off: Text("ph_summary_checks")
        }
    }
}

/// A password and what's wrong with it.
struct PasswordHealthRow: View {

    let item: PasswordHealth.Item

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 36

    var body: some View {
        HStack(spacing: 12) {
            Monogram(text: item.password.name)
                .frame(width: iconSize, height: iconSize)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.password.name)
                if !item.password.login.isEmpty {
                    Text(item.password.login)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(item.issues.map(\.title).joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(item.isLeaked ? Color.red : Color.orange)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

/// The row that opens Password Health: in Passwords, and in Settings. Neutral until the passwords are read.
struct PasswordHealthLabel: View {

    let toFixCount: Int
    let isLoaded: Bool

    var body: some View {
        LabeledContent {
            if isLoaded {
                Group {
                    if toFixCount > 0 {
                        Text("ph_row_to_fix \(toFixCount)")
                            .foregroundStyle(.orange)
                    } else {
                        Text("ph_row_ok")
                    }
                }
                .contentTransition(.numericText())
            }
        } label: {
            Label("ph_title", systemImage: symbol)
                .labelStyle(.tile(tint))
                .contentTransition(.symbolEffect(.replace))
        }
    }

    private var symbol: String {
        guard isLoaded else { return "shield.fill" }
        return toFixCount > 0 ? "exclamationmark.shield.fill" : "checkmark.shield.fill"
    }

    private var tint: Color {
        guard isLoaded else { return .gray }
        return toFixCount > 0 ? .orange : .green
    }
}

/// On a password's own screen: what's wrong with it, how to fix it, and hiding the warning.
struct PasswordHealthWarningSection: View {

    let password: Password

    @Environment(\.openURL) private var openURL
    private var monitor = PasswordHealthMonitor.shared

    init(password: Password) {
        self.password = password
    }

    var body: some View {
        // A hidden warning is only a small note at the bottom (`PasswordHealthHiddenNote`).
        if !monitor.report.isHidden(password.id), let item = monitor.report.item(for: password.id) {
            Section {
                ForEach(item.issues, id: \.self) { issue in
                    Label {
                        Text(issue.title)
                    } icon: {
                        Image(systemName: issue == .leaked ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(issue == .leaked ? Color.red : Color.orange)
                    }
                }
                if let url = changePasswordURL {
                    Button("ph_change_password") {
                        openURL(url)
                    }
                }
                Button("ph_hide_warning") {
                    monitor.setWarningsHidden(true, for: password.id)
                }
            } footer: {
                Text("ph_detail_footer")
            }
            .transition(.opacity)
        }
    }

    /// Sites that support it send `/.well-known/change-password` to their change-password page. The same
    /// origin as the website (scheme, host, port), and not for addresses like a router's.
    private var changePasswordURL: URL? {
        guard let website = password.websiteURL,
              var components = URLComponents(url: website, resolvingAgainstBaseURL: false),
              let host = components.host, host.contains("."),
              !host.contains(":"), !host.allSatisfy({ $0.isNumber || $0 == "." }) else { return nil }
        components.scheme = components.scheme?.lowercased() == "http" ? "http" : "https"
        components.user = nil
        components.password = nil
        components.path = "/.well-known/change-password"
        components.query = nil
        components.fragment = nil
        return components.url
    }
}

/// At the bottom of a password's screen when the user hid its warning: small, since they chose not to see
/// it, with a way to show it again.
struct PasswordHealthHiddenNote: View {

    let password: Password

    private var monitor = PasswordHealthMonitor.shared

    init(password: Password) {
        self.password = password
    }

    var body: some View {
        if monitor.report.isHidden(password.id) {
            Section {
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Label("ph_warning_hidden", systemImage: "eye.slash")
                    Button("ph_show_warning") {
                        monitor.setWarningsHidden(false, for: password.id)
                    }
                    .fontWeight(.semibold)
                }
                .font(.footnote)
            }
            .transition(.opacity)
        }
    }
}

extension PasswordHealth.Issue {

    var title: String {
        switch self {
        case .leaked: String(localized: "ph_issue_leaked")
        case .reused(let accounts): String(localized: "ph_issue_reused \(accounts)")
        case .weak(.short): String(localized: "ph_issue_short")
        case .weak(.common): String(localized: "ph_issue_common")
        case .weak(.predictable): String(localized: "ph_issue_predictable")
        }
    }
}

#Preview {
    NavigationStack {
        PasswordHealthView()
    }
}
