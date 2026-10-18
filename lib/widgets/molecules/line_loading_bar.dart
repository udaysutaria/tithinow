import 'package:flutter/material.dart';
import '../../theme/design_system.dart';

/// A sleek, indeterminate horizontal loading bar widget with pill-shaped rounded ends.
///
/// Accurately implements the visual styling of `assets/images/Loading bar.svg`,
/// rendering a translucent pill track (20% opacity) and an inner sliding indicator
/// in the design system primary color ([AppColors.primary]).
class LineLoadingBar extends StatefulWidget {
  final double width;
  final double height;
  final Color? color;
  final Duration duration;

  const LineLoadingBar({
    super.key,
    this.width = 160.0,
    this.height = 4.0,
    this.color,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<LineLoadingBar> createState() => _LineLoadingBarState();
}

class _LineLoadingBarState extends State<LineLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.primary;
    final borderRadius = BorderRadius.circular(widget.height);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.2),
          borderRadius: borderRadius,
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _LineLoadingPainter(
                  progress: _controller.value,
                  color: effectiveColor,
                  radius: widget.height / 2.0,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LineLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double radius;

  _LineLoadingPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // The indicator takes ~35% of the total width
    final indicatorWidth = size.width * 0.35;

    // Smooth easeInOut movement across the track with slight over-travel outside bounds
    // to give a clean entrance and exit as seen in Loading bar.svg
    final curvedProgress = Curves.easeInOutCubic.transform(progress);
    final totalTravel = size.width + indicatorWidth * 1.5;
    final startX = -indicatorWidth + (curvedProgress * totalTravel);
    final endX = startX + indicatorWidth;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(startX, 0, endX, size.height),
      Radius.circular(radius),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _LineLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
