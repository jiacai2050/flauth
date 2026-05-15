import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import '../models/account.dart';
import '../widgets/account_tile.dart';
import 'scan_qr_screen.dart';
import 'manual_entry_screen.dart';
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
        bottom: _AppBarProgress(),
      ),
      body: Selector<AccountProvider, List<Account>>(
        // Optimization: Selector only triggers a rebuild if the returned value (List reference)
        // changes. AccountProvider ensures this by creating a new list copy on every modification.
        selector: (_, p) => p.accounts,
        builder: (context, accounts, child) {
          if (accounts.isEmpty) {
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
                  const Text('Tap + to add an account'),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
            itemCount: accounts.length,
            onReorder: (oldIndex, newIndex) {
              Provider.of<AccountProvider>(
                context,
                listen: false,
              ).reorderAccounts(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final account = accounts[index];
              return Container(
                key: ValueKey(
                  account.id,
                ), // Key is required for ReorderableListView
                child: AccountTile(account: account),
              );
            },
          );
        },
      ),
      floatingActionButton: _SpeedDialFab(
        onScanQr: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const ScanQrScreen()));
        },
        onManualEntry: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
          );
        },
      ),
    );
  }
}

class _SpeedDialFab extends StatefulWidget {
  final VoidCallback onScanQr;
  final VoidCallback onManualEntry;

  const _SpeedDialFab({
    required this.onScanQr,
    required this.onManualEntry,
  });

  @override
  State<_SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<_SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: _controller.isDismissed,
              child: child,
            );
          },
          child: SizeTransition(
            sizeFactor: _controller,
            axisAlignment: 1.0,
            child: FadeTransition(
              opacity: _controller,
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildMiniAction(
                      label: 'Manual Entry',
                      icon: Icons.keyboard,
                      onPressed: () {
                        _controller.reverse();
                        widget.onManualEntry();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildMiniAction(
                      label: 'Scan QR',
                      icon: Icons.qr_code_scanner,
                      onPressed: () {
                        _controller.reverse();
                        widget.onScanQr();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: _toggle,
          child: RotationTransition(
            turns: _rotationAnimation,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: label,
          onPressed: onPressed,
          child: Icon(icon),
        ),
      ],
    );
  }
}

class _AppBarProgress extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(4.0);

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        if (provider.accounts.isEmpty) {
          return const SizedBox(height: 4.0);
        }
        return LinearProgressIndicator(
          value: provider.progress,
          minHeight: 4.0,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            provider.progress < 0.2
                ? Colors.red
                : Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }
}
