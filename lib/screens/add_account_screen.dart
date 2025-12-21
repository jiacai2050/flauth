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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Provider.of<AccountProvider>(context, listen: false).addAccount(
        _nameController.text,
        _secretController.text,
        issuer: _issuerController.text,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () async {
              // Navigate to ScanQrScreen. If it adds an account successfully, it pops.
              // We could also await a result if we wanted to pre-fill this form instead.
              // For now, let's assume ScanQrScreen handles the addition directly.
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScanQrScreen()),
              );
              // If we returned and the user added an account, we might want to close this screen too,
              // or just stay here. If the user successfully added an account in ScanQrScreen,
              // ScanQrScreen pops itself. We can check if we should pop too, but it's fine to stay.
              if (context.mounted && Provider.of<AccountProvider>(context, listen: false).accounts.isNotEmpty) {
                 // Optional: Check if a new account was actually added recently? 
                 // Or just let the user go back manually.
                 // Let's just pop this screen if we want to go back to Home directly after a successful scan.
                 // However, without a return value, it's hard to know.
                 // Let's keep it simple: Stay here.
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
                  // Basic regex check for Base32 could go here
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
