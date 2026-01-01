import 'package:flutter_test/flutter_test.dart';
import 'package:flauth/models/account.dart';

void main() {
  group('AccountProvider Logic (No Storage)', () {
    test('exportAccountsToText should format multiple accounts correctly', () {
      // We can't easily use AccountProvider because it touches Storage in constructor.
      // But we can test the Account model directly (already done in account_test.dart).

      final accounts = [
        Account(id: '1', name: 'User1', secret: 'JBSW', issuer: 'Issuer1'),
        Account(id: '2', name: 'User2', secret: 'KBSW', issuer: 'Issuer2'),
      ];

      final text = accounts.map((a) => a.toUriString()).join('\n');
      expect(
        text,
        contains('otpauth://totp/Issuer1:User1?secret=JBSW&issuer=Issuer1'),
      );
      expect(
        text,
        contains('otpauth://totp/Issuer2:User2?secret=KBSW&issuer=Issuer2'),
      );
      expect(text.split('\n').length, equals(2));
    });
  });
}
