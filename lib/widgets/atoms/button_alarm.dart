import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/design_system.dart';

/// Atomic widget representing the Alarm Toggle Button.
///
/// Has two visual states:
/// - Default (inactive): surface background with primary border, showing `IconSetAlarm.svg`.
/// - Active: filled with primary color, showing `IconRemoveAlarm.svg` tinted dark for contrast.
class ButtonAlarm extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;
  final bool isCompact;

  const ButtonAlarm({
    super.key,
    this.isActive = false,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isActive ? AppColors.primary : AppColors.surface;
    final iconAsset = isActive
        ? 'assets/icons/IconRemoveAlarm.svg'
        : 'assets/icons/IconSetAlarm.svg';
    final iconColor = isActive ? AppColors.background : AppColors.onSurfaceVariant;
    final size = isCompact ? 32.0 : 48.0;
    final iconSize = isCompact ? 16.0 : 24.0;
    final borderRadius = isCompact ? AppRadius.border8 : AppRadius.border16;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          width: size,
          height: size,
          decoration: ShapeDecoration(
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                width: 1,
                color: AppColors.primary,
              ),
              borderRadius: borderRadius,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: SvgPicture.asset(
                iconAsset,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(
                  iconColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
