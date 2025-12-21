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
  });
}
