import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            Image.asset('assets/images/logo.png'),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              top: 190,
              child: Text(
                'LEARN WITHOUT LIMITS...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  letterSpacing: 3,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              top: 230,
              child: LoadingAnimationWidget.dotsTriangle(color: Theme.of(context).colorScheme.primary, size: 25)),
          ],
        ),
      ),
    );
  }
}
