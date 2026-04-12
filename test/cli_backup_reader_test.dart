import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flauth/services/backup_security_service.dart';

import '../cli/backup_reader.dart';

void main() {
  group('CLI backup reader', () {
    test('reads backup file from environment variable', () {
      final String path = resolveBackupFilePath(
        environment: <String, String>{backupFileEnvVar: 'env.flauth'},
      );

      expect(path, 'env.flauth');
    });

    test('throws when backup file is missing', () {
      expect(
        () => resolveBackupFilePath(environment: const <String, String>{}),
        throwsFormatException,
      );
    });

    test('resolves optional filter argument', () {
      expect(resolveFilter(<String>['Git']), 'Git');
      expect(resolveFilter(const <String>[]), isNull);
    });

    test('throws when more than one filter argument is provided', () {
      expect(
        () => resolveFilter(<String>['Git', 'Hub']),
        throwsFormatException,
      );
    });

    test('parses plain backup text and reports invalid lines as warnings', () {
      const String text = '''
otpauth://totp/GitHub:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub
not-a-valid-uri
otpauth://totp/Google:bob@gmail.com?secret=JBSWY3DPEHPK3PXP&issuer=Google
''';

      final ParseAccountsResult result = parseAccountsFromText(text);

      expect(result.accounts, hasLength(2));
      expect(result.accounts.first.issuer, 'GitHub');
      expect(result.accounts.last.name, 'bob@gmail.com');
      expect(result.warnings, hasLength(1));
      expect(result.warnings.single.lineNumber, 2);
    });

    test(
      'reads encrypted backup file using password environment variable',
      () async {
        final Directory tempDir = await Directory.systemTemp.createTemp(
          'flauth-cli-test',
        );
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final File backupFile = File('${tempDir.path}/backup.flauth');
        const String plainText =
            'otpauth://totp/GitHub:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub';
        const String password = 'secure-password-123';
        await backupFile.writeAsString(
          BackupSecurityService.encrypt(plainText, password),
        );

        final BackupReadResult result = await readBackupAccounts(
          environment: <String, String>{
            backupFileEnvVar: backupFile.path,
            backupPasswordEnvVar: password,
          },
        );

        expect(result.backupFilePath, backupFile.path);
        expect(result.accounts, hasLength(1));
        expect(result.accounts.single.issuer, 'GitHub');
      },
    );

    test('throws when encrypted backup password is missing', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'flauth-cli-test',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final File backupFile = File('${tempDir.path}/backup.flauth');
      const String plainText =
          'otpauth://totp/GitHub:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub';
      await backupFile.writeAsString(
        BackupSecurityService.encrypt(plainText, 'secure-password-123'),
      );

      expect(
        () => readBackupAccounts(
          environment: <String, String>{backupFileEnvVar: backupFile.path},
        ),
        throwsFormatException,
      );
    });
  });
}
