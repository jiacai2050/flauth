import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Callback when a barcode is detected by the scanner.
  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String rawValue = barcode.rawValue!;
        // Check if the QR code is a valid TOTP URI
        if (rawValue.startsWith('otpauth://')) {
          _isProcessing = true;
          // Stop the camera immediately to prevent multiple reads
          controller.stop();
          
          _processUri(rawValue);
          break;
        }
      }
    }
  }

  /// Parses the 'otpauth://' URI to extract account details.
  /// Expected format: otpauth://totp/Issuer:Account?secret=SECRET&issuer=Issuer
  void _processUri(String uriString) {
    try {
      final Uri uri = Uri.parse(uriString);
      if (uri.scheme != 'otpauth' || uri.host != 'totp') {
         throw Exception('Invalid scheme or host');
      }

      final String path = uri.path;
      // The path usually contains the label (Issuer:Account or just Account)
      String name = path.startsWith('/') ? path.substring(1) : path;
      String issuer = '';

      if (name.contains(':')) {
        final parts = name.split(':');
        issuer = parts[0];
        name = parts.sublist(1).join(':');
      }

      final String? secret = uri.queryParameters['secret'];
      final String? queryIssuer = uri.queryParameters['issuer'];

      // Prefer the issuer from query parameters if available
      if (queryIssuer != null && queryIssuer.isNotEmpty) {
        issuer = queryIssuer;
      }

      if (secret == null || secret.isEmpty) {
        throw Exception('No secret found');
      }

      // Add the account to the provider
      Provider.of<AccountProvider>(context, listen: false)
          .addAccount(name, secret, issuer: issuer)
          .then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added account: $name')),
          );
          Navigator.of(context).pop(); // Return to previous screen (Home)
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
    setState(() {
      _isProcessing = false;
    });
    // Restart scanning if an error occurred
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: _handleBarcode,
      ),
    );
  }
}