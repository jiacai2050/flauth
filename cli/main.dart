import 'dart:io';

import 'account_filter.dart';
import 'backup_reader.dart';
import 'totp_printer.dart';

Future<void> main(List<String> arguments) async {
  try {
    final String? filter = resolveFilter(arguments);
    final BackupReadResult readResult = await readBackupAccounts();
    final filteredAccounts = filterAccounts(readResult.accounts, filter);
    final TotpPrintResult printResult = buildTotpOutput(filteredAccounts);

    for (final CliWarning warning in readResult.warnings) {
      stderr.writeln('Warning: ${warning.format()}');
    }
    for (final CliWarning warning in printResult.warnings) {
      stderr.writeln('Warning: ${warning.format()}');
    }

    if (printResult.output.isNotEmpty) {
      stdout.writeln(printResult.output);
    }
  } catch (error) {
    stderr.writeln('Error: ${_formatError(error)}');
    stderr.writeln(_usage());
    exitCode = 1;
  }
}

String _formatError(Object error) {
  if (error is FileSystemException) {
    if (error.path == null || error.path!.isEmpty) {
      return error.message;
    }
    return '${error.message} (${error.path})';
  }

  if (error is FormatException) {
    return error.message;
  }
  return error.toString().replaceFirst('Exception: ', '');
}

String _usage() {
  return '''
Usage:
  flauth-cli [filter]

Environment variables:
  FLAUTH_BACKUP_FILE       Backup file path
  FLAUTH_BACKUP_PASSWORD   Password for encrypted Flauth backups
''';
}
