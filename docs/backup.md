# Backup & Restore Logic

This document describes the implementation details of Flauth's backup and restore system, covering local file exports and WebDAV cloud synchronization.

## 1. Overview

Flauth supports two backup methods:
*   **Local File**: Export accounts to a file on your device or import from an existing file.
*   **WebDAV Sync**: Synchronize your accounts with a private cloud (e.g., Nextcloud, Nutstore) using the WebDAV protocol.

Both methods share the same underlying security architecture.

## 2. Security Architecture

To ensure the safety of your 2FA secrets, Flauth provides industry-standard encryption for backup files.

### 2.1 Encryption Standard
*   **Algorithm**: AES-256-CBC (Advanced Encryption Standard).
*   **Key Derivation**: PBKDF2 (Password-Based Key Derivation Function 2) with HMAC-SHA256.
*   **Iterations**: 10,000 rounds (balances performance and security).
*   **Salting**: A unique 16-byte random salt is generated for every backup to prevent rainbow table attacks.
*   **IV**: A 16-byte random Initialization Vector is used for every encryption to ensure uniqueness.

### 2.2 File Formats

Flauth unifies all backup files with the `.flauth` extension. The app automatically detects whether the file is encrypted or plain text during the import process.

#### Encrypted Format
Encrypted backups are stored as a JSON container:
```json
{
  "version": 1,
  "kdf": {
    "algorithm": "pbkdf2",
    "iterations": 10000,
    "salt": "<Base64 encoded salt>"
  },
  "encryption": {
    "algorithm": "aes-256-cbc",
    "iv": "<Base64 encoded IV>",
    "data": "<Base64 encoded ciphertext>"
  }
}
```

#### Plain Text Format
If the user chooses to skip encryption, accounts are exported as a simple list of `otpauth://` URIs, one per line (still saved with the `.flauth` extension).

## 3. Workflows

### 3.1 Export Workflow
1.  **Collect Data**: Gather all accounts and convert them to `otpauth://` URIs.
2.  **Security Choice**: Prompt the user to enter a password (minimum 6 characters) or skip encryption.
3.  **Encryption**: If a password is provided, derive a 256-bit key and encrypt the content.
4.  **Save/Upload**: 
    *   **Local**: Use the system file picker to save the `.flauth` file (encrypted or plain text).
    *   **WebDAV**: Upload the content to the configured remote path (defaults to `flauth_backup.flauth`).

### 3.2 Import Workflow
1.  **Read Content**: Load the file string from local storage or download from WebDAV.
2.  **Detection**: Automatically check if the content is a JSON container with the expected encryption keys.
3.  **Decryption**: 
    *   If encrypted, prompt the user for the password.
    *   Re-derive the key using the salt and iterations stored in the JSON.
    *   Perform AES decryption.
4.  **Parsing**: Parse the resulting URI list and add new accounts to the local secure storage (skipping duplicates).

## 4. Platform Specifics (macOS)

For macOS users running the app in a development environment without official code signing, Flauth handles entitlements carefully to ensure the file picker functions correctly within the App Sandbox.
