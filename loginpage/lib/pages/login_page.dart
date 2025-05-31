import 'package:flutter/material.dart';
import 'package:loginpage/auth/auth_service.dart';
import 'package:loginpage/components/my_button.dart';
import 'package:loginpage/components/my_textfield.dart';
import 'package:loginpage/components/square_tile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loginpage/pages/Registrieren.dart';
import 'package:loginpage/pages/password_reset_page.dart';

class LoginPage extends StatefulWidget {
   const LoginPage({super.key});

   @override
   State<LoginPage> createState() => _LoginPageState();
}

   class _LoginPageState extends State<LoginPage> {
    // get auth service
    final authService = AuthService();



  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  // login button pressed
  void login() async {

    //prepare data
    final email = emailController.text;
    final password = passwordController.text;
    
    // attempt login
    try {
      await authService.signInWithEmailPassword(email, password);
     
   if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erfolgreich eingeloggt!")),
      );
   }
   } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
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
            Text('Willkommen zurück, wir haben dich vermisst!',
            style: TextStyle(
              color:Theme.of(context).colorScheme.inversePrimary,
              fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),
          
            // email textfield
            MyTextfield(
              controller: emailController,
              hintText: 'Email',
              obscureText: false,
            ),

            const SizedBox(height: 10),
          
            // password textfield
            MyTextfield(
              controller: passwordController,
              hintText: 'Passwort',
              obscureText: true,
            ),

            const SizedBox(height: 10),

            // forgot password
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => PasswordResetPage(),
                      )
                    ),
                    child: Text('Passwort vergessen?',
                    style: TextStyle(color:Theme.of(context).colorScheme.inversePrimary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // sign in button
          MyButton(
            onTap: login,
            text: "Einloggen",
          ),

          

          const SizedBox(height: 50),
            // or continue with
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 25.0),
             child: Row(
              children: [
                Expanded(
                  child:  Divider(
                thickness: 0.5,
                color: Theme.of(context).colorScheme.inversePrimary,
                height: 20,
              ),
                ),
             
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 10.0),
                   child: Text(
                    'oder weiter mit',
                    style: TextStyle(color:Theme.of(context).colorScheme.inversePrimary),
                  ),
                 ),
             
                Expanded(
                  child:  Divider(
                thickness: 0.5,
                color:Theme.of(context).colorScheme.inversePrimary,
                height: 20,
              ),
                ),
              ],
             ),
           ),

           const SizedBox(height: 50),
          
            // google + apple button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              // google button
              SquareTile(imagePath: 'lib/images/Google Logo.png'),

               SizedBox(width: 25),

              // apple button
              SquareTile(imagePath: 'lib/images/Apple Logo.png'),
            ],
          ),

          const SizedBox(height: 50),
            // resgister button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Text(
                'Noch kein Konto?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
                fontWeight: FontWeight.bold,)
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => RegisterPage(),
                  )
                ),
                child: const Text(
                  'Jetzt Registrieren',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                ),
              ),
            ],
          )
          
          ]),
        ),
      )
    ),
  );
  }
}