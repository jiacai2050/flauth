import 'package:flutter/material.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.unknown;

  AuthStatus get status => _status;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Initial check. We start unauthenticated.
    // In a future version, we might check a shared_preference to see if auth is enabled.
    // For now, we assume it's always enabled if supported.
    bool supported = await _authService.isDeviceSupported();
    if (!supported) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> authenticate() async {
    bool success = await _authService.authenticate();
    if (success) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
