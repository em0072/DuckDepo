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
xcodebuild -project DuckDepo.xcodeproj -scheme DuckDepo -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild -project DuckDepo.xcodeproj -scheme DuckDepo clean
```

### Project Structure
- **Main App**: `DuckDepo/` - SwiftUI app with MVVM architecture
- **AutoFill Extension**: `DuckDepoAutoFillExtension/` - iOS AutoFill credential provider
- **Shared Core Data**: Both targets share the same Core Data model and storage

## Architecture

### MVVM Pattern
- ViewModels use `@ObservableObject` and Combine for reactive UI updates
- Each major view has a corresponding ViewModel (e.g., `DepoListViewModel`, `EditDocumentViewModel`)
- Models are Core Data entities with custom classes

### Core Data Stack
- **PersistenceController**: Singleton managing NSPersistentCloudKitContainer
- **CloudKit Integration**: Automatic sync with `iCloud.DuckDepo` container
- **Entities**: `DDDocument`, `DDPassword`, `DDSection`, `DDField`, `DDFolder`
- **File Protection**: Complete file protection enabled for security

### Security Architecture
- **BiometricController**: Manages Face ID/Touch ID authentication
- **Keychain Integration**: Secure credential storage via KeychainSwift
- **App Locking**: Configurable biometric delays (5 seconds to 15 minutes)

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
- `ClipboardController`: Secure clipboard operations with auto-clear

### UI Components
- Custom neumorphic design system with adaptive dark/light themes
- Reusable components in `Views/Elements/`
- Custom button styles: `RoundedRectYellowButtonStyle`

## Dependencies

### Swift Package Manager
- **KeychainSwift** (master): Keychain access wrapper
- **SFSafeSymbols** (v5.3.0): Type-safe SF Symbols

## Testing

Currently no test targets are configured. When adding tests:
- Use XCTest framework
- Test ViewModels independently of UI
- Mock Core Data stack for unit tests
- Use iOS Simulator for AutoFill extension testing

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