import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../widgets/molecules/line_loading_bar.dart';

/// SplashView displays the centered splash branding and line loading animation.
/// On desktop (macOS & Windows), it fills the window edge-to-edge with #121414
/// and centers the splash icon, matching the mobile launch experience.
class SplashView extends StatelessWidget {
  final bool showLoadingBar;

  const SplashView({
    super.key,
    this.showLoadingBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    // SplashIcon.png has an 1152x1152 canvas with the visible icon occupying the center.
    // On desktop, 480dp produces a crisp ~160dp visible icon.
    // On mobile, 288dp produces a ~96dp visible icon matching the native mobile splash.
    final double iconBoxSize = isDesktop ? 480.0 : 288.0;
    final double loadingBarWidth = isDesktop ? 220.0 : 160.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: iconBoxSize,
              height: iconBoxSize,
              child: Image.asset(
                'assets/images/SplashIcon.png',
                fit: BoxFit.contain,
                semanticLabel: 'TithiNow Splash Icon',
              ),
            ),
            if (showLoadingBar)
              Transform.translate(
                offset: Offset(0, isDesktop ? -48.0 : -32.0),
                child: LineLoadingBar(
                  width: loadingBarWidth,
                  height: 4.0,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
