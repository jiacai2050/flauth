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
import 'webdav_config_screen.dart';

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

  // --- Local File Handlers ---

  Future<void> _handleLocalExport() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<AccountProvider>(context, listen: false);

      final text = provider.exportAccountsToText();

      if (text.isEmpty) {
        _showSnackBar('No accounts to export');

        return;
      }

      final now = DateTime.now();

      final fileName =
          'flauth_backup_${DateFormat('yyyyMMdd_HHmmss').format(now)}.txt';

      if (Platform.isAndroid) {
        // Android: Use System "Save As" dialog via SAF (Storage Access Framework)

        // 1. Write to temp file first

        final directory = await getTemporaryDirectory();

        final tempFile = File('${directory.path}/$fileName');

        await tempFile.writeAsString(text);

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

        await file.writeAsString(text);

        _showSnackBar('Saved to "Files" App > On My iPhone > Flauth');
      } else {
        // Desktop: Use Save Dialog

        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Backup File',

          fileName: fileName,

          type: FileType.custom,

          allowedExtensions: ['txt'],
        );

        if (outputPath != null) {
          final file = File(outputPath);

          await file.writeAsString(text);

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
        type: FileType.any,
      );

      if (result != null) {
        final file = File(result.files.single.path!);

        final content = await file.readAsString();

        if (!mounted) return;

        final provider = Provider.of<AccountProvider>(context, listen: false);

        final count = await provider.importAccountsFromText(content);

        if (mounted) {
          if (count > 0) {
            _showSnackBar('Successfully imported $count new accounts');
          } else {
            _showSnackBar(
              'No new accounts added (duplicates or empty)',
              backgroundColor: Colors.orange,
            );
          }
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
  final String _fixedFileName = 'flauth_backup.txt';

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

      final provider = Provider.of<AccountProvider>(context, listen: false);
      final text = provider.exportAccountsToText();

      if (text.isEmpty) {
        _showSnackBar('No accounts to upload');
        return;
      }

      final fullUrl = '$baseUrl$remotePath$_fixedFileName';
      final fileUri = Uri.parse(fullUrl);
      final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';

      final response = await http.put(
        fileUri,
        headers: {'Authorization': basicAuth, 'Content-Type': 'text/plain'},
        body: text,
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
        if (!mounted) return;
        final provider = Provider.of<AccountProvider>(context, listen: false);
        final count = await provider.importAccountsFromText(content);
        if (mounted) {
          if (count > 0) {
            _showSnackBar('Successfully synced $count new accounts');
          } else {
            _showSnackBar(
              'Already up to date. No new accounts found in Cloud.',
              backgroundColor: Colors.orange,
            );
          }
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

            desc: 'Sync backups with your private cloud (Nextcloud,坚果云, etc).',

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
