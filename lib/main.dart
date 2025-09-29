import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart'; // Füge diese Dependency hinzu
import 'package:loginpage/auth/auth_gate.dart';
import 'package:loginpage/pages/splash_screen.dart';
import 'package:loginpage/pages/Registrieren.dart';
import 'package:loginpage/pages/alone_page.dart';
import 'package:loginpage/pages/freunde_page.dart';
import 'package:loginpage/pages/home.dart';
import 'package:loginpage/components/bottom_nav_bar.dart';
import 'package:loginpage/pages/search_page.dart';
import 'package:loginpage/pages/settings_page.dart';
import 'package:loginpage/pages/upload_page.dart';
import 'package:loginpage/theme/dark_mode.dart';
import 'package:loginpage/theme/light_mode.dart';
import 'package:loginpage/theme/theme_provider.dart'; // Neuer Import
import 'pages/login_page.dart';
import 'components/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE');

  await Supabase.initialize(
    url: 'https://qpsnfuhhiesjxdtfyyop.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFwc25mdWhoaWVzanhkdGZ5eW9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzNzEwMzIsImV4cCI6MjA2MTk0NzAzMn0.NETHmdJU3wvAoVvSo9A0oAFMl7DWa4rPqBIakj6hlio',
  );

  runApp(
    // Wrap mit ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyLifecycleManager(),
    ),
  );
}

/// NEU: Kümmert sich um Online/Offline-Status
class MyLifecycleManager extends StatefulWidget {
  const MyLifecycleManager({super.key});

  @override
  State<MyLifecycleManager> createState() => _MyLifecycleManagerState();
}

class _MyLifecycleManagerState extends State<MyLifecycleManager>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnlineStatus(true); // Direkt beim Start online setzen
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnlineStatus(false); // Sicherheitshalber beim Dispose
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.detached) {
      _setOnlineStatus(false);
    }
  }

  Future<void> _setOnlineStatus(bool isOnline) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'is_online': isOnline,
      if (!isOnline) 'last_online': DateTime.now().toUtc(),
    };

    await Supabase.instance.client
        .from('profiles')
        .update(updates)
        .eq('id', user.id);
  }

  @override
  Widget build(BuildContext context) {
    return const MainApp();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          theme: lightMode,
          darkTheme: darkMode,
          themeMode: themeProvider.themeMode, // Dynamisches Theme
          routes: {
            '/auth_gate': (context) => const AuthGate(),
            '/login_register_page': (context) => const LoginPage(),
            '/home_page': (context) => const HomePage(),
            '/settins_page': (context) => const SettingsPage(),
            '/freunde_page': (context) => const MyFriends(),
            '/alone_page': (context) => MyProfile(),
            '/search_page': (context) => const MySearch(),
            '/upload_page': (context) => const MyUpload(),
          },
        );
      },
    );
  }
}