import 'dart:async';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../services/storage_service.dart';

class AccountProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Account> _accounts = [];
  Timer? _timer;
  double _progress = 1.0;

  List<Account> get accounts => _accounts;
  double get progress => _progress;

  AccountProvider() {
    _loadAccounts();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      // TOTP usually has a 30-second period.
      // We calculate progress from 0.0 to 1.0.
      final seconds = (now / 1000) % 30;
      _progress = 1.0 - (seconds / 30.0);
      notifyListeners();
    });
  }

  Future<void> _loadAccounts() async {
    _accounts = await _storageService.getAccounts();
    notifyListeners();
  }

  Future<void> addAccount(String name, String secret, {String issuer = ''}) async {
    // Validate secret is valid base32 (basic check or try/catch during generation)
    // Here we just add it.
    final newAccount = Account(
      id: const Uuid().v4(),
      name: name,
      secret: secret.replaceAll(' ', '').toUpperCase(), // Clean secret
      issuer: issuer,
    );
    _accounts.add(newAccount);
    await _storageService.saveAccounts(_accounts);
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
    await _storageService.saveAccounts(_accounts);
    notifyListeners();
  }

  String getCurrentCode(String secret) {
    try {
      return OTP.generateTOTPCodeString(
        secret,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (e) {
      return 'ERROR';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
