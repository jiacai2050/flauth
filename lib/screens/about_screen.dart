import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'security_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'dev@liujiacai.net',
      query: 'subject=Flauth Feedback',
    );
    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.hasData
              ? 'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})'
              : 'Loading...';

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Icon(Icons.lock_outline, size: 80, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Flauth',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  version,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'A privacy-first, fully open-source TOTP authenticator for Android, macOS, Windows, and Linux.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Security Settings'),
                subtitle: const Text('Setup PIN & Biometrics'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SecurityScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.person),
                title: Text('Author'),
                subtitle: Text('Jiacai Liu'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('GitHub'),
                subtitle: const Text('github.com/jiacai2050/flauth'),
                onTap: () => _launchUrl('https://github.com/jiacai2050/flauth'),
                trailing: const Icon(Icons.open_in_new, size: 16),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Contact'),
                subtitle: const Text('dev@liujiacai.net'),
                onTap: _launchEmail,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  '© ${DateTime.now().year} Jiacai Liu',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
