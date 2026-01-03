import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/account_provider.dart';

class AccountTile extends StatefulWidget {
  final Account account;

  const AccountTile({super.key, required this.account});

  @override
  State<AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<AccountTile> {
  bool _isCodeVisible = false;

  @override
  Widget build(BuildContext context) {
    // Optimization: Only rebuild when remainingSeconds changes (once per second)
    final remainingSeconds = context.select<AccountProvider, int>(
      (p) => p.remainingSeconds,
    );
    final provider = Provider.of<AccountProvider>(context, listen: false);
    final code = provider.getCurrentCode(widget.account.secret);

    // Format code for readability (e.g., "123 456")
    final formattedCode = code.length == 6
        ? '${code.substring(0, 3)} ${code.substring(3)}'
        : code;

    // Dismissible allows the user to swipe the tile to delete the account.
    return RepaintBoundary(
      child: Dismissible(
        key: Key(widget.account.id),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Delete Account"),
                content: const Text(
                  "Are you sure you want to delete this account? This cannot be undone.",
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Delete"),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          provider.deleteAccount(widget.account.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.account.name} deleted')),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: InkWell(
            onTap: () {
              setState(() {
                _isCodeVisible = !_isCodeVisible;
              });

              if (_isCodeVisible) {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code revealed and copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.account.issuer.isNotEmpty
                              ? (_isCodeVisible
                                    ? widget.account.issuer
                                    : '${widget.account.issuer} (${widget.account.name})')
                              : widget.account.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isCodeVisible ? Colors.grey[600] : null,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        _isCodeVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 20,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  if (_isCodeVisible) ...[
                    if (widget.account.issuer.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          widget.account.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formattedCode,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Text(
                          '${remainingSeconds}s',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: remainingSeconds < 6
                                    ? Colors.red
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
