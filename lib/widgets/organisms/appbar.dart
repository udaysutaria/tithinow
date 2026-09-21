import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/design_system.dart';

/// Unified responsive AppBar for TithiNow.
///
/// Adapts automatically between Mobile (< 768px) and Desktop (>= 768px):
/// - **Mobile**: 64px surface bar with drawer menu or back button, and 22px Sora title.
/// - **Desktop**: Spacious header with 32px Sora title and an optional pill-shaped
///   'Back' button with icon and text.
class Appbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;

  const Appbar({
    super.key,
    this.title = 'Today',
    this.showBackButton = false,
    this.onBackPressed,
    this.onMenuPressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return _buildDesktopAppBar(context);
    }
    return _buildMobileAppBar(context);
  }

  // Mobile Layout (< 768px)
  Widget _buildMobileAppBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Conditional Leading Button: Back or Menu
          _buildMobileLeadingButton(context),
          const SizedBox(width: AppSpacing.spacing8),

          // Title
          Expanded(
            child: Text(
              title,
              style: context.appTypography.h3(
                weight: AppTypography.semiBold,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),

          // Optional trailing actions
          ...?actions,
        ],
      ),
    );
  }

  Widget _buildMobileLeadingButton(BuildContext context) {
    final iconAsset = showBackButton
        ? 'assets/icons/IconArrowBack.svg'
        : 'assets/icons/IconMenu.svg';

    final onTap = showBackButton
        ? (onBackPressed ?? () => Navigator.maybePop(context))
        : (onMenuPressed ?? () => Scaffold.maybeOf(context)?.openDrawer());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.border8,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Desktop Layout (>= 768px)
  Widget _buildDesktopAppBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing24,
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton) ...[
            _buildDesktopBackButton(context),
            const SizedBox(width: AppSpacing.spacing24),
          ],
          Text(
            title,
            style: context.appTypography.h2(
              weight: AppTypography.semiBold,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          ...?actions,
        ],
      ),
    );
  }

  Widget _buildDesktopBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBackPressed ?? () => Navigator.maybePop(context),
        borderRadius: AppRadius.border999,
        child: Container(
          padding: const EdgeInsets.only(
            top: 8,
            left: 8,
            right: 20,
            bottom: 8,
          ),
          decoration: ShapeDecoration(
            color: AppColors.surface,
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
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  'assets/icons/IconArrowBack.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    AppColors.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Back',
                style: context.appTypography.bodySM(
                  weight: AppTypography.semiBold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
