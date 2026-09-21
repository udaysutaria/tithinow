import 'package:flutter/material.dart';
import '../../theme/design_system.dart';

/// Atomic widget representing a Pill Button with active and disabled states.
///
/// Has two visual states:
/// - Active: Solid primary color (`AppColors.primary` #7FC9CE) background with dark text (`AppColors.background` #121414).
/// - Disabled: Subtle surface background (`AppColors.surface`) with outline border and 40% opacity text.
class AppPillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;
  final String text;
  final double? width;

  const AppPillButton({
    super.key,
    this.onPressed,
    this.isEnabled = true,
    required this.text,
    this.width = 364,
  });

  bool get isActive => isEnabled && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      side: isActive
          ? BorderSide.none
          : BorderSide(
              width: 1,
              color: AppColors.outline,
            ),
      borderRadius: AppRadius.border999,
    );

    final decoration = ShapeDecoration(
      color: isActive ? AppColors.primary : AppColors.surface,
      shape: shape,
    );

    final textStyle = AppTypography.bodyStyle(
      fontSize: 16,
      weight: FontWeight.w600,
      color: isActive ? AppColors.background : AppColors.onSurface,
      height: 1.5,
    );

    Widget textWidget = Text(
      text,
      textAlign: TextAlign.center,
      style: textStyle,
    );

    if (!isActive) {
      textWidget = Opacity(
        opacity: 0.40,
        child: textWidget,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? onPressed : null,
        borderRadius: AppRadius.border999,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: decoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              textWidget,
            ],
          ),
        ),
      ),
    );
  }
}
