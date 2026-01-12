import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  // Prevents multiple concurrent scan attempts (e.g., rapid button taps
  // or build loops). Ensures only one scanner activity is active at a time.
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // Auto-trigger scanning as soon as the screen is presented.
    // We use a post-frame callback to ensure the UI is fully rendered
    // before launching the native scanner Activity.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // Launch the platform-native scanner (ZXing on Android, AVFoundation on iOS).
      // This is more robust than embedding a scanner widget on some hardware.
      final result = await BarcodeScanner.scan(
        options: const ScanOptions(
          strings: {
            'cancel': 'Cancel',
            'flash_on': 'Flash On',
            'flash_off': 'Flash Off',
          },
        ),
      );

      if (!mounted) return;

      if (result.type == ResultType.Barcode) {
        final rawValue = result.rawContent;
        // Authenticator URIs must follow the otpauth:// scheme.
        if (rawValue.startsWith('otpauth://')) {
          await _processUri(rawValue);
        } else {
          _showError('Invalid QR Code: Not an authenticator URI');
        }
      } else if (result.type == ResultType.Cancelled) {
        // If user presses the back button in the scanner, we exit this screen.
        Navigator.of(context).pop();
      } else if (result.type == ResultType.Error) {
        _showError('Scan error: ${result.rawContent}');
      }
    } catch (e) {
      _showError('Failed to start scanner: $e');
    } finally {
      // Always release the lock, even on failure, to allow manual retries.
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  /// Parses the 'otpauth://' URI and persists the new account.
  Future<void> _processUri(String uriString) async {
    try {
      final Uri uri = Uri.parse(uriString);
      final account = Account.fromUri(uri);

      // Save account to secure storage.
      final success = await Provider.of<AccountProvider>(
        context,
        listen: false,
      ).addAccountObject(account);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added account: ${account.name}')),
          );
          Navigator.of(context).pop(); // Return to Home screen on success.
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Account already exists: ${account.name}'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      _showError('Failed to add account: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Scanning'),
            ),
          ],
        ),
      ),
    );
  }
}
