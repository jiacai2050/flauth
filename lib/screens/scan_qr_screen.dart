import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  bool _isProcessing = false;

  /// Callback when a barcode is detected by the scanner.
  void _handleScan(Code result) {
    if (_isProcessing) return;

    if (result.isValid && result.text != null) {
      final String rawValue = result.text!;
      // Check if the QR code is a valid TOTP URI
      if (rawValue.startsWith('otpauth://')) {
        setState(() {
          _isProcessing = true;
        });
        
        _processUri(rawValue);
      }
    }
  }

  /// Parses the 'otpauth://' URI to extract account details.
  /// Expected format: otpauth://totp/Issuer:Account?secret=SECRET&issuer=Issuer
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
                // Optionally pop or let user scan another
                Navigator.of(context).pop();
              }
            }
          })
          .catchError((e) {
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
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: ReaderWidget(
        onScan: _handleScan,
        codeFormat: Format.qrCode,
        resolution: ResolutionPreset.high,
        showToggleCamera: true,
        showFlashlight: true,
        showGallery: false,
      ),
    );
  }
}