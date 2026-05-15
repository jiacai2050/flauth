# Performance Design inside Flauth

Flauth is designed to be a high-performance, battery-efficient TOTP authenticator. This document explains the key architectural decisions made to ensure smooth UI interaction even with a high-frequency (100ms) global heartbeat.

## 1. Global Heartbeat with Granular Updates

The application uses a central `AccountProvider` that maintains a `Timer.periodic` running every **100ms**.

- **Why 100ms?** This provides a 10Hz refresh rate, which is the "sweet spot" for `LinearProgressIndicator`. It ensures the progress bar moves smoothly across the 30-second TOTP window without looking jittery.
- **Why Persistent?** The timer runs continuously regardless of the account list size. This simplifies the state machine and ensures that the UI is always ready to display the correct progress as soon as an account is added or revealed.

## 2. Rebuild Optimization (context.select)

The most critical optimization is how individual `AccountTile` widgets consume data.

### The Problem
If every `AccountTile` used `Provider.of<AccountProvider>(context)`, every single tile would rebuild **10 times per second** because the provider notifies listeners every 100ms to update the top progress bar.

### The Solution: Selector Pattern
We use `context.select<AccountProvider, int>((p) => p.remainingSeconds)` inside `AccountTile`.

- **Filtering Notifications**: When `notifyListeners()` is called, `select` executes the selector function and compares the returned `int` with the previous value.
- **Lazy Rebuilding**: Since `remainingSeconds` only changes once every 1000ms, the `AccountTile` widget ignores 9 out of 10 notifications.
- **Result**: Even with 100+ accounts, the UI thread remains idle most of the time, only updating the specific tiles once per second.

## 3. Efficient TOTP Generation

TOTP codes are generated using the `otp` library, which performs HMAC-SHA1 calculations.

- **On-Demand Calculation**: Codes are not pre-calculated or stored in the provider's state. Instead, they are calculated during the `build` phase of the `AccountTile`.
- **Performance**: HMAC-SHA1 is a lightweight cryptographic operation. Modern mobile CPUs can perform thousands of these per second, making it perfectly safe to calculate them during a widget's 1fps rebuild.

## 4. Decoupled Services

- **StorageService**: Uses `flutter_secure_storage` which offloads sensitive data handling to the OS (Keychain/Keystore). This is an asynchronous operation that doesn't block the UI thread.
- **WebDavService**: All network I/O and path normalization logic are encapsulated in a static service. This keeps the `AccountProvider` clean and focused solely on state management.

## 5. Summary of UI Refresh Rates

| Component | Refresh Frequency | Strategy |
| :--- | :--- | :--- |
| **Global Timer** | 100ms (10Hz) | `Timer.periodic` |
| **Progress Bar** | 100ms (10Hz) | Direct consumption in `HomeScreen` |
| **Account Tile** | 1000ms (1Hz) | `context.select` optimization |
| **WebDAV Sync** | On Demand | Manual trigger |

By combining a high-frequency global heartbeat with low-frequency local consumption, Flauth achieves a "silky smooth" feel with minimal battery impact.
