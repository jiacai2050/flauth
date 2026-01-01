import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart' as pc;

/// Provides encryption and decryption services for secure backups.
/// Uses AES-256-CBC with PBKDF2 (HMAC-SHA256) key derivation.
class BackupSecurityService {
  static const int _pbkdf2Iterations = 10000;
  static const int _keyLength = 32; // 256 bits
  static const int _saltLength = 16; // 128 bits
  static const int _ivLength = 16; // 128 bits (AES block size)

  /// Encrypts plain text content with a user-provided password.
  /// Returns a JSON string containing the encrypted data and metadata (salt, iv).
  static String encrypt(String plainText, String password) {
    // 1. Generate random Salt and IV
    final salt = _generateRandomBytes(_saltLength);
    final iv = _generateRandomBytes(_ivLength);

    // 2. Derive Key using PBKDF2
    final keyBytes = _deriveKey(password, salt);
    final key = Key(keyBytes);
    final ivObj = IV(iv);

    // 3. Encrypt using AES-256-CBC
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: ivObj);

    // 4. Construct JSON container
    final Map<String, dynamic> container = {
      'version': 1,
      'kdf': {
        'algorithm': 'pbkdf2',
        'iterations': _pbkdf2Iterations,
        'salt': base64Encode(salt),
      },
      'encryption': {
        'algorithm': 'aes-256-cbc',
        'iv': base64Encode(iv),
        'data': encrypted.base64,
      },
    };

    return jsonEncode(container);
  }

  /// Decrypts a JSON-formatted backup string using the user-provided password.
  /// Throws an exception if the password is incorrect or format is invalid.
  static String decrypt(String jsonString, String password) {
    try {
      final Map<String, dynamic> container = jsonDecode(jsonString);
      
      // Basic validation
      if (!container.containsKey('encryption') || !container.containsKey('kdf')) {
        throw const FormatException('Invalid backup format');
      }

      final kdf = container['kdf'];
      final enc = container['encryption'];

      // Extract metadata
      final salt = base64Decode(kdf['salt']);
      final ivBytes = base64Decode(enc['iv']);
      final encryptedData = enc['data'];
      final iterations = kdf['iterations'] as int? ?? _pbkdf2Iterations;

      // 1. Re-derive Key
      final keyBytes = _deriveKey(password, salt, iterations: iterations);
      final key = Key(keyBytes);
      final iv = IV(ivBytes);

      // 2. Decrypt
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final decrypted = encrypter.decrypt64(encryptedData, iv: iv);

      return decrypted;
    } catch (e) {
      // Preserve format-related errors (e.g., invalid JSON / backup structure)
      if (e is FormatException) {
        rethrow;
      }
      // For all other failures, surface a user-friendly message for likely
      // invalid password or corrupted ciphertext.
      throw Exception('Decryption failed: Invalid password or corrupted file.');
    }
  }

  /// Checks if the given string is likely an encrypted JSON backup.
  static bool isEncrypted(String content) {
    try {
      final trimmed = content.trim();
      if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
        return false;
      }
      final Map<String, dynamic> data = jsonDecode(trimmed);
      return data.containsKey('encryption') && data.containsKey('kdf');
    } catch (_) {
      return false;
    }
  }

  // --- Helper Methods ---

  static Uint8List _generateRandomBytes(int length) {
    final rnd = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = rnd.nextInt(256);
    }
    return bytes;
  }

  static Uint8List _deriveKey(
    String password,
    Uint8List salt, {
    int iterations = _pbkdf2Iterations,
  }) {
    // PBKDF2 with HMAC-SHA256
    final derivator = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
    final params = pc.Pbkdf2Parameters(salt, iterations, _keyLength);
    
    derivator.init(params);
    return derivator.process(utf8.encode(password));
  }
}
