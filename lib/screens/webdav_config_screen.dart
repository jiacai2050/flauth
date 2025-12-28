import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';

class WebDavConfigScreen extends StatefulWidget {
  const WebDavConfigScreen({super.key});

  @override
  State<WebDavConfigScreen> createState() => _WebDavConfigScreenState();
}

class _WebDavConfigScreenState extends State<WebDavConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pathController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final provider = Provider.of<AccountProvider>(context, listen: false);
    final config = await provider.getWebDavConfig();
    if (config != null && mounted) {
      _urlController.text = config['url'] ?? '';
      _usernameController.text = config['username'] ?? '';
      _passwordController.text = config['password'] ?? '';
      _pathController.text = config['path'] ?? '';
    }
  }

  Future<void> _testAndSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final url = _urlController.text.trim();
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();
    String path = _pathController.text.trim();

    // Ensure path ends with / if not empty
    if (path.isNotEmpty && !path.endsWith('/')) {
      path = '$path/';
    }
    // Ensure path starts with / if not empty
    if (path.isNotEmpty && !path.startsWith('/')) {
      path = '/$path';
    }

    try {
      final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
      final uri = Uri.parse(url);

      // Use PROPFIND with Depth: 0 to check if the root (or URL) exists/is accessible
      // This is a standard WebDAV check.
      final client = http.Client();
      final request = http.Request('PROPFIND', uri)
        ..headers['Authorization'] = basicAuth
        ..headers['Depth'] = '0';

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          final provider = Provider.of<AccountProvider>(context, listen: false);
          await provider.saveWebDavConfig(url, user, pass, path);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection successful & Saved!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Server responded with status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Server URL',
                    hintText: 'https://dav.example.com/',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'URL is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Username is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pathController,
                  decoration: const InputDecoration(
                    labelText: 'Remote Path (Optional)',
                    hintText: '/flauth_backups/',
                    border: OutlineInputBorder(),
                    helperText: 'Leave empty for root directory',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _testAndSave,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test Connection & Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
