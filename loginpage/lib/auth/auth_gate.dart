import 'package:flutter/material.dart';

import 'package:loginpage/components/bottom_nav_bar.dart';
import 'package:loginpage/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      // Listen to the auth state changes
      stream: Supabase.instance.client.auth.onAuthStateChange, 
      
      // Build the appropriate page based on the auth state
      builder: (context, snapshot) {
        // loading...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }


        //check if there is a valid session currently
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User is logged in, navigate to the home page
          return const BottomNavigationBarWidget();
        } else {
          // User is not logged in, navigate to the login page
          return const LoginPage();
        }

      },
     );
  }
}