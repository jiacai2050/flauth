import 'package:flutter_test/flutter_test.dart';
import 'package:flauth/models/account.dart';

import '../cli/totp_printer.dart';

void main() {
  group('CLI TOTP printer', () {
    test('prints current code output without inserted spacing', () {
      final List<Account> accounts = <Account>[
        Account(
          id: '1',
          issuer: 'GitHub',
          name: 'alice@example.com',
          secret: 'JBSWY3DPEHPK3PXP',
        ),
      ];

      final TotpPrintResult result = buildTotpOutput(
        accounts,
        now: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(result.warnings, isEmpty);
      expect(result.output, contains('GitHub  alice@example.com  282760'));
    });

    test('prints ERROR and warning for invalid secret', () {
      final List<Account> accounts = <Account>[
        Account(
          id: '1',
          issuer: 'Broken',
          name: 'alice@example.com',
          secret: '%%%%',
        ),
      ];

      final TotpPrintResult result = buildTotpOutput(
        accounts,
        now: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(result.output, contains('ERROR'));
      expect(result.warnings, hasLength(1));
      expect(
        result.warnings.single.format(),
        'Invalid secret for Broken / alice@example.com.',
      );
    });
  });
}
