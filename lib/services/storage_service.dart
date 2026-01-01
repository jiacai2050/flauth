import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/account.dart';

/// Handles persistent storage of accounts.
/// Uses [FlutterSecureStorage] to encrypt sensitive data (secrets) in the device's secure element
/// (Keychain on iOS, Keystore on Android).
class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _keyWebDavConfig = 'webdav_config';
  static const _keyPin = 'auth_pin';
  static const _keyBiometricEnabled = 'auth_biometric_enabled';
  static const _keyPinSkipped = 'auth_pin_skipped';
  static const _keyFailedAttempts = 'auth_failed_attempts';
  static const _keyLockoutEnd = 'auth_lockout_end';
  static const _accountPrefix = 'account_';

  /// Retrieves the list of accounts from secure storage.
  /// Each account is stored with its own key prefixed by 'account_'.
  Future<List<Account>> getAccounts() async {
    final allItems = await _storage.readAll();
    final List<Account> accounts = [];

    allItems.forEach((key, value) {
      if (key.startsWith(_accountPrefix)) {
        try {
          accounts.add(Account.fromJson(value));
        } catch (e) {
          // Ignore corrupted or invalid JSON entries
          debugPrint('Failed to parse account from key $key: $e');
        }
      }
    });

    return accounts;
  }

  // --- Auth & PIN ---

  Future<void> savePin(String pin) async {
    await _storage.write(key: _keyPin, value: pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _keyPin);
  }

  Future<bool> hasPin() async {
    return await _storage.containsKey(key: _keyPin);
  }

  Future<void> deletePin() async {
    await _storage.delete(key: _keyPin);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> setPinSetupSkipped() async {
    await _storage.write(key: _keyPinSkipped, value: 'true');
  }

  Future<bool> isPinSetupSkipped() async {
    final val = await _storage.read(key: _keyPinSkipped);
    return val == 'true';
  }

  // --- Lockout Logic ---

  Future<int> getFailedAttempts() async {
    final val = await _storage.read(key: _keyFailedAttempts);
    return val != null ? int.parse(val) : 0;
  }

  Future<void> setFailedAttempts(int attempts) async {
    await _storage.write(key: _keyFailedAttempts, value: attempts.toString());
  }

  Future<DateTime?> getLockoutEndTime() async {
    final val = await _storage.read(key: _keyLockoutEnd);
    return val != null ? DateTime.parse(val) : null;
  }

  Future<void> setLockoutEndTime(DateTime? time) async {
    if (time == null) {
      await _storage.delete(key: _keyLockoutEnd);
    } else {
      await _storage.write(key: _keyLockoutEnd, value: time.toIso8601String());
    }
  }

  /// Saves a single account to its own secure key.
  Future<void> saveAccount(Account account) async {
    await _storage.write(
      key: '$_accountPrefix${account.id}',
      value: account.toJson(),
    );
  }

  /// Deletes a specific account by its ID.
  Future<void> deleteAccount(String id) async {
    await _storage.delete(key: '$_accountPrefix$id');
  }

  /// Saves multiple accounts (useful for restore/import).
  Future<void> saveAccounts(List<Account> accounts) async {
    for (var acc in accounts) {
      await saveAccount(acc);
    }
  }

  // WebDAV Config
  Future<Map<String, String>?> getWebDavConfig() async {
    final String? jsonStr = await _storage.read(key: _keyWebDavConfig);
    if (jsonStr == null) return null;
    try {
      return Map<String, String>.from(json.decode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  Future<void> saveWebDavConfig(
    String url,
    String username,
    String password,
    String path,
  ) async {
    final map = {
      'url': url,
      'username': username,
      'password': password,
      'path': path,
    };
    await _storage.write(key: _keyWebDavConfig, value: json.encode(map));
  }
}
