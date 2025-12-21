import 'dart:convert';

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
    return {
      'id': id,
      'name': name,
      'secret': secret,
      'issuer': issuer,
    };
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
}