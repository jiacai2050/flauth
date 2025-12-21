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