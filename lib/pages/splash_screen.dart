import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late List<AnimationController> controllers;
  late List<Animation<double>> opacities;
  late List<Animation<double>> scales;
  AnimationController? zoomController;
  Animation<double>? zoomAnimation;
  bool joined = false;

  final List<String> letters = ['t', 'g', 't', 'h', 'r', '.'];

  @override
  void initState() {
    super.initState();

    controllers = List.generate(letters.length, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    });

    opacities = controllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: controller, curve: Curves.easeIn)))
        .toList();

    scales = controllers
        .map((controller) => Tween<double>(begin: 1.4, end: 1.0)
            .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack)))
        .toList();

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Buchstaben schnell nacheinander einblenden
    for (int i = 0; i < controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      await controllers[i].forward();
    }

    setState(() {
      joined = true;
    });

    // Kurz warten, damit alle Buchstaben sichtbar sind
    await Future.delayed(const Duration(milliseconds: 300));

    // Reinzoom Animation starten
    zoomController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    zoomAnimation = Tween<double>(begin: 1.0, end: 10.0).animate(
      CurvedAnimation(parent: zoomController!, curve: Curves.easeInOut),
    );

    zoomController!.addListener(() {
      setState(() {});
    });

    await zoomController!.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth_gate');
    }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    zoomController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scale = zoomAnimation?.value ?? 1.0;
    // Opacity fällt linear mit dem Reinzoom von 1 auf 0
    final double opacity = 1.0 - ((scale - 1.0) / 9.0).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 500),
          padding: EdgeInsets.symmetric(horizontal: joined ? 0 : 6.0),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(letters.length, (index) {
                  return AnimatedBuilder(
                    animation: controllers[index],
                    builder: (context, child) {
                      return Opacity(
                        opacity: opacities[index].value,
                        child: Transform.scale(
                          scale: scales[index].value,
                          child: Text(
                            letters[index],
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.inversePrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
