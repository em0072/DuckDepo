//
//  DomainMatcherTests.swift
//  DuckDepoTests
//

import Testing
@testable import DuckDepo

struct DomainMatcherTests {

    @Test(arguments: [
        ("https://www.Google.com/path?q=1", "google.com"),
        ("google.com", "google.com"),
        ("  accounts.google.com  ", "accounts.google.com"),
        ("http://example.org:8080", "example.org"),
    ])
    func extractsHost(input: String, expected: String) {
        #expect(DomainMatcher.host(from: input) == expected)
    }

    @Test(arguments: ["", "   "])
    func emptyInputHasNoHost(input: String) {
        #expect(DomainMatcher.host(from: input) == nil)
    }

    @Test func matchesSameDomainAndSubdomains() {
        #expect(DomainMatcher.matches(website: "google.com", serviceIdentifier: "https://accounts.google.com/signin"))
        #expect(DomainMatcher.matches(website: "accounts.google.com", serviceIdentifier: "google.com"))
        #expect(DomainMatcher.matches(website: "https://www.apple.com", serviceIdentifier: "apple.com"))
    }

    @Test func doesNotMatchOtherDomains() {
        #expect(!DomainMatcher.matches(website: "google.com", serviceIdentifier: "notgoogle.com"))
        #expect(!DomainMatcher.matches(website: "apple.com", serviceIdentifier: "https://example.com"))
    }

    /// A password without a website used to be recommended for every site.
    @Test func emptyWebsiteNeverMatches() {
        #expect(!DomainMatcher.matches(website: "", serviceIdentifier: "https://bank.example"))
    }
}
