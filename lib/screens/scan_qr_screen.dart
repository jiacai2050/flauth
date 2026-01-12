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
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to trigger the scan immediately after the build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasScanned) {
        _startScan();
      }
    });
  }

  Future<void> _startScan() async {
    try {
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
        if (rawValue.toLowerCase().startsWith('otpauth://')) {
          _processUri(rawValue);
        } else {
          _showError('Invalid QR Code: Not an authenticator URI');
        }
      } else if (result.type == ResultType.Cancelled) {
        // User cancelled, maybe just stay on screen or pop?
        // Usually popping is expected if they pressed back in the scanner
        Navigator.of(context).pop();
      } else if (result.type == ResultType.Error) {
        _showError('Scan error: ${result.rawContent}');
      }
    } catch (e) {
      _showError('Failed to start scanner: $e');
    } finally {
      if (mounted) {
        setState(() {
          _hasScanned = true;
        });
      }
    }
  }

  /// Parses the 'otpauth://' URI to extract account details.
  void _processUri(String uriString) {
    try {
      final Uri uri = Uri.parse(uriString);
      final account = Account.fromUri(uri);

      // Add the account to the provider
      Provider.of<AccountProvider>(context, listen: false)
          .addAccountObject(account)
          .then((success) {
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added account: ${account.name}')),
            );
            Navigator.of(context).pop(); // Return to previous screen (Home)
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
      }).catchError((e) {
        _showError('Failed to add account: $e');
      });
    } catch (e) {
      _showError('Invalid QR Code: $e');
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

