# Flauth 🔐

[中文说明](./README_zh.md)

Flauth is a secure, open-source TOTP (Time-based One-Time Password) authenticator built with Flutter. It provides a simple, beautiful, and lightweight solution for managing your 2FA (Two-Factor Authentication) tokens.

## 🌟 Why Flauth?

- **100% Open Source**: Transparent and trustable code. Your secrets never leave your device unless you choose to sync them.
- **Flexible Backups**:
  - **Local Backup**: Export/Import accounts as standard text files using system file pickers.
  - **WebDAV Sync**: Seamlessly sync your data with your private cloud (Nextcloud, Nutstore, etc.) using a robust single-file sync approach with custom path support.
- **Privacy & Security**:
  - **Encrypted Storage**: Secrets are encrypted and stored in the device's secure element (Keychain on iOS/macOS, Keystore on Android).
  - **Granular Storage**: Implements "One Key Per Account" architecture for maximum reliability and scalability.
- **Modern UI**: Focused on simplicity. Built with Material 3, supporting adaptive light and dark modes.

## ✨ Features

- **TOTP Generation**: Standard 6-digit codes refreshing every 30 seconds.
- **QR Code Scanner**: Quickly add accounts by scanning standard `otpauth://` QR codes.
- **Live Progress**: Visual timer indicating code expiration.
- **Deduplication**: Intelligent duplicate check based on secret keys to prevent account bloat.
- **Easy Management**: Tap to copy, swipe to delete with confirmation.

![](assets/account-empty.png)
![](assets/backup-local.png)
![](assets/backup-webdav.png)
![](assets/account-two.png)

## 🛠️ Tech Stack

- **Framework**: Flutter & Dart
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Core Logic**: [OTP](https://pub.dev/packages/otp)
- **Security**: [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- **Scanner**: [Mobile Scanner](https://pub.dev/packages/mobile_scanner)
- **Networking**: Standard [http](https://pub.dev/packages/http) for lightweight WebDAV.

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- Appropriate development environment (Xcode for iOS/macOS, Android Studio for Android).

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jiacai2050/flauth.git
   cd flauth
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

## 🏗️ Platform Specifics

### macOS
To build on macOS, ensure you have set up a **Development Team** in Xcode for code signing (required for Keychain access in Sandbox). The app includes entitlements for:
- Network Client (WebDAV)
- Camera (Scanning)
- Keychain Sharing (Secure Storage)
- User-Selected File Access (Local Backup)

## 🛡️ Permissions

- **Camera**: To scan QR codes for adding accounts.
- **Local Storage/Network**: To backup/restore accounts locally or via WebDAV.

## 📄 License

This project is licensed under the [MIT License](https://liujiacai.net/license/MIT).
