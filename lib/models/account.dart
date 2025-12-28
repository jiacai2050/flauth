import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Represents a single TOTP account.
/// Stores the essential information needed to generate codes and identify the service.
class Account {
  final String id;
  final String name; // e.g., user@example.com
  final String secret; // The Base32 encoded secret key provided by the service
  final String issuer; // e.g., Google, GitHub

  Account({
    required this.id,
    required this.name,
    required this.secret,
    this.issuer = '',
  });

  // Convert to Map for JSON serialization
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'secret': secret, 'issuer': issuer};
  }

  // Create an Account object from a Map (deserialization)
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      secret: map['secret'] ?? '',
      issuer: map['issuer'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Account.fromJson(String source) =>
      Account.fromMap(json.decode(source));

  /// Converts the account to a standard otpauth URI string.
  /// Format: otpauth://totp/Issuer:Name?secret=SECRET&issuer=Issuer
  String toUriString() {
    final label = issuer.isNotEmpty ? '$issuer:$name' : name;
    final uri = Uri(
      scheme: 'otpauth',
      host: 'totp',
      path: label,
      queryParameters: {
        'secret': secret,
        if (issuer.isNotEmpty) 'issuer': issuer,
      },
    );
    return uri.toString();
  }

  /// Creates an Account from a standard otpauth URI.
  /// Generates a new random ID.
  /// Throws FormatException if URI is invalid.
  factory Account.fromUri(Uri uri) {
    if (uri.scheme != 'otpauth' || uri.host != 'totp') {
      throw const FormatException('Invalid scheme or host');
    }

    final String path = uri.path;
    // The path usually contains the label (Issuer:Account or just Account)
    String name = path.startsWith('/') ? path.substring(1) : path;
    String issuer = '';

    if (name.contains(':')) {
      final parts = name.split(':');
      issuer = parts[0];
      name = parts.sublist(1).join(':');
    }

    final String? secret = uri.queryParameters['secret'];
    final String? queryIssuer = uri.queryParameters['issuer'];

    // Prefer the issuer from query parameters if available
    if (queryIssuer != null && queryIssuer.isNotEmpty) {
      issuer = queryIssuer;
    }

    if (secret == null || secret.isEmpty) {
      throw const FormatException('No secret found in URI');
    }

    return Account(
      id: const Uuid().v4(),
      name: name,
      secret: secret.replaceAll(' ', '').toUpperCase(),
      issuer: issuer,
    );
  }
}
