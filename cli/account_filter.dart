import 'package:flauth/models/account.dart';

List<Account> filterAccounts(List<Account> accounts, String? filter) {
  if (filter == null) {
    return accounts;
  }

  final String normalizedFilter = filter.toLowerCase();
  return accounts.where((Account account) {
    final String issuer = account.issuer.toLowerCase();
    final String name = account.name.toLowerCase();
    return issuer.contains(normalizedFilter) || name.contains(normalizedFilter);
  }).toList();
}
