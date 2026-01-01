import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/account_tile.dart';
import 'scan_qr_screen.dart';
import 'import_export_screen.dart';
import 'about_screen.dart';
import 'security_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSecuritySetup());
  }

  Future<void> _checkSecuritySetup() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (await auth.shouldShowSetupPrompt()) {
      if (!mounted) return;
      _showSetupDialog(auth);
    }
  }

  void _showSetupDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Protect your accounts'),
        content: const Text(
          'It is highly recommended to set up a PIN to secure your 2FA tokens. Would you like to do it now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              auth.skipSetupPrompt();
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SecurityScreen()),
              );
            },
            child: const Text('Setup Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flauth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: 'Import / Export',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ImportExportScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
        // Display a progress bar at the bottom of the AppBar.
        // This gives a visual indication of when the code will expire.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Consumer<AccountProvider>(
            builder: (context, provider, child) {
              return LinearProgressIndicator(
                value: provider.progress,
                minHeight: 4.0,
                backgroundColor: Colors.transparent,
                // Change color to red when time is running out (< 20%).
                valueColor: AlwaysStoppedAnimation<Color>(
                  provider.progress < 0.2
                      ? Colors.red
                      : Theme.of(context).primaryColor,
                ),
              );
            },
          ),
        ),
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, child) {
          if (provider.accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_clock, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No accounts yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap the button below to scan a QR code'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: provider.accounts.length,
            itemBuilder: (context, index) {
              return AccountTile(account: provider.accounts[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const ScanQrScreen()));
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan'),
      ),
    );
  }
}
