import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(); // Zum vorherigen Bildschirm zurückkehren
      },
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          Icons.arrow_back,
          size: 24, // Größe des Pfeils
          color: Theme.of(context).colorScheme.inversePrimary, // Farbe aus dem Theme
        ),
      ),
    );
  }
}
