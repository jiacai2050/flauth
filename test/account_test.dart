import 'package:flutter_test/flutter_test.dart';
import 'package:flauth/models/account.dart';

void main() {
  group('Account Model', () {
    test('should convert to Map and back', () {
      final account = Account(
        id: '123',
        name: 'Test',
        secret: 'SECRET',
        issuer: 'Issuer',
      );

      final map = account.toMap();
      final fromMap = Account.fromMap(map);

      expect(fromMap.id, account.id);
      expect(fromMap.name, account.name);
      expect(fromMap.secret, account.secret);
      expect(fromMap.issuer, account.issuer);
    });

    test('should convert to JSON and back', () {
      final account = Account(
        id: '123',
        name: 'Test',
        secret: 'SECRET',
        issuer: 'Issuer',
      );

      final jsonStr = account.toJson();
      final fromJson = Account.fromJson(jsonStr);

      expect(fromJson.id, account.id);
      expect(fromJson.name, account.name);
      expect(fromJson.secret, account.secret);
      expect(fromJson.issuer, account.issuer);
    });

    test('should generate valid otpauth URI', () {
      final account = Account(
        id: '1',
        name: 'alice@google.com',
        secret: 'JBSWY3DPEHPK3PXP',
        issuer: 'Google',
      );

      final uri = account.toUriString();
      // Should handle special characters in label if needed, but basic check here:
      expect(uri, contains('otpauth://totp/Google:alice@google.com'));
      expect(uri, contains('secret=JBSWY3DPEHPK3PXP'));
      expect(uri, contains('issuer=Google'));
    });

    test('should parse valid otpauth URI', () {
      final uriStr = 'otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example';
      final uri = Uri.parse(uriStr);
      
      final account = Account.fromUri(uri);
      
      expect(account.name, 'alice@google.com');
      expect(account.secret, 'JBSWY3DPEHPK3PXP');
      expect(account.issuer, 'Example');
      expect(account.id, isNotEmpty); // ID should be generated
    });
    
    test('should parse URI without issuer prefix in label', () {
      final uriStr = 'otpauth://totp/alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Google';
      final uri = Uri.parse(uriStr);
      
      final account = Account.fromUri(uri);
      
      expect(account.name, 'alice@google.com');
      expect(account.issuer, 'Google');
    });

    test('fromUri should throw on invalid scheme', () {
      final uri = Uri.parse('http://google.com');
      expect(() => Account.fromUri(uri), throwsFormatException);
    });

    test('fromUri should throw on missing secret', () {
       final uri = Uri.parse('otpauth://totp/Test?issuer=Test');
       expect(() => Account.fromUri(uri), throwsFormatException);
    });
  });
}
