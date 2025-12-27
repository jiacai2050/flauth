import 'dart:async';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../services/storage_service.dart';

/// Manages the state of the application, including the list of accounts and the TOTP timer.
class AccountProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Account> _accounts = [];
  Timer? _timer;
  
  // Progress of the current 30-second TOTP window (1.0 = full, 0.0 = empty).
  double _progress = 1.0;

  List<Account> get accounts => _accounts;
  double get progress => _progress;

  AccountProvider() {
    _loadAccounts();
    _startTimer();
  }

  /// Starts a periodic timer to update the progress bar and refresh codes.
  /// Updates every 100ms for smooth UI animation.
  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final now = DateTime.now().millisecondsSinceEpoch;
      // TOTP codes are valid for 30 seconds.
      // We calculate how many seconds have passed in the current window.
      final seconds = (now / 1000) % 30;
      
      // Calculate remaining percentage for the progress bar.
      _progress = 1.0 - (seconds / 30.0);
      
      // Notify UI to redraw (updating the progress bar and the codes if the window changed).
      notifyListeners();
    });
  }

  Future<void> _loadAccounts() async {
    _accounts = await _storageService.getAccounts();
    notifyListeners();
  }

  /// Adds a new account and persists it to storage.
  Future<void> addAccount(String name, String secret, {String issuer = ''}) async {
    // Generate a unique ID for the account.
    final newAccount = Account(
      id: const Uuid().v4(),
      name: name,
      // Ensure secret is uppercase and has no spaces, as required by Base32 decoding.
      secret: secret.replaceAll(' ', '').toUpperCase(),
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

  /// Adds an account directly (e.g. from URI parsing)
  Future<void> addAccountObject(Account account) async {
    _accounts.add(account);
    await _storageService.saveAccounts(_accounts);
    notifyListeners();
  }

  /// Exports all accounts to a newline-separated string of otpauth URIs.
  String exportAccountsToText() {
    return _accounts.map((a) => a.toUriString()).join('\n');
  }

  /// Imports accounts from a text string (one URI per line).
  /// Returns the number of accounts successfully imported.
  Future<int> importAccountsFromText(String text) async {
    int count = 0;
    final lines = text.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final uri = Uri.parse(line.trim());
        final account = Account.fromUri(uri);
        // Check for duplicates based on secret to avoid double entry?
        // For now, we allow duplicates or could check secret.
        // Let's simple add.
        _accounts.add(account);
        count++;
      } catch (e) {
        // Skip invalid lines
        debugPrint('Skipping invalid line: $line ($e)');
      }
    }
    if (count > 0) {
      await _storageService.saveAccounts(_accounts);
      notifyListeners();
    }
    return count;
  }

  /// Generates the current 6-digit TOTP code for a given secret.
  String getCurrentCode(String secret) {
    try {
      return OTP.generateTOTPCodeString(
        secret,
        DateTime.now().millisecondsSinceEpoch,
        algorithm: Algorithm.SHA1,
        isGoogle: true, // Uses Google Authenticator compatibility
      );
    } catch (e) {
      // Return error string if secret is invalid (e.g. not valid Base32)
      return 'ERROR';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}