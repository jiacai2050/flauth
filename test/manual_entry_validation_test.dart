import 'package:flutter_test/flutter_test.dart';
import 'package:flauth/screens/manual_entry_screen.dart';

void main() {
  group('isValidBase32', () {
    test('accepts valid Base32 strings', () {
      expect(isValidBase32('JBSWY3DPEHPK3PXP'), true);
      expect(isValidBase32('ABCDEFGHIJKLMNOP'), true);
      expect(isValidBase32('MFRA===='), true);
      expect(isValidBase32('AB234567'), true);
    });

    test('accepts strings with spaces (stripped before check)', () {
      expect(isValidBase32('JBSW Y3DP EHPK 3PXP'), true);
    });

    test('accepts lowercase (uppercased before check)', () {
      expect(isValidBase32('jbswy3dpehpk3pxp'), true);
    });

    test('rejects empty string', () {
      expect(isValidBase32(''), false);
      expect(isValidBase32('   '), false);
    });

    test('rejects invalid characters', () {
      expect(isValidBase32('JBSWY3DP!'), false);
      expect(isValidBase32('01489'), false);
    });

    test('rejects strings with only invalid chars', () {
      expect(isValidBase32('!!!'), false);
      expect(isValidBase32('189'), false);
    });
  });
}
