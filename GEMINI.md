# Project Context: Flauth

## Overview
**Flauth** is a secure, open-source TOTP (Time-based One-Time Password) authenticator application built with **Flutter**. It allows users to manage their 2FA accounts, supporting both manual entry and QR code scanning.

## Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Persistence:** `flutter_secure_storage` (Keychain on iOS, Keystore on Android)
- **Core Logic:** `otp` (TOTP generation), `base32` (Secret decoding)
- **Camera/Scanning:** `mobile_scanner`
- **Import/Export:** `file_picker` (Desktop/Import), `path_provider` (Mobile Export)

## Architecture
The project follows a clean separation of concerns, somewhat aligning with MVVM:
- **Models (`lib/models/`)**: Pure data classes (e.g., `Account`).
- **Services (`lib/services/`)**: Data access layer. `StorageService` handles secure reading/writing.
- **Providers (`lib/providers/`)**: ViewModels/Business Logic. `AccountProvider` manages the list of accounts, timer logic for the progress bar, and interacts with the storage service.
- **Screens (`lib/screens/`)**: UI pages (Home, Add Account, Scan QR, Import/Export).
- **Widgets (`lib/widgets/`)**: Reusable UI components (e.g., `AccountTile`).

## Key Files
- `lib/main.dart`: Application entry point. Initializes bindings and sets up the `MultiProvider`.
- `lib/providers/account_provider.dart`: Central hub for app state (account list, timer, progress).
- `lib/services/storage_service.dart`: Encapsulates `FlutterSecureStorage` interactions.
- `lib/screens/scan_qr_screen.dart`: Handles camera permissions and parsing of `otpauth://` URIs.
- `lib/screens/import_export_screen.dart`: Handles backing up and restoring accounts via standard text files.

## Development & Commands

### Running the App
```bash
flutter run
```

### Building
```bash
flutter build apk      # Android
flutter build ios      # iOS (requires Xcode)
flutter build macos    # macOS
```

### Testing & Quality
```bash
flutter test           # Run unit tests
flutter analyze        # Run static analysis
```

## Conventions
- **Code Style:** Standard Dart/Flutter guidelines.
- **Comments:** Key files are documented to explain "Why" certain decisions were made (e.g., `ensureInitialized` in main, timer logic in provider).
- **Security:** Secrets are **never** stored in plain text; always use `StorageService`.