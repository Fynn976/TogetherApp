import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loginpage/components/my_backbutton.dart';
import 'package:loginpage/components/bottom_nav_bar.dart';

class MySearch extends StatelessWidget {
  const MySearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea( // Sicherer Bereich, um Notches zu berücksichtigen
        child: Stack(
          children: [
            // Main content of the page
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 25),

                  // Freunde text
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0, top: 50),
                    child: Row(
                      children: [
                        Text(
                          'Finden',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Was machen meine Freunde text
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0),
                    child: Row(
                      children: [
                        Text(
                          'Finde Trainingspartner und Aktivitäten',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // "tgthr." text positioned at the top-right corner
            Positioned(
              top: 20,
              left: 30, // Position it to the right side
              child: Text(
                'tgthr.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
