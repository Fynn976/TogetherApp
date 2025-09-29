import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loginpage/auth/auth_service.dart';
import 'package:loginpage/components/my_button.dart';
import 'package:loginpage/components/my_textfield.dart';
import 'package:loginpage/components/square_tile.dart';
import 'package:loginpage/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();
  final uniqueusernameController = TextEditingController();

void register() async {
  final email = emailController.text.trim();
  final password = passwordController.text;
  final confirmPassword = confirmPasswordController.text;
  final displayName = usernameController.text.trim();         // Anzeigename
  final uniqueUsername = uniqueusernameController.text.trim(); // Eindeutiger Benutzername

  if (password != confirmPassword) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwörter stimmen nicht überein")),
      );
    }
    return;
  }

  try {
    // Prüfen, ob Benutzername (uniqueUsername) schon existiert
    final existing = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('username', uniqueUsername)
        .maybeSingle();

    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Benutzername bereits vergeben")),
      );
      return;
    }

    // Registrierung bei Supabase Auth mit display_name in den Metadaten
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'display_name': displayName,
      },
    );

    if (response.user == null) {
      throw 'Registrierung fehlgeschlagen.';
    }

    final userId = response.user?.id;

    // Speichere Benutzer in der profiles-Tabelle
    await Supabase.instance.client.from('profiles').upsert({
      'id': userId,
      'username': uniqueUsername,     // eindeutiger Benutzername
      'display_name': displayName,    // frei wählbarer Anzeigename
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registrierung erfolgreich")),
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Fehler: $e")));
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Text(
                  'Tgthr.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 70,
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Lass uns dein Konto erstellen!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),
                MyTextfield(
                  controller: usernameController,
                  hintText: 'Anzeigename',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: uniqueusernameController,
                  hintText: 'Benutzername',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Passwort',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                MyTextfield(
                  controller: confirmPasswordController,
                  hintText: 'Passwort bestätigen',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                
                const SizedBox(height: 25),
                MyButton(
                  onTap: register,
                  text: 'Registrieren',
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color:Theme.of(context).colorScheme.inversePrimary,
                          height: 20,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          'oder weiter mit',
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.grey[400],
                          height: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SquareTile(imagePath: 'lib/images/Google Logo.png'),
                    SizedBox(width: 25),
                    SquareTile(imagePath: 'lib/images/Apple Logo.png'),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hast du bereits ein Konto?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      ),
                      child: const Text(
                        'Anmelden',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
