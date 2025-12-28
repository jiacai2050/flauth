import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import 'scan_qr_screen.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _secretController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Add the account manually using the input values
      final success = await Provider.of<AccountProvider>(context, listen: false).addAccount(
        _nameController.text,
        _secretController.text,
        issuer: _issuerController.text,
      );
      
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account with this secret already exists'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
        actions: [
          // Shortcut to switch to scanning mode if user changes their mind
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScanQrScreen()),
              );
              
              if (context.mounted && Provider.of<AccountProvider>(context, listen: false).accounts.isNotEmpty) {
                 // Logic handled in ScanQrScreen, but we could pop here if needed.
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  labelText: 'Issuer (optional)',
                  hintText: 'e.g., Google, GitHub',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g., user@example.com',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _secretController,
                decoration: const InputDecoration(
                  labelText: 'Secret Key',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the secret key';
                  }
                  // TODO: Add strict Base32 validation regex if needed
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Add Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}