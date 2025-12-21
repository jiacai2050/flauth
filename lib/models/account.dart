import 'dart:convert';

class Account {
  final String id;
  final String name;
  final String secret;
  final String issuer;

  Account({
    required this.id,
    required this.name,
    required this.secret,
    this.issuer = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'secret': secret,
      'issuer': issuer,
    };
  }

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
