import 'package:flutter_test/flutter_test.dart';
import 'package:flauth/services/backup_security_service.dart';

void main() {
  group('BackupSecurityService Tests', () {
    const plainText = 'otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example';
    const password = 'secure-password-123';

    test('Encryption and Decryption should return original text', () {
      final encryptedJson = BackupSecurityService.encrypt(plainText, password);
      
      expect(BackupSecurityService.isEncrypted(encryptedJson), isTrue);
      
      final decrypted = BackupSecurityService.decrypt(encryptedJson, password);
      expect(decrypted, equals(plainText));
    });

    test('Decryption with wrong password should fail', () {
      final encryptedJson = BackupSecurityService.encrypt(plainText, password);
      
      expect(
        () => BackupSecurityService.decrypt(encryptedJson, 'wrong-password'),
        throwsException,
      );
    });

    test('isEncrypted should return false for plain text', () {
      expect(BackupSecurityService.isEncrypted(plainText), isFalse);
      expect(BackupSecurityService.isEncrypted('{"invalid": "json"}'), isFalse);
    });

    test('Decryption of non-encrypted format should fail', () {
      expect(
        () => BackupSecurityService.decrypt('invalid content', password),
        throwsException,
      );
    });
  });
}
