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
- **Share Extension**: `DuckDepoShareExtension/` - saves images and PDFs shared from other apps as a document (see Share Extension below)
- **Shared Core Data**: The app and both extensions open the same store in the App Group container (`group.evgenymitko.duckdepo`)
- **Minimum iOS**: 26.0 for all targets

## Architecture

### MVVM Pattern
- ViewModels are `@Observable` classes held in `@State`. A view model built in a view's initializer is rebuilt on every parent redraw, so its init must be cheap: heavy work (fetches, keychain reads, full documents) goes in `start()`/`load()`, called once from `onAppear`
- Each major view has a corresponding ViewModel (e.g., `DepoListViewModel`, `EditDocumentViewModel`)
- Models are Core Data entities with custom classes

### Core Data Stack
- **PersistenceController**: Singleton managing NSPersistentCloudKitContainer. Roles: `.app` (syncs with CloudKit), `.autoFill` and `.share` (same file, no CloudKit), `.inMemory` (tests)
- **CloudKit Integration**: Only the app mirrors to `iCloud.DuckDepo`. The extensions' writes (`Role.extensions`: AutoFill, Share) reach the app through persistent history (`mergeChangesFromOtherProcesses`, `extensionTransactions`). The extensions don't merge others' changes: call `DataBase.readLatestStoredData()` before reading what the app may have changed
- **Store location**: moved from the app sandbox to the App Group on first launch of 2.7 (`moveLegacyStoreIfNeeded`); the extensions wait for `DefaultsController.isSharedStoreReady`
- **Model changes**: add a new model version (additive only: CloudKit can't rename or remove), run a Debug build once with `-InitializeCloudKitSchema`, then deploy the schema to Production in the CloudKit Console
- **Entities**: `DDDocument`, `DDPhoto`, `DDPassword`, `DDSection`, `DDField`, `DDFolder` (current model: `DuckDepo 3`)
- **Keys**: predefined sections and fields store a stable `key` (`SectionKey`/`FieldKey` in `FieldCatalog.swift`) and display their name from it, so names follow the current language. Date fields store `yyyy-MM-dd` (`FieldDate`); documents keep `createdAt`/`updatedAt`/`expiresAt`
- **Photos**: one `DDPhoto` record per photo (ID derived from the image bytes), plus the old `photoData` blob kept in sync for devices still on 2.6. `LegacyDataMigration` converts `photoData` changed by 2.6 and removes duplicate records the same way on every device. `DocumentPhoto` holds only the JPEG and its `size`: `image` decodes a new copy on each call (keep it only while shown), `downsampled(toMaxPixelSize:)` for anything smaller. New photos are stored at `storedScale` (long side 2560 px; pages over 2:1 keep about 3.3 MP so text stays readable) and on white where transparent. A failed `save`/`update` rolls the context back (`saveOrRollBack`)
- **File Protection**: Complete file protection enabled for security

### Scanning (`DuckDepo/Scanning/`)
- Everything runs on the device. `DocumentScanner.draft(from:)`: Vision text recognition (`DocumentReader`, language correction off), then exact parsers (`MRZParser` for passport/ID zones with check digits, `DrivingLicenceParser` for the numbered fields of EU and Russian licences, VINs), then `ModelExtractor` (on-device `SystemLanguageModel` only, never the Private Cloud Compute model) for fields still empty
- The model doesn't support Russian (skipped for mostly-Cyrillic text) and makes values up: `ScanReading.add(_:text:)` keeps only values printed in the recognized text. It's prewarmed when a scan starts and given 6 s
- Search inside photos: `PhotoIndexer` reads every document photo's text in the background (on launch and when documents change) into `PhotoTextIndex`, a local file only on this device (complete file protection, excluded from backups, nothing syncs; keys are document ID + content-derived photo ID). `SearchViewModel` adds photo matches with an excerpt
- The result opens in the editor (`EditDocumentViewModel.Mode.scanned`) with a banner and per-field `ScanMarker`s (verified / read / suggested) that disappear once a value is edited; nothing is saved until confirmed

### Security Architecture
- **BiometricController**: Manages Face ID/Touch ID authentication
- **Keychain Integration**: Password values live in the iCloud-synchronized keychain group (`Keychain` wraps KeychainSwift behind `KeychainStoring`); Core Data holds only name/login/website. One-time code setups (`otpauth://` links, `OneTimeCode`, RFC 6238) are stored next to them under `<id>.otp` and offered to AutoFill as `ASOneTimeCodeCredentialIdentity` (extension capability `ProvidesOneTimeCodes`)
- **Passkeys** (`DuckDepo/Passkeys/`): DuckDepo is a WebAuthn authenticator in AutoFill (extension capability `ProvidesPasskeys`). `PasskeyAuthenticator` builds the P-256/ES256 COSE key, "none" attestation (zero AAGUID) and assertions with a small canonical `CBOR` encoder; flags say backup eligible and backed up. Each `Passkey` (credential ID, site, user, user handle, private key) is JSON in the synced keychain under `passkey.<base64url credential ID>` with its own keychain service `DuckDepo.passkey` (`PasskeyStorage`), so listing reads no passwords and nothing touches Core Data or the CloudKit schema. Lists hold `PasskeySummary` (no key); the key is read only to sign and, after `UserVerification`, to export (`allWithKeys`). A new passkey replaces the account's earlier one (same site and user handle). Changes made in this process post `PasskeyStorage.didChange`. Creating or using one asks `UserVerification` (Face ID or passcode) first, unless the user just unlocked the AutoFill list; the extension never signs without interaction. When a site asks for a passkey, the AutoFill list shows its passkeys above the passwords. The app lists passkeys in their own section of Passwords (`PasskeyRow`, `PasskeyView`, delete only; deleting removes only that suggestion from `ASCredentialIdentityStore`)
- **Import and export** (`Support/CredentialExchange.swift`, `CredentialTransfer.swift`): iOS 26 Credential Exchange between password managers, no files. `CredentialExchange` converts; `CredentialTransfer` reads and saves.
  - Export (Settings › Export to Another App): `UserVerification` (required: no passcode, no export; asked before the system sheet, since a prompt during it shows behind it), then `ASCredentialExportManager`. Secrets are read off the main thread. Passwords with codes; a website only when its host has a dot (Passwords refuses the whole item with "gi"; without a website it keeps login, password and code). Passkeys with their PKCS#8 key. Documents: passport / ID card / driving licence (from type + name, `CredentialExchange.Kind`, fields taken only from predefined sections) as typed credentials, other sections as custom field groups with their section ID and name, days zero-padded, the type as a tag, and everything again as a note (section names included, last line `cx_note_footer`), because Passwords keeps only notes. Photos don't go.
  - Import: the system opens the app with `ASCredentialExchangeActivity` (app `NSUserActivityTypes`; extension `SupportsCredentialExchange` + `SupportedCredentialExchangeVersions`). `CredentialImporter` (in `ContentView`) reads it (newest import wins; gives up if the store doesn't load); `ImportPlan` leaves out what's saved and reads only the matching accounts' secrets; `ImportSheet` asks and shows progress.
    - Same account: site + login, or with no site, name + login. Same password and agreeing codes (same secret, or one missing) means already saved; a saved value not yet synced here counts as saved; a different code is kept as a new entry. Passkeys by credential ID. Documents by type, name, description and fields (key or title = value, days normalised).
    - Codes go with the login their account names. One document per typed credential. A typed document keeps its type over tags. Text dates become days. Each custom group is its own section. DuckDepo's own note (by its footer) is dropped when fields came too, kept as notes when it's all there is (Passwords). Passwords sends note-only items as an empty login. Cards, Wi-Fi, SSH/API keys (with what came with them) and notes on passwords are counted, not imported.
    - Saving runs once per plan, in batches of 100 (keychain writes off the main thread, then one save), skips IDs already stored, re-checks that a saved password still has no code before giving it one, and refreshes AutoFill once. Code links with short secrets are read (typed keys still need 80 bits)
- **App Locking**: `BiometricController` + `LockWindowPresenter` (a separate window above all sheets). Lock state is never persisted; the app always starts locked when the lock is on
- **Password Health** (`DuckDepo/PasswordHealth/`, app only):
  - `PasswordHealthMonitor.shared` reads values from the keychain off the main thread, hashes and judges them, and keeps only `PasswordHealth` (list items, issues, no values). One pass at a time: a refresh during a pass asks for another after it (`requestPass`), never cancels it. `start()` again refreshes, so screens call it on appear. `isLoaded` false means not read yet (summary and tiles stay neutral, never "no issues")
  - Reuse by SHA-1 (`PasswordsStorage.valueHash`). Strength by `PasswordStrength`, on device, first 256 characters: `CommonPasswords` as typed or with look-alikes ("1" as i and l) and up to 6 digits or symbols around it; then words, runs (alphabet, digits, keyboard rows, shifted digits, keyboard walks like 1q2w/1qaz), repeats (one character, or a 2–6 character chunk) and years cost a few bits each; caseless scripts count as a large alphabet; under 36 bits or 8 characters is weak
  - Leak check off by default (`checksLeakedPasswords`): `PwnedPasswords` sends 5 hex digits of the SHA-1 to Have I Been Pwned's padded range API (fixed headers, ephemeral session) and rejects anything that isn't a hash list. Each prefix's answer goes to `LeakCheckCache` as it arrives (local file, complete protection, HMAC under a this-device keychain key): leaked stays leaked while the password has that value, safe is rechecked after a week; entries for gone values are pruned. Turning it off or Delete All Data bumps a generation so a lookup in flight records nothing
  - "Hide Warning" is `<id>.health` = `v1:<value SHA-1>:<issue kinds>` in the synced keychain next to the value: hidden only while the value matches and no new kind of issue appears (a leak found later shows it again). `PasswordsStorage.didChange` (object: the keychain) covers value-only edits
  - Shown in Settings (To Fix tile, "–" until loaded; four tiles in a row or 2×2 when they don't fit; section with the screen and both switches) and, when `showsPasswordHealthInPasswords`, at the top of Passwords. Rows open the password by ID (`navigationDestination(item:)`), so moving rows don't close it. Each password's screen shows its warning at the top, or once hidden only a small note with Show Warning at the bottom (not in AutoFill). The Privacy page lists the leak check
- **LegacyDataMigration**: idempotent repair of v1 data, runs on every activation

### Navigation Structure
- Tab-based main interface (`Tab` API): Depo (Documents), Passwords, Settings, plus a search tab (`Tab(role: .search)` with `.tabViewSearchActivation(.searchTabSelection)`, the separate button at the end of the tab bar) that searches documents and passwords together (`SearchView`)
- Each list is a selection-based `NavigationSplitView` (sidebar list, detail column on iPad, push on iPhone), with swipe actions and context menus
- Editors are sheets with close/confirm toolbar buttons (`Button(role: .close)` / `.confirm`) and a discard confirmation
- Photos open in `PhotoViewer` (full screen, zoom transition from the tapped photo; only the page on screen and its neighbours hold a full-size image); on the document they show in `PhotoGallery` (a row at each photo's own shape, or one photo at full width); the editor's strip draws `PhotoThumbnails` (cached copies sized to the cell)
- A document's share menu: Share as Text and Copy All (`Document.plainText`: name, description, filled-in fields by section; Copy All goes through `ClipboardController`), and its photos as a PDF
- Settings: an overview card (counts, with passkeys counted as passwords; documents to renew; passwords to fix), rows with `ColorfulIconLabelStyle` tiles (`.labelStyle(.tile(color))`), Security (lock, clipboard), Password Health, Reminders, Sync and AutoFill (status from `ASCredentialIdentityStore`), Import and Export (`TransferSection`, `ImportGuideView`), About (Privacy page, version)

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

### Share Extension
- Target `DuckDepoShareExtension` (bundle `DuckDepo.DuckDepoShareExtension`, flag `SHARE_EXTENSION`, store role `.share` with transaction author "share", merged by the app like AutoFill's; `Role.extensions`)
- Takes images and PDFs (activation rule in its Info.plist), about 120 MB of memory in all. `PageImport` reads each item from its file (`loadFileRepresentation`; data only as a fallback) a page at a time without decoding full-size images (ImageIO thumbnails; PDF pages by their crop box; every page of a TIFF), keeps identical pages once, up to `PageImport.maximumSharedPages` (10, the editor's photo picker included)
- New Document: `DocumentScanner.draft(from: [DocumentPhoto])`, then the app's own `EditDocumentView` in `.scanned` mode as a sheet (the camera is hidden: extensions can't use it; Add Photo opens the library directly). Add to a Document: Face ID first when `BiometricController.isLockRequired` (the list shows names), then `DataBase.addPhotos(_:toDocumentWith:)`, which only appends photo records and the 2.6 copy (`DDDocument.appendPhotos`: never rewrites sections from the extension's possibly stale copy) and refuses documents with more than 30 MB of photos (`.tooLarge`)
- While the documents list is open it's covered when the host app goes inactive and closed once the host has been in the background for the lock's delay (`NSExtensionHost…` notifications in `ShareViewController`)
- No keychain access (its entitlements have only the App Group); Face ID text in its own `InfoPlist.xcstrings`
- It compiles the data layer, the scanner and the document editor; new files they need must be added to the share target too

### AutoFill Extension
- Shares Core Data stack with main app
- Implements `ASCredentialProviderViewController`
- Requires physical device for full testing

### Common Patterns
- Use `@State` for view models (see MVVM above) and `@Bindable` for bindings into shared `@Observable` controllers
- Environment injection for Core Data context
- Storage classes publish lists with Combine; view models subscribe in `start()`
- List items carry no photos (only `Document.thumbnail`); detail screens load the full document in `load()` and reload when the list item changes (sync)
- Animation: changes the user makes animate (`withAnimation` at the call site: deletes, edits coming back from an editor, toggles via `$x.animation()`, model writes after the first load); counts use `.contentTransition(.numericText())`, changing symbols `.symbolEffect(.replace)`. Never animate a screen's first load (`onAppear`/`start()`), whole lists arriving from iCloud, or the lock window (a fade would show in the app-switcher snapshot). Scope `.animation(_:value:)` to the view that changes, so typing and selection aren't animated

## File Organization

- **Views**: SwiftUI views organized by feature
- **Models**: Core Data models and Swift structs
- **Controllers**: Business logic controllers
- **Helpers**: Extensions and utility functions
- **Styles**: Custom SwiftUI view modifiers and styles
- **CoreData**: Core Data model and entity classes