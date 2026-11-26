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
- ViewModels use `@ObservableObject` and Combine for reactive UI updates
- Each major view has a corresponding ViewModel (e.g., `DepoListViewModel`, `EditDocumentViewModel`)
- Models are Core Data entities with custom classes

### Core Data Stack
- **PersistenceController**: Singleton managing NSPersistentCloudKitContainer. Roles: `.app` (syncs with CloudKit), `.autoFill` (same file, no CloudKit), `.inMemory` (tests)
- **CloudKit Integration**: Only the app mirrors to `iCloud.DuckDepo`. AutoFill writes reach the app through persistent history (`mergeChangesFromOtherProcesses`)
- **Store location**: moved from the app sandbox to the App Group on first launch of 2.7 (`moveLegacyStoreIfNeeded`); the extension waits for `DefaultsController.isSharedStoreReady`
- **Model changes**: run a Debug build once with `-InitializeCloudKitSchema`, then deploy the schema to Production in the CloudKit Console
- **Entities**: `DDDocument`, `DDPassword`, `DDSection`, `DDField`, `DDFolder`
- **File Protection**: Complete file protection enabled for security

### Security Architecture
- **BiometricController**: Manages Face ID/Touch ID authentication
- **Keychain Integration**: Password values live in the iCloud-synchronized keychain group (`Keychain` wraps KeychainSwift behind `KeychainStoring`); Core Data holds only name/login/website
- **App Locking**: `BiometricController` + `LockWindowPresenter` (a separate window above all sheets). Lock state is never persisted; the app always starts locked when the lock is on
- **LegacyDataMigration**: idempotent repair of v1 data, runs on every activation

### Navigation Structure
- Tab-based main interface: Depo (Documents), Passwords, Settings
- Modal presentations for editing workflows
- Context menus for list item interactions

## Key Components

### Data Layer
- `DataBase.swift`: Generic Core Data operations wrapper
- `DocumentsStorage.swift` / `PasswordsStorage.swift`: Entity-specific storage classes
- Migration system: `ManualMigrationV1toV2` handles data structure updates

### Controllers
- `BiometricController`: Authentication state management
- `DefaultsController`: UserDefaults wrapper with proper key management
- `ClipboardController`: Copies are local-only (no Universal Clipboard) and expire after 60 s (text) / 120 s (images)

### UI Components
- Custom neumorphic design system with adaptive dark/light themes
- Reusable components in `Views/Elements/`
- Custom button styles: `RoundedRectYellowButtonStyle`

## Dependencies

### Swift Package Manager
- **KeychainSwift** (master): Keychain access wrapper
- **SFSafeSymbols** (v5.3.0): Type-safe SF Symbols

## Testing

Target `DuckDepoTests` (Swift Testing, hosted by the app). The app skips its data stack and UI when `AppEnvironment.isRunningTests`.
- Use `TestStack.makeDatabase()` (in-memory store) and `InMemoryKeychain`
- Mark Core Data suites `@MainActor` (the view context is main-queue)
- The Xcode project has no file-system-synchronized groups: new files must be added to the project (and to the extension target when shared)

## Development Notes

### Localization
- English and Russian language support
- Strings files in `Localization/` folders
- Predefined field options in JSON format

### CloudKit Considerations
- Development environment configured
- Sharing capabilities enabled (`CKSharingSupported`)
- Push notifications for remote changes

### AutoFill Extension
- Shares Core Data stack with main app
- Implements `ASCredentialProviderViewController`
- Requires physical device for full testing

### Common Patterns
- Use `@StateObject` for ViewModel creation
- Environment injection for Core Data context
- Combine publishers for reactive data flow
- Custom view modifiers for consistent styling

## File Organization

- **Views**: SwiftUI views organized by feature
- **Models**: Core Data models and Swift structs
- **Controllers**: Business logic controllers
- **Helpers**: Extensions and utility functions
- **Styles**: Custom SwiftUI view modifiers and styles
- **CoreData**: Core Data model and entity classes