import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_pad.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isSettingPin = false;
  String _tempPin = '';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // If user is in the process of setting a new PIN
    if (_isSettingPin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_tempPin.isEmpty ? 'Set New PIN' : 'Confirm PIN'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSettingPin = false;
                _tempPin = '';
              });
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _tempPin.isEmpty ? 'Enter 6-digit PIN' : 'Re-enter to confirm',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: PinPad(
                  pinLength: 6,
                  onSubmit: (pin) {
                    if (_tempPin.isEmpty) {
                      // First entry
                      setState(() {
                        _tempPin = pin;
                      });
                    } else {
                      // Confirmation
                      if (pin == _tempPin) {
                        // Success
                        auth.setSecurity(
                          pin,
                          enableBiometrics: auth.isBiometricEnabled,
                        );
                        setState(() {
                          _isSettingPin = false;
                          _tempPin = '';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN Set Successfully')),
                        );
                      } else {
                        // Mismatch
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PINs do not match. Try again.'),
                          ),
                        );
                        setState(() {
                          _tempPin = ''; // Reset
                        });
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Main Security Settings List
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('PIN Protection'),
            subtitle: Text(auth.hasPin ? 'Enabled' : 'Disabled'),
            trailing: Switch(
              value: auth.hasPin,
              onChanged: (val) {
                if (val) {
                  // Enable -> Go to Set PIN
                  setState(() {
                    _isSettingPin = true;
                  });
                } else {
                  // Disable -> Clear Security
                  // Ideally, ask for current PIN before disabling.
                  // For simplicity:
                  auth.clearSecurity();
                }
              },
            ),
          ),
          if (auth.hasPin) ...[
            const Divider(),
            ListTile(
              title: const Text('Change PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  _isSettingPin = true;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Biometric Unlock'),
              subtitle: const Text('Use FaceID / Fingerprint'),
              value: auth.isBiometricEnabled,
              onChanged: (val) {
                auth.toggleBiometrics(val);
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Use PIN for Backup'),
              subtitle: const Text(
                'Automatically use your App PIN to encrypt/decrypt backups',
              ),
              value: auth.isUsePinForBackupEnabled,
              onChanged: (val) {
                auth.toggleUsePinForBackup(val);
              },
            ),
          ],
        ],
      ),
    );
  }
}
