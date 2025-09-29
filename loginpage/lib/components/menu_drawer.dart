import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loginpage/auth/auth_service.dart';
import 'package:loginpage/pages/alone_page.dart';
import 'package:loginpage/pages/freunde_page.dart';
import 'package:loginpage/pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  MyDrawer({super.key});

  final AuthService authService = AuthService();

  Future<void> logout() async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              // logo
              DrawerHeader(
                child: Center(
                  child: Text(
                    'Tgthr.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 40,
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),

              // settings list title
              Padding(
                padding: const EdgeInsets.only(left: 25.0),
                child: ListTile(
                  title: Text('E I N S T E L L U N G E N'),
                  leading: Icon(Icons.settings),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                ),
              ),

      
            ],
          ),
          // logout list title
          Padding(
            padding: const EdgeInsets.only(left: 25.0, bottom: 25.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: logout,
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text(
                      'A U S L O G G E N',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
