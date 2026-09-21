import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';

export '../../constants/panchang_terms.dart' show AppLanguage;

/// Navigation item model for drawer menu destinations.
class NavMenuItem {
  final String iconAsset;
  final String label;

  const NavMenuItem({
    required this.iconAsset,
    required this.label,
  });
}

/// Menulist component representing the vertical destination list in the drawer.
///
/// Features:
/// - 5 destinations: Today, Tithi, Alarms, Settings, About.
/// - Multilingual support for English, Hindi, and Gujarati via [PanchangLabels].
/// - Dynamically updates with [AppDatabase.instance.languageNotifier] or an explicit [language] override.
/// - Active destination styled with [AppColors.primary] (#7FC9CE).
/// - Inactive destinations styled with [AppColors.onSurfaceVariant] (White).
/// - Each row contains a 24x24 SVG icon and an Inter 16px label.
class Menulist extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<NavMenuItem>? items;
  final AppLanguage? language;

  /// Returns localized navigation menu items based on [AppLanguage].
  static List<NavMenuItem> getItems(AppLanguage lang) => [
    NavMenuItem(
      iconAsset: 'assets/icons/IconHome.svg',
      label: PanchangLabels.navToday(lang),
    ),
    NavMenuItem(
      iconAsset: 'assets/icons/IconMonth.svg',
      label: PanchangLabels.tithi(lang),
    ),
    NavMenuItem(
      iconAsset: 'assets/icons/IconSetAlarm.svg',
      label: PanchangLabels.alarms(lang),
    ),
    NavMenuItem(
      iconAsset: 'assets/icons/IconSettings.svg',
      label: PanchangLabels.settings(lang),
    ),
    NavMenuItem(
      iconAsset: 'assets/icons/IconAbout.svg',
      label: PanchangLabels.about(lang),
    ),
  ];

  static const List<NavMenuItem> defaultMenuItems = [
    NavMenuItem(
      iconAsset: 'assets/icons/IconHome.svg',
      label: 'Today',
    ),
    NavMenuItem(
      iconAsset: 'assets/icons/IconMonth.svg',
      label: 'Tithi',
    ),
    NavMenuItem(
      iconAsset: 'assets/icons/IconSetAlarm.svg',
      label: 'Alarms',
    ),
    NavMenuItem(
      iconAsset: 'assets/icons/IconSettings.svg',
      label: 'Settings',
    ),
    NavMenuItem(
      iconAsset: 'assets/icons/IconAbout.svg',
      label: 'About',
    ),
  ];

  const Menulist({
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.items,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguageNotifier,
      builder: (context, dbLang, _) {
        final effectiveLang = language ?? dbLang;
        final menuItems = items ?? getItems(effectiveLang);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < menuItems.length; i++)
                    _buildMenuItem(
                      context,
                      index: i,
                      item: menuItems[i],
                      isSelected: selectedIndex == i,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required int index,
    required NavMenuItem item,
    required bool isSelected,
  }) {
    final color = isSelected ? AppColors.primary : AppColors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onDestinationSelected?.call(index),
        borderRadius: AppRadius.border8,
        child: Container(
          width: double.infinity,
          height: 48,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing12,
            vertical: AppSpacing.spacing8,
          ),
          decoration: ShapeDecoration(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.border8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  item.iconAsset,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
              Text(
                item.label,
                style: AppTypography.bodyStyle(
                  language: context.appTypography.language,
                  fontSize: 16,
                  weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mobile Navigation Drawer for TithiNow.
///
/// Wraps [Menulist] inside a styled Material [Drawer] container with:
/// - Brand logo header ([MenuBrandIcon.png])
/// - Close button
/// - Background color [AppColors.background]
/// - Outline right border
class NavDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final VoidCallback? onClosePressed;
  final List<NavMenuItem>? items;
  final AppLanguage? language;

  const NavDrawer({
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.onClosePressed,
    this.items,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppRadius.radius24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing24,
            vertical: AppSpacing.spacing16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with brand logo and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/MenuBrandIcon.png',
                    width: 156,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      'TithiNow',
                      style: GoogleFonts.sora(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.onSurface,
                      size: 24,
                    ),
                    tooltip: 'Close Menu',
                    onPressed: onClosePressed ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing16),
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.outline,
              ),
              const SizedBox(height: AppSpacing.spacing8),

              // Menu list
              Expanded(
                child: SingleChildScrollView(
                  child: Menulist(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    items: items,
                    language: language,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compatibility aliases matching Figma export names.
typedef MenuList = Menulist;
typedef DrawerMenu = NavDrawer;
