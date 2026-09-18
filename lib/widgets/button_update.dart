import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';

/// Atomic widget representing the "Update" action button.
///
/// Has two states:
/// - Active: Solid primary color (`AppColors.primary` #7FC9CE) background with dark text (`AppColors.background` #121414).
/// - Disabled: Subtle surface background (`AppColors.surface`) with outline border and 40% opacity text.
class ButtonUpdate extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;
  final String text;
  final double? width;

  const ButtonUpdate({
    super.key,
    this.onPressed,
    this.isEnabled = true,
    this.text = 'Update',
    this.width = 364,
  });

  bool get _isActive => isEnabled && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      side: _isActive
          ? BorderSide.none
          : BorderSide(
              width: 1,
              color: AppColors.outline,
            ),
      borderRadius: AppRadius.border999,
    );

    final decoration = ShapeDecoration(
      color: _isActive ? AppColors.primary : AppColors.surface,
      shape: shape,
    );

    final textStyle = GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: _isActive ? AppColors.background : AppColors.onSurface,
    );

    Widget textWidget = Text(
      text,
      textAlign: TextAlign.center,
      style: textStyle,
    );

    if (!_isActive) {
      textWidget = Opacity(
        opacity: 0.40,
        child: textWidget,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isActive ? onPressed : null,
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
