import 'dart:convert';
import 'dart:io';

import 'package:flauth/models/account.dart';
import 'package:flauth/services/backup_security_service.dart';

const String backupFileEnvVar = 'FLAUTH_BACKUP_FILE';
const String backupPasswordEnvVar = 'FLAUTH_BACKUP_PASSWORD';

class CliWarning {
  final int? lineNumber;
  final String message;

  const CliWarning(this.message, {this.lineNumber});

  String format() {
    if (lineNumber == null) {
      return message;
    }
    return 'line $lineNumber: $message';
  }
}

class BackupReadResult {
  final String backupFilePath;
  final List<Account> accounts;
  final List<CliWarning> warnings;

  const BackupReadResult({
    required this.backupFilePath,
    required this.accounts,
    required this.warnings,
  });
}

String? resolveFilter(List<String> arguments) {
  if (arguments.length > 1) {
    throw const FormatException('Expected at most one filter argument.');
  }

  return _normalizedValue(arguments.isEmpty ? null : arguments.first);
}

String resolveBackupFilePath({Map<String, String>? environment}) {
  final Map<String, String> env = environment ?? Platform.environment;
  final String? envPath = _normalizedValue(env[backupFileEnvVar]);
  if (envPath != null) {
    return envPath;
  }

  throw const FormatException(
    'Backup file is required via FLAUTH_BACKUP_FILE.',
  );
}

Future<BackupReadResult> readBackupAccounts({
  Map<String, String>? environment,
}) async {
  final Map<String, String> env = environment ?? Platform.environment;
  final String backupFilePath = resolveBackupFilePath(environment: env);

  final File backupFile = File(backupFilePath);
  if (!await backupFile.exists()) {
    throw FileSystemException('Backup file does not exist.', backupFilePath);
  }

  final String rawContent = await backupFile.readAsString();
  final String content = _resolveBackupContent(rawContent, env);
  final ParseAccountsResult parseResult = parseAccountsFromText(content);

  if (parseResult.accounts.isEmpty) {
    throw const FormatException('No valid accounts found in backup file.');
  }

  return BackupReadResult(
    backupFilePath: backupFilePath,
    accounts: parseResult.accounts,
    warnings: parseResult.warnings,
  );
}

class ParseAccountsResult {
  final List<Account> accounts;
  final List<CliWarning> warnings;

  const ParseAccountsResult({required this.accounts, required this.warnings});
}

ParseAccountsResult parseAccountsFromText(String text) {
  final List<Account> accounts = <Account>[];
  final List<CliWarning> warnings = <CliWarning>[];
  final List<String> lines = const LineSplitter().convert(text);

  for (int index = 0; index < lines.length; index++) {
    final String line = lines[index].trim();
    if (line.isEmpty) {
      continue;
    }

    try {
      final Uri uri = Uri.parse(line);
      accounts.add(Account.fromUri(uri));
    } on FormatException catch (error) {
      warnings.add(CliWarning(error.message, lineNumber: index + 1));
    } catch (error) {
      warnings.add(CliWarning(error.toString(), lineNumber: index + 1));
    }
  }

  return ParseAccountsResult(accounts: accounts, warnings: warnings);
}

String _resolveBackupContent(
  String rawContent,
  Map<String, String> environment,
) {
  if (!BackupSecurityService.isEncrypted(rawContent)) {
    return rawContent;
  }

  final String? password = _normalizedValue(environment[backupPasswordEnvVar]);
  if (password == null) {
    throw const FormatException(
      'Encrypted backup requires FLAUTH_BACKUP_PASSWORD.',
    );
  }

  return BackupSecurityService.decrypt(rawContent, password);
}

String? _normalizedValue(String? value) {
  if (value == null) {
    return null;
  }

  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
