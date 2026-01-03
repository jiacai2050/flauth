import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_pad.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start a timer to refresh UI only when locked out
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final lockoutEnd = auth.lockoutEndTime;
      if (lockoutEnd != null && DateTime.now().isBefore(lockoutEnd)) {
        if (mounted) setState(() {});
      }
    });

    // Try biometrics automatically if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isBiometricEnabled) {
        auth.authenticateWithBiometrics();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handlePinSubmit(String pin) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool isValid = await auth.verifyPin(pin);
    if (!isValid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect PIN'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lockoutEnd = auth.lockoutEndTime;
    final isLocked = lockoutEnd != null && DateTime.now().isBefore(lockoutEnd);

    int secondsRemaining = 0;
    if (isLocked) {
      secondsRemaining = lockoutEnd.difference(DateTime.now()).inSeconds;
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocked ? Icons.lock_clock : Icons.lock_outline,
              size: 64,
              color: isLocked ? Colors.red : Colors.blueGrey,
            ),
            const SizedBox(height: 16),
            Text(
              isLocked ? 'Locked for ${secondsRemaining}s' : 'Enter PIN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.red : null,
              ),
            ),
            if (!isLocked && auth.failedAttempts > 0 && auth.failedAttempts < 5)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${5 - auth.failedAttempts} attempts remaining',
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            const SizedBox(height: 40),

            // Reusable PinPad Widget
            AbsorbPointer(
              absorbing: isLocked, // Disable input when locked
              child: Opacity(
                opacity: isLocked ? 0.5 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: PinPad(
                    pinLength: 6, // Changed to 6-digit PIN
                    onSubmit: _handlePinSubmit,
                    showBiometricButton: auth.isBiometricEnabled && !isLocked,
                    onBiometricPressed: () => auth.authenticateWithBiometrics(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
