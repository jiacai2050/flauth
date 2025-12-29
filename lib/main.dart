import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/account_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() {
  // Required because we use plugins (like secure_storage) before runApp might finish initializing bindings.
  // It ensures the Flutter engine and native channels are ready.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider allows us to inject the AccountProvider at the top of the widget tree.
    // This makes the account state accessible from anywhere in the app.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Flauth',
        // debugShowCheckedModeBanner: false,
        // Define a consistent theme for the app, supporting both light and dark modes.
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.authenticated) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
