# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DuckDepo is an iOS password manager and document storage app built with SwiftUI, Core Data, and CloudKit. The project includes both a main application and an AutoFill extension for system-wide password access.

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open DuckDepo.xcodeproj

# Build from command line
xcodebuild -project DuckDepo.xcodeproj -scheme DuckDepo -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build

# Run unit tests (Swift Testing, target DuckDepoTests)
xcodebuild -project DuckDepo.xcodeproj -scheme DuckDepo -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test

# Clean build folder
xcodebuild -project DuckDepo.xcodeproj -scheme DuckDepo clean
```

### Project Structure
- **Main App**: `DuckDepo/` - SwiftUI app with MVVM architecture
- **AutoFill Extension**: `DuckDepoAutoFillExtension/` - iOS AutoFill credential provider
- **Shared Core Data**: Both targets open the same store in the App Group container (`group.evgenymitko.duckdepo`)
- **Minimum iOS**: 26.0 for all targets

## Architecture

### MVVM Pattern
- ViewModels are `@Observable` classes held in `@State`. A view model built in a view's initializer is rebuilt on every parent redraw, so its init must be cheap: heavy work (fetches, keychain reads, full documents) goes in `start()`/`load()`, called once from `onAppear`
- Each major view has a corresponding ViewModel (e.g., `DepoListViewModel`, `EditDocumentViewModel`)
- Models are Core Data entities with custom classes

### Core Data Stack
- **PersistenceController**: Singleton managing NSPersistentCloudKitContainer. Roles: `.app` (syncs with CloudKit), `.autoFill` (same file, no CloudKit), `.inMemory` (tests)
- **CloudKit Integration**: Only the app mirrors to `iCloud.DuckDepo`. AutoFill writes reach the app through persistent history (`mergeChangesFromOtherProcesses`)
- **Store location**: moved from the app sandbox to the App Group on first launch of 2.7 (`moveLegacyStoreIfNeeded`); the extension waits for `DefaultsController.isSharedStoreReady`
- **Model changes**: add a new model version (additive only: CloudKit can't rename or remove), run a Debug build once with `-InitializeCloudKitSchema`, then deploy the schema to Production in the CloudKit Console
- **Entities**: `DDDocument`, `DDPhoto`, `DDPassword`, `DDSection`, `DDField`, `DDFolder` (current model: `DuckDepo 3`)
- **Keys**: predefined sections and fields store a stable `key` (`SectionKey`/`FieldKey` in `FieldCatalog.swift`) and display their name from it, so names follow the current language. Date fields store `yyyy-MM-dd` (`FieldDate`); documents keep `createdAt`/`updatedAt`/`expiresAt`
- **Photos**: one `DDPhoto` record per photo (ID derived from the image bytes), plus the old `photoData` blob kept in sync for devices still on 2.6. `LegacyDataMigration` converts `photoData` changed by 2.6 and removes duplicate records the same way on every device
- **File Protection**: Complete file protection enabled for security

### Scanning (`DuckDepo/Scanning/`)
- Everything runs on the device. `DocumentScanner.draft(from:)`: Vision text recognition (`DocumentReader`, language correction off), then exact parsers (`MRZParser` for passport/ID zones with check digits, `DrivingLicenceParser` for the numbered fields of EU and Russian licences, VINs), then `ModelExtractor` (on-device `SystemLanguageModel` only, never the Private Cloud Compute model) for fields still empty
- The model doesn't support Russian (skipped for mostly-Cyrillic text) and makes values up: `ScanReading.add(_:text:)` keeps only values printed in the recognized text. It's prewarmed when a scan starts and given 6 s
- Search inside photos: `PhotoIndexer` reads every document photo's text in the background (on launch and when documents change) into `PhotoTextIndex`, a local file only on this device (complete file protection, excluded from backups, nothing syncs; keys are document ID + content-derived photo ID). `SearchViewModel` adds photo matches with an excerpt
- The result opens in the editor (`EditDocumentViewModel.Mode.scanned`) with a banner and per-field `ScanMarker`s (verified / read / suggested) that disappear once a value is edited; nothing is saved until confirmed

### Security Architecture
- **BiometricController**: Manages Face ID/Touch ID authentication
- **Keychain Integration**: Password values live in the iCloud-synchronized keychain group (`Keychain` wraps KeychainSwift behind `KeychainStoring`); Core Data holds only name/login/website. One-time code setups (`otpauth://` links, `OneTimeCode`, RFC 6238) are stored next to them under `<id>.otp` and offered to AutoFill as `ASOneTimeCodeCredentialIdentity` (extension capability `ProvidesOneTimeCodes`)
- **Passkeys** (`DuckDepo/Passkeys/`): DuckDepo is a WebAuthn authenticator in AutoFill (extension capability `ProvidesPasskeys`). `PasskeyAuthenticator` builds the P-256/ES256 COSE key, "none" attestation (zero AAGUID) and assertions with a small canonical `CBOR` encoder; flags say backup eligible and backed up. Each `Passkey` (credential ID, site, user, user handle, private key) is JSON in the synced keychain under `passkey.<base64url credential ID>` with its own keychain service `DuckDepo.passkey` (`PasskeyStorage`), so listing reads no passwords and nothing touches Core Data or the CloudKit schema. Lists hold `PasskeySummary` (no key); the key is read only to sign. A new passkey replaces the account's earlier one (same site and user handle). Changes made in this process post `PasskeyStorage.didChange`. Creating or using one asks `UserVerification` (Face ID or passcode) first, unless the user just unlocked the AutoFill list; the extension never signs without interaction. When a site asks for a passkey, the AutoFill list shows its passkeys above the passwords. The app lists passkeys in their own section of Passwords (`PasskeyRow`, `PasskeyView`, delete only; deleting removes only that suggestion from `ASCredentialIdentityStore`)
- **App Locking**: `BiometricController` + `LockWindowPresenter` (a separate window above all sheets). Lock state is never persisted; the app always starts locked when the lock is on
- **LegacyDataMigration**: idempotent repair of v1 data, runs on every activation

### Navigation Structure
- Tab-based main interface (`Tab` API): Depo (Documents), Passwords, Settings, plus a search tab (`Tab(role: .search)` with `.tabViewSearchActivation(.searchTabSelection)`, the separate button at the end of the tab bar) that searches documents and passwords together (`SearchView`)
- Each list is a selection-based `NavigationSplitView` (sidebar list, detail column on iPad, push on iPhone), with swipe actions and context menus
- Editors are sheets with close/confirm toolbar buttons (`Button(role: .close)` / `.confirm`) and a discard confirmation
- Photos open in `PhotoViewer` (full screen, zoom transition from the tapped photo); on the document they show in `PhotoGallery` (a row at each photo's own shape, or one photo at full width)
- Settings: an overview card (counts, with passkeys counted as passwords; documents to renew), rows with `ColorfulIconLabelStyle` tiles (`.labelStyle(.tile(color))`), Security (lock, clipboard), Reminders, Sync and AutoFill (status from `ASCredentialIdentityStore`), About (Privacy page, version)

## Key Components

### Data Layer
- `DataBase.swift`: Generic Core Data operations wrapper
- `DocumentsStorage.swift` / `PasswordsStorage.swift`: Entity-specific storage classes
- Migration system: `ManualMigrationV1toV2` handles data structure updates

### Controllers
- `BiometricController`: Authentication state management
- `DefaultsController`: UserDefaults wrapper with proper key management
- `ClipboardController`: Copies are local-only (no Universal Clipboard) and expire after the user's `ClipboardLifetime` (default 1 min, shared with the extension through `DefaultsController`)
- `ExpiryReminders`: local notifications 90/30/7 days before and on the expiry day (`ReminderSchedule`), 9:00 local, only the document's name shown; watches documents and reschedules on any change (nearest 60 pending)

### UI Components
- Standard iOS 26 look (insetGrouped lists, forms, glass toolbars); `duckYellow` is the accent (deep amber #9E6C00 in light mode for contrast, bright #FBC531 in dark, plus Increase Contrast variants); labels on a yellow fill use `onDuckYellow`
- Reusable components in `Views/Elements/`: `FieldValueRow` (value with copy and show/hide buttons), `LabeledTextField` (editor field with its title above), `PhotoViewer`
- List rows: `DocumentRow` (thumbnail or type tile, `ExpiryBadge`), `PasswordRow` (monogram)
- Expiry: `ExpiryStatus` (expired / expires within 90 days / valid) from `Document.expiryDate`; document matching in `DocumentSearch`

## Dependencies

### Swift Package Manager
- **KeychainSwift** (master): Keychain access wrapper

## Testing

Target `DuckDepoTests` (Swift Testing, hosted by the app). The app skips its data stack and UI when `AppEnvironment.isRunningTests`.
- Use `TestStack.makeDatabase()` (in-memory store) and `InMemoryKeychain`
- Mark Core Data suites `@MainActor` (the view context is main-queue)
- The Xcode project has no file-system-synchronized groups: new files must be added to the project (and to the extension target when shared)

## Development Notes

### Localization
- English and Russian language support
- String Catalogs: `Localization/Localizable.xcstrings` (app and extension) and `InfoPlist.xcstrings`
- Predefined sections and fields: `FieldCatalog.swift`

### CloudKit Considerations
- Development environment configured
- Sharing capabilities enabled (`CKSharingSupported`)
- Push notifications for remote changes

### AutoFill Extension
- Shares Core Data stack with main app
- Implements `ASCredentialProviderViewController`
- Requires physical device for full testing

### Common Patterns
- Use `@State` for view models (see MVVM above) and `@Bindable` for bindings into shared `@Observable` controllers
- Environment injection for Core Data context
- Storage classes publish lists with Combine; view models subscribe in `start()`
- List items carry no photos (only `Document.thumbnail`); detail screens load the full document in `load()` and reload when the list item changes (sync)

## File Organization

- **Views**: SwiftUI views organized by feature
- **Models**: Core Data models and Swift structs
- **Controllers**: Business logic controllers
- **Helpers**: Extensions and utility functions
- **Styles**: Custom SwiftUI view modifiers and styles
- **CoreData**: Core Data model and entity classes