import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loginpage/components/my_backbutton.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,

          body: Center(
            child: Column(
              children: [
               // back button
              const Padding(
                 padding: const EdgeInsets.only(
                  top: 50.0,
                  left: 20.0,
                  ),
                 child: Row(
                   children: [
                     CustomBackButton()
                   ],
                 ),
               ),



                  // Freunde text
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0, top: 50),
                    child: Row(
                      children: [
                        Text(
                          'Einstellungen',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
              ]
            ),
          ),
        );
  }
}
                 
            