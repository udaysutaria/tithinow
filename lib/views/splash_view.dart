import 'package:flutter/material.dart';
import 'package:tithinow/theme/design_system.dart';

/// SplashView displays the centered splash branding.
/// On desktop (macOS & Windows), it fills the window edge-to-edge with #121414
/// and centers the splash icon, matching the mobile launch experience.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    // SplashIcon.png has an 1152x1152 canvas with the visible icon occupying the center.
    // On desktop, 480dp produces a crisp ~160dp visible icon.
    // On mobile, 288dp produces a ~96dp visible icon matching the native mobile splash.
    final double iconBoxSize = isDesktop ? 480.0 : 288.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: iconBoxSize,
          height: iconBoxSize,
          child: Image.asset(
            'assets/images/SplashIcon.png',
            fit: BoxFit.contain,
            semanticLabel: 'TithiNow Splash Icon',
          ),
        ),
      ),
    );
  }
}
