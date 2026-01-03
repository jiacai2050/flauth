# Android Signing Guide

This document describes how to configure Android app signing for Flauth, both for local development and automated CI/CD using GitHub Actions.

## 1. Local Development Setup

To build a signed release APK locally, follow these steps:

### Step 1: Create a Keystore
If you don't have one, generate a keystore file:
```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Step 2: Configure key.properties
Create a file at `android/key.properties` (this file is ignored by Git):
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 3: Build
Run the release build command:
```bash
flutter build apk --release
```
The build system will automatically detect `key.properties` and use your JKS file. If the file is missing, it will fallback to debug signing.

## 3. Verifying the Signature

After building the APK, you can verify if it was signed correctly using the `apksigner` tool (part of the Android SDK Build Tools).

On **macOS**, it's typically located at:
`~/Library/Android/sdk/build-tools/<version>/apksigner`

Example command:
```bash
~/Library/Android/sdk/build-tools/34.0.0/apksigner verify --print-certs --verbose build/app/outputs/flutter-apk/app-release.apk
```

Check the output for the **Signer #1 certificate DN** and **SHA-256 digest** to ensure they match your keystore.

---

## 4. F-Droid & Third-party Builds

Our `android/app/build.gradle.kts` is designed to be environment-agnostic:
- If signing keys are present, it produces a signed release.
- If keys are missing (like on F-Droid build servers), it **falls back to debug signing** automatically. This ensures the source code remains buildable by anyone without needing private keys.
