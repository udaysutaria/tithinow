import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/design_system.dart';

/// Atomic widget representing the Edit Button.
///
/// Has two visual size states:
/// - Default: 48x48 surface container with 24x24 edit icon and 16px corner radius, matching [ButtonAlarm].
/// - Compact (`isCompact: true`): 32x32 surface container with 16x16 edit icon and 8px corner radius.
class ButtonEdit extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isCompact;

  const ButtonEdit({
    super.key,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: AppColors.outline,
              ),
              borderRadius: borderRadius,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: SvgPicture.asset(
                'assets/icons/IconEdit.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: const ColorFilter.mode(
                  AppColors.onSurfaceVariant,
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
