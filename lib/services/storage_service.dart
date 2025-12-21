import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/account.dart';

/// Handles persistent storage of accounts.
/// Uses [FlutterSecureStorage] to encrypt sensitive data (secrets) in the device's secure element
/// (Keychain on iOS, Keystore on Android).
class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _keyAccounts = 'totp_accounts';

  /// Retrieves the list of accounts from secure storage.
  /// Returns an empty list if no data is found or if parsing fails.
  Future<List<Account>> getAccounts() async {
    final String? accountsJson = await _storage.read(key: _keyAccounts);
    if (accountsJson == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(accountsJson);
      return decoded.map((e) => Account.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Serializes and saves the list of accounts to secure storage.
  Future<void> saveAccounts(List<Account> accounts) async {
    final String encoded = json.encode(accounts.map((e) => e.toMap()).toList());
    await _storage.write(key: _keyAccounts, value: encoded);
  }
}