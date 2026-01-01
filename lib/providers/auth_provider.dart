import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, setupRequired }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.unknown;
  bool _isBiometricEnabled = false;
  bool _hasPin = false;
  DateTime? _lockoutEndTime;
  DateTime? _backgroundTime; // Track when app went to background
  int _failedAttempts = 0;

  AuthStatus get status => _status;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get hasPin => _hasPin;
  DateTime? get lockoutEndTime => _lockoutEndTime;
  int get failedAttempts => _failedAttempts;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _hasPin = await _storageService.hasPin();
    _isBiometricEnabled = await _storageService.isBiometricEnabled();
    _failedAttempts = await _storageService.getFailedAttempts();
    _lockoutEndTime = await _storageService.getLockoutEndTime();

    // Check if lockout expired
    if (_lockoutEndTime != null && DateTime.now().isAfter(_lockoutEndTime!)) {
      _resetLockout();
    }

    if (!_hasPin) {
      // No security set up yet, allow access but maybe prompt to setup
      _status = AuthStatus.authenticated;
      // Or use AuthStatus.setupRequired if you want to force setup
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Trigger biometric authentication if enabled
  Future<void> authenticateWithBiometrics() async {
    if (!_isBiometricEnabled) return;

    bool success = await _authService.authenticate();
    if (success) {
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
    // If failed, status remains unauthenticated, UI should show PIN pad
  }

  Future<void> _resetLockout() async {
    _failedAttempts = 0;
    _lockoutEndTime = null;
    await _storageService.setFailedAttempts(0);
    await _storageService.setLockoutEndTime(null);
    notifyListeners();
  }

  /// Verify entered PIN against stored PIN
  Future<bool> verifyPin(String inputPin) async {
    // Check lockout first
    if (_lockoutEndTime != null) {
      if (DateTime.now().isBefore(_lockoutEndTime!)) {
        return false; // Still locked
      } else {
        await _resetLockout(); // Expired
      }
    }

    final storedPin = await _storageService.getPin();
    if (storedPin == inputPin) {
      _status = AuthStatus.authenticated;
      await _resetLockout();
      notifyListeners();
      return true;
    } else {
      // Failed
      _failedAttempts++;
      await _storageService.setFailedAttempts(_failedAttempts);

      if (_failedAttempts >= 5) {
        _lockoutEndTime = DateTime.now().add(const Duration(seconds: 30));
        await _storageService.setLockoutEndTime(_lockoutEndTime);
      }
      notifyListeners();
      return false;
    }
  }

  /// Set a new PIN and optionally enable biometrics
  Future<void> setSecurity(
    String newPin, {
    bool enableBiometrics = false,
  }) async {
    await _storageService.savePin(newPin);
    await _storageService.setBiometricEnabled(enableBiometrics);

    _hasPin = true;
    _isBiometricEnabled = enableBiometrics;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Disable all security
  Future<void> clearSecurity() async {
    await _storageService.deletePin();
    await _storageService.setBiometricEnabled(false);
    _hasPin = false;
    _isBiometricEnabled = false;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> toggleBiometrics(bool enabled) async {
    if (!_hasPin) return; // Cannot enable biometrics without PIN
    await _storageService.setBiometricEnabled(enabled);
    _isBiometricEnabled = enabled;
    notifyListeners();
  }

  Future<bool> shouldShowSetupPrompt() async {
    if (_hasPin) return false;
    return !(await _storageService.isPinSetupSkipped());
  }

  Future<void> skipSetupPrompt() async {
    await _storageService.setPinSetupSkipped();
  }

  // --- Lifecycle Logic ---

  /// Called when app goes to background
  void markBackground() {
    if (_status == AuthStatus.authenticated) {
      debugPrint('Marking background time: ${DateTime.now()}');
      _backgroundTime = DateTime.now();
    }
  }

  /// Called when app resumes. Locks if time exceeded threshold.
  void checkLock({int timeoutSeconds = 30}) {
    if (_backgroundTime != null && _hasPin) {
      final diff = DateTime.now().difference(_backgroundTime!).inSeconds;
      debugPrint(
        'App resumed. Background duration: ${diff}s. Timeout: ${timeoutSeconds}s',
      );
      if (diff > timeoutSeconds) {
        debugPrint('Locking app due to timeout.');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
      // Reset background time
      _backgroundTime = null;
    }
  }

  // Lock the app immediately
  void lock() {
    if (_hasPin) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }
}
