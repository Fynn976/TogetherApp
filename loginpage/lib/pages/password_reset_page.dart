import 'package:flutter/material.dart';
import 'package:loginpage/components/my_button.dart';
import 'package:loginpage/components/my_textfield.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});



  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final emailCoontroller = TextEditingController();

  // reset password function
  void resetPassword() async {
    final email =emailCoontroller.text.trim();

    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bitte geben Sie eine E-Mail-Adresse ein")),
        );
      }
      return;
    }
    try {
      // Fordere ein Passwort-Zurücksetzten mit Supabase an
      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      // Erfolgsmeldung
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("E-Mail zum Zurücksetzen des Passworts gesendet")),
        );
      }

      // Erfolgsmeldung
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("E-Mail zum Zurücksetzen des Passworts gesendet")),
        );
      }

      // Zurück zur Login-Seite
      Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children:  [
               const SizedBox(height: 50),
            
            // logo
            Text('Tgthr.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 70,
              fontFamily: GoogleFonts.montserrat().fontFamily,
              fontWeight: FontWeight.w900,
              ),
            ), 

              const SizedBox(height: 50),

            // welcome back
            Text('Lass uns dein Passwort zurücksetzen!',
            style: TextStyle(
              color:Theme.of(context).colorScheme.inversePrimary,
              fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

             MyTextfield(
              controller: emailCoontroller,
              hintText: 'Email',
              obscureText: false,
            ),

            const SizedBox(height: 10),

                        // sign in button
          MyButton(
            onTap: resetPassword,
            text: "Passwort zurücksetzen",
          ),

            const SizedBox(height: 25),

            // back to login page
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Doch nicht? Zurück zur ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Anmeldung',
                    style: TextStyle(
                      color:Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
      ),
      
    );
        
  }
}