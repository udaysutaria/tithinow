import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/design_system.dart';

/// Atomic widget representing the Edit Button.
///
/// Features a compact 16x16 edit icon within an 8px padded surface container
/// with an outline border and 8px corner radius.
class ButtonEdit extends StatelessWidget {
  final VoidCallback? onTap;

  const ButtonEdit({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.border8,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.spacing8),
          decoration: ShapeDecoration(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: 1,
                color: AppColors.outline,
              ),
              borderRadius: AppRadius.border8,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: SvgPicture.asset(
                'assets/icons/IconEdit.svg',
                width: 16,
                height: 16,
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
