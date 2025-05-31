import 'package:flutter/material.dart';
import 'package:loginpage/auth/auth_gate.dart';

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
import 'pages/login_page.dart';
import 'components/bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  // supabase setup
  await Supabase.initialize(
    url: 'https://qpsnfuhhiesjxdtfyyop.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFwc25mdWhoaWVzanhkdGZ5eW9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDYzNzEwMzIsImV4cCI6MjA2MTk0NzAzMn0.NETHmdJU3wvAoVvSo9A0oAFMl7DWa4rPqBIakj6hlio',
  );


  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
      theme: lightMode,
      darkTheme: darkMode,
      routes: {
        '/login_register_page': (context) => const LoginPage(),
        '/home_page': (context) => const HomePage(),
        '/settins_page': (context) => const SettingsPage(),
        '/freunde_page': (context) => const MyFriends(),
        '/alone_page': (context) =>  MyProfile(),
        '/search_page': (context) => const MySearch(),
        '/upload_page': (context) => const MyUpload(),
      },
    );
  }
}


