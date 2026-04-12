import 'package:flauth/models/account.dart';
import 'package:otp/otp.dart';

import 'backup_reader.dart';

class TotpPrintResult {
  final String output;
  final List<CliWarning> warnings;

  const TotpPrintResult({required this.output, required this.warnings});
}

TotpPrintResult buildTotpOutput(List<Account> accounts, {DateTime? now}) {
  final DateTime currentTime = now ?? DateTime.now();
  final List<_RenderedAccount> rows = <_RenderedAccount>[];
  final List<CliWarning> warnings = <CliWarning>[];

  for (final Account account in accounts) {
    final String code = _generateCurrentCode(account.secret, now: currentTime);
    if (code == 'ERROR') {
      final String issuer = account.issuer.isEmpty
          ? '<unknown>'
          : account.issuer;
      final String name = account.name.isEmpty ? '<unknown>' : account.name;
      warnings.add(CliWarning('Invalid secret for $issuer / $name.'));
    }

    rows.add(
      _RenderedAccount(
        issuer: account.issuer.isEmpty ? '-' : account.issuer,
        name: account.name.isEmpty ? '-' : account.name,
        code: code,
      ),
    );
  }

  final int issuerWidth = rows.isEmpty
      ? 1
      : rows.map((row) => row.issuer.length).reduce(_max);
  final int nameWidth = rows.isEmpty
      ? 1
      : rows.map((row) => row.name.length).reduce(_max);

  final String output = rows
      .map(
        (row) =>
            '${row.issuer.padRight(issuerWidth)}  ${row.name.padRight(nameWidth)}  ${row.code}',
      )
      .join('\n');

  return TotpPrintResult(output: output, warnings: warnings);
}

String _generateCurrentCode(String secret, {required DateTime now}) {
  try {
    return OTP.generateTOTPCodeString(
      secret,
      now.millisecondsSinceEpoch,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );
  } catch (_) {
    return 'ERROR';
  }
}

int _max(int left, int right) => left > right ? left : right;

class _RenderedAccount {
  final String issuer;
  final String name;
  final String code;

  const _RenderedAccount({
    required this.issuer,
    required this.name,
    required this.code,
  });
}
