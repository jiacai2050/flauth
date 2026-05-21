import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/account_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';

void main() {
  debugPrint('=== APP STARTED ===');
  // Required because we use plugins (like secure_storage) before runApp might finish initializing bindings.
  // It ensures the Flutter engine and native channels are ready.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    const snackBarTheme = SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    );
    const pageTransitionsTheme = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    );

    // MultiProvider allows us to inject the AccountProvider at the top of the widget tree.
    // This makes the account state accessible from anywhere in the app.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Flauth',
        navigatorKey: navigatorKey,
        // debugShowCheckedModeBanner: false,
        // Define a consistent theme for the app, supporting both light and dark modes.
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          snackBarTheme: snackBarTheme,
          pageTransitionsTheme: pageTransitionsTheme,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          snackBarTheme: snackBarTheme,
          pageTransitionsTheme: pageTransitionsTheme,
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth = Provider.of<AuthProvider>(context, listen: false);
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onAuthChanged() {
    if (_auth.status == AuthStatus.unauthenticated) {
      final navigator = MyApp.navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App entered background: record timestamp
      _auth.markBackground();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground: check if we should lock
      _auth.checkLock(timeoutSeconds: 30); // 30 seconds grace period
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.status == AuthStatus.unknown) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (auth.status == AuthStatus.authenticated) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
