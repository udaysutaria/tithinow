import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';

/// Atomic widget representing the "Today" jump/filter button.
///
/// Has two states:
/// - Active (selected): Solid white background (`AppColors.onSurfaceVariant`) with dark text (`AppColors.background`).
/// - Inactive / Default: Translucent surface background (`AppColors.surface`) with muted text (`AppColors.onSurface`).
class ButtonToday extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isSelected;
  final String text;

  const ButtonToday({
    super.key,
    this.onTap,
    this.isSelected = false,
    this.text = 'Today',
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isSelected ? AppColors.onSurfaceVariant : AppColors.surface;
    final textColor =
        isSelected ? AppColors.background : AppColors.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.border999,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: ShapeDecoration(
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: AppColors.outline,
              ),
              borderRadius: AppRadius.border999,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                text,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
