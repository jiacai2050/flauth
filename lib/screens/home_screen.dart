import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../widgets/account_tile.dart';
import 'add_account_screen.dart';
import 'scan_qr_screen.dart';
import 'import_export_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: 'Import / Export',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ImportExportScreen()),
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
                  provider.progress < 0.2 ? Colors.red : Theme.of(context).primaryColor,
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tap + to add an account'),
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
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Button to open the QR Scanner
          FloatingActionButton.extended(
            heroTag: 'scan',
            onPressed: () {
               Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScanQrScreen()),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan'),
          ),
          const SizedBox(width: 16),
          // Button to open the Manual Entry screen
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AddAccountScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}