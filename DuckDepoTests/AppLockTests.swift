//
//  AppLockTests.swift
//  DuckDepoTests
//

import Foundation
import Testing
@testable import DuckDepo

@MainActor
final class AppLockTests {

    private var now = Date(timeIntervalSinceReferenceDate: 1_000_000)
    private var authenticationResult = true
    private var authenticationCount = 0

    private func makeLock(enabled: Bool = true, delay: BiometricController.BiometricDelay = .none) -> BiometricController {
        let defaults = DefaultsController(defaults: TestStack.makeDefaults(), legacyDefaults: nil)
        defaults.isBiometryEnabled = enabled
        defaults.biometricDelay = delay.rawValue
        return BiometricController(
            defaults: defaults,
            now: { [unowned self] in self.now },
            canAuthenticate: { true },
            authenticator: { [unowned self] _, completion in
                self.authenticationCount += 1
                completion(self.authenticationResult)
            }
        )
    }

    @Test func startsLockedAndUnlocksAfterAuthentication() {
        let lock = makeLock()
        #expect(lock.isLocked)

        lock.sceneDidBecomeActive()

        #expect(!lock.isLocked)
        #expect(authenticationCount == 1)
    }

    @Test func failedAuthenticationStaysLockedAndCanRetry() {
        authenticationResult = false
        let lock = makeLock()

        lock.sceneDidBecomeActive()
        #expect(lock.isLocked)
        #expect(!lock.isAuthenticating)

        authenticationResult = true
        lock.unlock()
        #expect(!lock.isLocked)
    }

    @Test func disabledLockNeverLocks() {
        let lock = makeLock(enabled: false)
        lock.sceneDidEnterBackground()
        lock.sceneDidBecomeActive()
        #expect(!lock.isContentHidden)
        #expect(authenticationCount == 0)
    }

    @Test func immediatelyLocksOnBackground() {
        let lock = makeLock()
        lock.sceneDidBecomeActive()

        lock.sceneDidEnterBackground()

        #expect(lock.isLocked)
        #expect(lock.isObscured)
    }

    /// Pulling down Control Center makes the app inactive but must not ask for Face ID again.
    @Test func inactiveOnlyObscures() {
        let lock = makeLock()
        lock.sceneDidBecomeActive()

        lock.sceneWillResignActive()
        #expect(lock.isObscured)
        #expect(!lock.isLocked)

        lock.sceneDidBecomeActive()
        #expect(!lock.isContentHidden)
        #expect(authenticationCount == 1)
    }

    @Test func delayCountsFromBackground() {
        let lock = makeLock(delay: .fiveSeconds)
        lock.sceneDidBecomeActive()

        lock.sceneDidEnterBackground()
        now += 4
        lock.sceneDidBecomeActive()
        #expect(!lock.isLocked)

        lock.sceneDidEnterBackground()
        now += 6
        lock.sceneDidBecomeActive()
        #expect(authenticationCount == 2)
    }

    @Test func migratesSettingsFromStandardDefaults() {
        let legacy = TestStack.makeDefaults()
        legacy.set(true, forKey: "biometryEnabled")
        legacy.set(3, forKey: "biometricDelay")
        legacy.set(true, forKey: "isUnlocked")
        let shared = TestStack.makeDefaults()

        let defaults = DefaultsController(defaults: shared, legacyDefaults: legacy)

        #expect(defaults.isBiometryEnabled)
        #expect(defaults.biometricDelay == 3)
        #expect(legacy.object(forKey: "isUnlocked") == nil)

        defaults.biometricDelay = 1
        _ = DefaultsController(defaults: shared, legacyDefaults: legacy)
        #expect(defaults.biometricDelay == 1)
    }
}
