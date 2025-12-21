import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/account.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();
  static const _keyAccounts = 'totp_accounts';

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

  Future<void> saveAccounts(List<Account> accounts) async {
    final String encoded = json.encode(accounts.map((e) => e.toMap()).toList());
    await _storage.write(key: _keyAccounts, value: encoded);
  }
}
