import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _isLoading = false;

  Future<void> _handleExport() async {
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
        // iOS: Save to Documents. User can access via Files app (On My iPhone -> Flauth)
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

  Future<void> _handleImport() async {
    setState(() => _isLoading = true);
    try {
      // Use FileType.any to avoid issues on Android where .txt files might be grayed out
      // due to MIME type mismatch. We'll validate the content later.
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
            _showSnackBar('Successfully imported $count accounts');
          } else {
            _showSnackBar('No valid accounts found in file', isError: true);
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.backup, size: 80, color: Colors.blueGrey),
                    const SizedBox(height: 32),
                    const Text(
                      'Manage your backups',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Export your accounts to a secure file or import them from an existing backup.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 48),

                    // Export Button
                    FilledButton.icon(
                      onPressed: _handleExport,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Export to File'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Import Button
                    OutlinedButton.icon(
                      onPressed: _handleImport,
                      icon: const Icon(Icons.download),
                      label: const Text('Import from File'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
