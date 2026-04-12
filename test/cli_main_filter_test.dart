import 'package:flutter_test/flutter_test.dart';
import 'package:flauth/models/account.dart';

import '../cli/account_filter.dart';

void main() {
  group('CLI filter behavior', () {
    test('case-insensitive contains matches issuer or account name', () {
      final List<Account> accounts = <Account>[
        Account(
          id: '1',
          issuer: 'GitHub',
          name: 'alice@example.com',
          secret: 'SECRET1',
        ),
        Account(
          id: '2',
          issuer: 'Google',
          name: 'bob@gmail.com',
          secret: 'SECRET2',
        ),
      ];

      expect(
        filterAccounts(
          accounts,
          'git',
        ).map((account) => account.issuer).toList(),
        <String>['GitHub'],
      );
      expect(
        filterAccounts(accounts, 'BOB').map((account) => account.name).toList(),
        <String>['bob@gmail.com'],
      );
      expect(filterAccounts(accounts, null), accounts);
    });
  });
}
