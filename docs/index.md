# Flauth 🔐

<div align="center">
<img src="https://raw.githubusercontent.com/jiacai2050/flauth/main/assets/app_icon.svg" alt="Flauth Logo" width="100"/>
</div>

> **Flauth** is a privacy-first, fully open-source TOTP authenticator for Android, macOS, Windows, and Linux.

It provides a simple and lightweight solution for managing your 2FA (Two-Factor Authentication) tokens.

[:material-download: Download Latest Release](https://github.com/jiacai2050/flauth/releases){ .md-button .md-button--primary }
[:material-github: View on GitHub](https://github.com/jiacai2050/flauth){ .md-button }

---

## 🌟 Why Flauth?

- **100% Open Source**: Transparent and trustable code. Your secrets never leave your device unless you choose to sync them.
- **Flexible Backups**:
    - **Security Logic**: Detailed [backup and restore mechanisms](backup.md).
    - **Local Backup**: Export/Import accounts as standard text files using system file pickers.
    - **WebDAV Sync**: Seamlessly sync your data with your private cloud (Nextcloud, Nutstore, etc.).
- **Privacy & Security**:
    - **Security Architecture**: Detailed [security implementation](auth.md).
    - **Encrypted Storage**: Secrets are encrypted and stored in the device's secure element (Keychain on iOS/macOS, Keystore on Android).
- **Modern UI**: Focused on simplicity. Built with Material 3, supporting adaptive light and dark modes.

## 📸 Screenshots

<div align="center">
  <img src="https://raw.githubusercontent.com/jiacai2050/flauth/main/metadata/en-US/images/phoneScreenshots/1.png" alt="Account List" width="200" style="margin: 10px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
  <img src="https://raw.githubusercontent.com/jiacai2050/flauth/main/metadata/en-US/images/phoneScreenshots/2.png" alt="Backup & Sync" width="200" style="margin: 10px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
  <img src="https://raw.githubusercontent.com/jiacai2050/flauth/main/metadata/en-US/images/phoneScreenshots/3.png" alt="Security Settings" width="200" style="margin: 10px; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
</div>

## ⬇️ Download

You can find the latest pre-compiled binaries for all supported platforms (Android APK, macOS, Linux, and Windows) on the **[GitHub Releases](https://github.com/jiacai2050/flauth/releases)** page.

## 🛡️ Permissions

- **Camera**: To scan QR codes for adding accounts.
- **Local Storage/Network**: To backup/restore accounts locally or via WebDAV.

## 📄 License

This project is licensed under the [MIT License](https://github.com/jiacai2050/flauth/blob/main/LICENSE).
