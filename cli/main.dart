import 'dart:io';

import 'account_filter.dart';
import 'backup_reader.dart';
import 'totp_printer.dart';

const String version = String.fromEnvironment('VERSION', defaultValue: 'dev');

Future<void> main(List<String> arguments) async {
  String cliName = Platform.script.pathSegments.last;

  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(_usage(cliName));
    return;
  }

  if (arguments.contains('--version') || arguments.contains('-v')) {
    stdout.writeln('$cliName $version');
    return;
  }

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
    stderr.writeln(_usage(cliName));
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

String _usage(String program) {
  return '''
Usage:
  $program [filter]

Options:
  -h, --help               Show this help message
  -v, --version            Show version

Environment variables:
  FLAUTH_BACKUP_FILE       Backup file path
  FLAUTH_BACKUP_PASSWORD   Password for encrypted Flauth backups
''';
}
