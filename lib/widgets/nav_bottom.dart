import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';

/// Navigation destination data for bottom navigation.
class NavBottomItem {
  final String iconAsset;
  final String label;

  const NavBottomItem({
    required this.iconAsset,
    required this.label,
  });
}

/// Atomic/Organism widget representing the Material 3 Mobile Bottom Navigation Bar.
///
/// Features:
/// - 3 tabs: "Today" ([IconHome.svg]), "Tithi" ([IconMonth.svg]), and "Alarms" ([IconSetAlarm.svg]).
/// - Uses Material 3 [NavigationBar] styled with TithiNow design tokens.
/// - Active destination features a primary pill indicator with high-contrast icon.
/// - Automatically collapses to [SizedBox.shrink] on desktop screens (`context.isDesktop`),
///   unless [ignoreDesktopCheck] is set to true for previews.
class NavBottom extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final bool ignoreDesktopCheck;

  static const List<NavBottomItem> defaultItems = [
    NavBottomItem(
      iconAsset: 'assets/icons/IconHome.svg',
      label: 'Today',
    ),
    NavBottomItem(
      iconAsset: 'assets/icons/IconMonth.svg',
      label: 'Tithi',
    ),
    NavBottomItem(
      iconAsset: 'assets/icons/IconSetAlarm.svg',
      label: 'Alarms',
    ),
  ];

  const NavBottom({
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.ignoreDesktopCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!ignoreDesktopCheck && context.isDesktop) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.outline,
            width: 0.5,
          ),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.primary,
          elevation: 0,
          height: 72,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (Set<WidgetState> states) {
              final isSelected = states.contains(WidgetState.selected);
              return GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.onSurfaceVariant
                    : AppColors.onSurface,
              );
            },
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (int i = 0; i < defaultItems.length; i++)
              NavigationDestination(
                icon: SvgPicture.asset(
                  defaultItems[i].iconAsset,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppColors.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  defaultItems[i].iconAsset,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppColors.background,
                    BlendMode.srcIn,
                  ),
                ),
                label: defaultItems[i].label,
                tooltip: defaultItems[i].label,
              ),
          ],
        ),
      ),
    );
  }
}
