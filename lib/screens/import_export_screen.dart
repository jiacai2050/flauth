import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/auth_provider.dart';
import '../services/backup_security_service.dart';
import 'webdav_config_screen.dart';

class ExportData {
  final String content;
  final String extension;

  ExportData(this.content, this.extension);
}

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  // --- Helper Dialogs ---

  Future<String?> _showSetPasswordDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _SetPasswordDialog(),
    );
  }

  Future<String?> _showEnterPasswordDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _EnterPasswordDialog(),
    );
  }

  // --- Unified Security Logic ---

  Future<ExportData?> _prepareExportContent() async {
    final accountProvider = Provider.of<AccountProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rawText = accountProvider.exportAccountsToText();

    if (rawText.isEmpty) {
      _showSnackBar('No accounts to export');
      return null;
    }

    String? password;
    bool usingAppPin = false;

    if (authProvider.isUsePinForBackupEnabled && authProvider.hasPin) {
      password = await authProvider.getBackupPassword();
      usingAppPin = true;
    } else {
      // Ask for encryption
      password = await _showSetPasswordDialog();
    }

    if (!mounted) return null;
    if (password == null) {
      // User cancelled
      return null;
    }

    String finalContent = rawText;
    String extension = 'flauth';

    if (password.isNotEmpty) {
      // Encrypt
      try {
        finalContent = BackupSecurityService.encrypt(rawText, password);
        if (usingAppPin) {
          _showSnackBar('Encrypted with App PIN');
        }
      } catch (e) {
        _showSnackBar('Encryption failed: $e', isError: true);
        return null;
      }
    }
    return ExportData(finalContent, extension);
  }

  Future<String?> _processImportContent(String content) async {
    // Check encryption
    if (BackupSecurityService.isEncrypted(content)) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Try with App PIN first if enabled
      if (authProvider.isUsePinForBackupEnabled && authProvider.hasPin) {
        final pin = await authProvider.getBackupPassword();
        if (pin != null) {
          try {
            return BackupSecurityService.decrypt(content, pin);
          } catch (_) {
            // Decryption with PIN failed, maybe it was a custom password?
            // Fall through to manual password dialog
          }
        }
      }

      if (!mounted) return null;
      final password = await _showEnterPasswordDialog();
      if (!mounted) return null;
      if (password == null) {
        // Cancelled
        return null;
      }
      try {
        return BackupSecurityService.decrypt(content, password);
      } catch (e) {
        _showSnackBar('Decryption failed: $e', isError: true);
        return null;
      }
    }
    return content;
  }

  // --- Local File Handlers ---

  Future<void> _handleLocalExport() async {
    setState(() => _isLoading = true);

    try {
      final exportData = await _prepareExportContent();
      if (exportData == null) return;

      final now = DateTime.now();
      final fileName =
          'flauth-${DateFormat('yyyyMMdd-HHmmss').format(now)}.${exportData.extension}';

      if (Platform.isAndroid) {
        // Android: Use System "Save As" dialog via SAF (Storage Access Framework)
        // 1. Write to temp file first
        final directory = await getTemporaryDirectory();
        final tempFile = File('${directory.path}/$fileName');
        await tempFile.writeAsString(exportData.content);

        // 2. Hand over to system dialog
        final params = SaveFileDialogParams(sourceFilePath: tempFile.path);
        final finalPath = await FlutterFileDialog.saveFile(params: params);

        if (finalPath != null) {
          _showSnackBar('Backup saved successfully');
        }
      } else if (Platform.isIOS) {
        // iOS: Save to Documents
        final directory = await getApplicationDocumentsDirectory();
        final outputPath = '${directory.path}/$fileName';
        final file = File(outputPath);
        await file.writeAsString(exportData.content);

        _showSnackBar('Saved to "Files" App > On My iPhone > Flauth');
      } else {
        // Desktop: Use Save Dialog
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup File',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: [exportData.extension],
        );

        if (outputPath != null) {
          final file = File(outputPath);
          await file.writeAsString(exportData.content);
          _showSnackBar('Saved to: $outputPath');
        }
      }
    } catch (e) {
      debugPrint('Export error: $e');
      _showSnackBar('Export failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLocalImport() async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['flauth'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        String content = await file.readAsString();

        final decryptedContent = await _processImportContent(content);
        if (decryptedContent == null) return;

        if (!mounted) return;
        final provider = Provider.of<AccountProvider>(context, listen: false);
        final count = await provider.importAccountsFromText(decryptedContent);

        if (count > 0) {
          _showSnackBar('Successfully imported $count new accounts');
        } else {
          _showSnackBar(
            'No new accounts added (duplicates or empty)',
            backgroundColor: Colors.orange,
          );
        }
      }
    } catch (e) {
      debugPrint('Import error: $e');
      _showSnackBar('Import failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // WebDAV Handlers

  // Use a fixed filename for sync-like behavior
  final String _fixedFileName = 'flauth_backup.flauth';

  Future<Map<String, String>?> _getWebDavConfig() async {
    final provider = Provider.of<AccountProvider>(context, listen: false);
    final config = await provider.getWebDavConfig();
    if (config == null || config['url'] == null) {
      _showSnackBar('Please configure WebDAV first');
      _openWebDavConfig();
      return null;
    }
    return config;
  }

  void _openWebDavConfig() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const WebDavConfigScreen()));
  }

  Future<void> _handleWebDavUpload() async {
    setState(() => _isLoading = true);

    try {
      final config = await _getWebDavConfig();
      if (!mounted) return;
      if (config == null) return;

      final url = config['url']!;
      final user = config['username'] ?? '';
      final pass = config['password'] ?? '';

      // Normalize Base URL: ensure it ends with /
      String baseUrl = url;
      if (!baseUrl.endsWith('/')) baseUrl += '/';

      // Normalize Remote Path: ensure it DOES NOT start with /, and ends with /
      String remotePath = config['path'] ?? '';
      if (remotePath.startsWith('/')) remotePath = remotePath.substring(1);
      if (remotePath.isNotEmpty && !remotePath.endsWith('/')) remotePath += '/';

      final exportData = await _prepareExportContent();
      if (exportData == null) return;

      final fullUrl = '$baseUrl$remotePath$_fixedFileName';
      final fileUri = Uri.parse(fullUrl);
      final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

      final response = await http.put(
        fileUri,
        headers: {'Authorization': basicAuth, 'Content-Type': 'text/plain'},
        body: exportData.content,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSnackBar('Uploaded successfully to $fullUrl');
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWebDavDownload() async {
    setState(() => _isLoading = true);

    try {
      final config = await _getWebDavConfig();
      if (!mounted) return;
      if (config == null) return;

      final url = config['url']!;

      final user = config['username'] ?? '';

      final pass = config['password'] ?? '';

      // Normalize Base URL: ensure it ends with /

      String baseUrl = url;

      if (!baseUrl.endsWith('/')) baseUrl += '/';

      // Normalize Remote Path: ensure it DOES NOT start with /, and ends with /

      String remotePath = config['path'] ?? '';

      if (remotePath.startsWith('/')) remotePath = remotePath.substring(1);

      if (remotePath.isNotEmpty && !remotePath.endsWith('/')) remotePath += '/';

      final fullUrl = '$baseUrl$remotePath$_fixedFileName';

      final fileUri = Uri.parse(fullUrl);

      final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

      final response = await http.get(
        fileUri,

        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final content = response.body;

        final decryptedContent = await _processImportContent(content);
        if (decryptedContent == null) return;

        if (!mounted) return;
        final provider = Provider.of<AccountProvider>(context, listen: false);
        final count = await provider.importAccountsFromText(decryptedContent);
        if (count > 0) {
          _showSnackBar('Successfully synced $count new accounts');
        } else {
          _showSnackBar(
            'Already up to date. No new accounts found in Cloud.',
            backgroundColor: Colors.orange,
          );
        }
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Download failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    Color? bg = backgroundColor;
    if (bg == null && isError) {
      bg = Colors.red;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),

        bottom: TabBar(
          controller: _tabController,

          tabs: const [
            Tab(text: 'Local File', icon: Icon(Icons.folder)),

            Tab(text: 'WebDAV Cloud', icon: Icon(Icons.cloud)),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.settings),

            onPressed: _openWebDavConfig,

            tooltip: 'WebDAV Settings',
          ),
        ],
      ),

      body: TabBarView(
        controller: _tabController,

        children: [
          // Local Tab
          _buildActionView(
            icon: Icons.sd_storage,

            title: 'Local Storage',

            desc: 'Save backups to your device or import from local files.',

            btn1Text: 'Export to File',

            btn1Icon: Icons.upload_file,

            btn1Action: _handleLocalExport,

            btn2Text: 'Import from File',

            btn2Icon: Icons.drive_folder_upload,

            btn2Action: _handleLocalImport,
          ),

          // WebDAV Tab
          _buildActionView(
            icon: Icons.cloud_sync,
            title: 'WebDAV Cloud',
            desc:
                'Sync backups with your private cloud (Nextcloud, InfiniCloud etc).',
            btn1Text: 'Upload to Cloud',
            btn1Icon: Icons.cloud_upload,
            btn1Action: _handleWebDavUpload,
            btn2Text: 'Restore from Cloud',
            btn2Icon: Icons.cloud_download,
            btn2Action: _handleWebDavDownload,
          ),
        ],
      ),
    );
  }

  Widget _buildActionView({
    required IconData icon,

    required String title,

    required String desc,

    required String btn1Text,

    required IconData btn1Icon,

    required VoidCallback btn1Action,

    required String btn2Text,

    required IconData btn2Icon,

    required VoidCallback btn2Action,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            Icon(icon, size: 80, color: Colors.blueGrey),

            const SizedBox(height: 32),

            Text(
              title,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              desc,

              textAlign: TextAlign.center,

              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 48),

            FilledButton.icon(
              onPressed: btn1Action,

              icon: Icon(btn1Icon),

              label: Text(btn1Text),

              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: btn2Action,
              icon: Icon(btn2Icon),

              label: Text(btn2Text),

              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetPasswordDialog extends StatefulWidget {
  const _SetPasswordDialog();

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Encrypt Backup?'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Protect your backup with a password. If you lose this password, you cannot restore your accounts.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (val) =>
                  (val == null || val.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (val) =>
                  val != _passCtrl.text ? 'Passwords do not match' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Cancel export
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ''), // Skip encryption
          child: const Text('Skip (Plain Text)'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _passCtrl.text);
            }
          },
          child: const Text('Encrypt'),
        ),
      ],
    );
  }
}

class _EnterPasswordDialog extends StatefulWidget {
  const _EnterPasswordDialog();

  @override
  State<_EnterPasswordDialog> createState() => _EnterPasswordDialogState();
}

class _EnterPasswordDialogState extends State<_EnterPasswordDialog> {
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decrypt Backup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('This file is encrypted. Please enter the password.'),
          const SizedBox(height: 16),
          TextField(
            controller: _passCtrl,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => Navigator.pop(context, _passCtrl.text),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _passCtrl.text),
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
