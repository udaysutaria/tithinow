import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/design_system.dart';

/// Navigation item data for desktop side navigation.
class NavSideItem {
  final String iconAsset;
  final String label;

  const NavSideItem({
    required this.iconAsset,
    required this.label,
  });
}

/// Atomic/Organism widget representing the Desktop Side Navigation Bar.
///
/// Features:
/// - Fixed width of 54px.
/// - Fills the vertical height of the window with icons centered vertically.
/// - 5 navigation destinations: Home, Month, Alarms, Settings, About.
/// - Active item highlighted with a solid white pill (`AppColors.onSurfaceVariant`)
///   and dark icon (`AppColors.background`).
/// - Inactive items displayed with muted icon color (`AppColors.onSurface`).
class NavSide extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  static const List<NavSideItem> defaultItems = [
    NavSideItem(
      iconAsset: 'assets/icons/IconHome.svg',
      label: 'Home',
    ),
    NavSideItem(
      iconAsset: 'assets/icons/IconMonth.svg',
      label: 'Month',
    ),
    NavSideItem(
      iconAsset: 'assets/icons/IconSetAlarm.svg',
      label: 'Alarms',
    ),
    NavSideItem(
      iconAsset: 'assets/icons/IconSettings.svg',
      label: 'Settings',
    ),
    NavSideItem(
      iconAsset: 'assets/icons/IconAbout.svg',
      label: 'About',
    ),
  ];

  const NavSide({
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (int i = 0; i < defaultItems.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.spacing16),
              _buildNavItem(
                context,
                index: i,
                item: defaultItems[i],
                isSelected: selectedIndex == i,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required NavSideItem item,
    required bool isSelected,
  }) {
    final backgroundColor =
        isSelected ? AppColors.onSurfaceVariant : Colors.transparent;
    final iconColor =
        isSelected ? AppColors.background : AppColors.onSurface;

    return Tooltip(
      message: item.label,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onDestinationSelected?.call(index),
          borderRadius: AppRadius.border999,
          child: Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(10),
            decoration: ShapeDecoration(
              color: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.border999,
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: SvgPicture.asset(
                  item.iconAsset,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    iconColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
