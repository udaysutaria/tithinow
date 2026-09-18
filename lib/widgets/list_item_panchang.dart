import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';

/// Layout behavior modes for [ListItemPanchang].
enum PanchangLayoutMode {
  /// Automatically decides layout:
  /// - Mobile (!context.isDesktop): 2-slide slider (2x2 grid each + dot indicators).
  /// - Desktop (context.isDesktop): Responsive grid (2x4 if width < 1024px, 4x2 if width >= 1024px).
  auto,

  /// Mobile slider with 2 slides:
  /// - Slide 1: Nakshatras, Month, Vrat, Festival (2x2)
  /// - Slide 2: Sunrise, Sunset, Moonrise, Moonset (2x2)
  /// Includes dot pagination indicator.
  mobileSlider,

  /// Desktop responsive grid:
  /// - 2 columns x 4 rows if screen width < 1024px
  /// - 4 columns x 2 rows if screen width >= 1024px
  desktopResponsive,

  /// Fixed 2 columns x 4 rows grid.
  desktopGrid2x4,

  /// Fixed 4 columns x 2 rows grid.
  desktopGrid4x2,
}

/// Data model encapsulating the 8 Panchang items.
class PanchangData {
  final String nakshatra;
  final String month;
  final String? vrat;
  final String? festival;
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;

  // Localized/customizable labels
  final String labelNakshatra;
  final String labelMonth;
  final String labelVrat;
  final String labelFestival;
  final String labelSunrise;
  final String labelSunset;
  final String labelMoonrise;
  final String labelMoonset;

  const PanchangData({
    this.nakshatra = 'Dhanishtha',
    this.month = 'Bhadrapada',
    this.vrat = 'No Vrat',
    this.festival = 'No Festival',
    this.sunrise = '06:27 AM',
    this.sunset = '06:33 PM',
    this.moonrise = '05:08 PM',
    this.moonset = '04:56 AM',
    this.labelNakshatra = 'Nakshatras',
    this.labelMonth = 'Month',
    this.labelVrat = 'Vrat',
    this.labelFestival = 'Festival',
    this.labelSunrise = 'Sunrise',
    this.labelSunset = 'Sunset',
    this.labelMoonrise = 'Moonrise',
    this.labelMoonset = 'Moonset',
  });

  /// Check if a conditional field (Vrat or Festival) has an empty or "No ..." value.
  static bool isInactive(String? value) {
    if (value == null) return true;
    final trimmed = value.trim().toLowerCase();
    return trimmed.isEmpty ||
        trimmed == 'no vrat' ||
        trimmed == 'no festival' ||
        trimmed == 'none' ||
        trimmed == 'n/a' ||
        trimmed == '-';
  }

  /// Slide 1 items: Nakshatras, Month, Vrat, Festival.
  List<PanchangSubItemData> get slide1Items => [
        PanchangSubItemData(
          iconAsset: 'assets/icons/IconNakshatra.svg',
          label: labelNakshatra,
          value: nakshatra,
          isConditional: false,
        ),
        PanchangSubItemData(
          iconAsset: 'assets/icons/IconMonth.svg',
          label: labelMonth,
          value: month,
          isConditional: false,
        ),
        PanchangSubItemData(
          iconAsset: 'assets/icons/IconVrat.svg',
          label: labelVrat,
          value: vrat ?? 'No Vrat',
          isConditional: true,
          isInactive: isInactive(vrat),
        ),
        PanchangSubItemData(
          iconAsset: 'assets/icons/IconFestival.svg',
          label: labelFestival,
          value: festival ?? 'No Festival',
          isConditional: true,
          isInactive: isInactive(festival),
        ),
      ];

  /// Slide 2 items: Sunrise, Sunset, Moonrise, Moonset.
  List<PanchangSubItemData> get slide2Items => [
        PanchangSubItemData(
          iconAsset: 'assets/icons/IconSun.svg',
          label: labelSunrise,
          value: sunrise,
          isConditional: false,
        ),
        PanchangSubItemData(
          iconAsset: 'assets/icons/IconSun.svg',
          label: labelSunset,
          value: sunset,
          isConditional: false,
        ),
        PanchangSubItemData(
          iconAsset: 'assets/icons/IconMoon.svg',
          label: labelMoonrise,
          value: moonrise,
          isConditional: false,
        ),
        PanchangSubItemData(
          iconAsset: 'assets/icons/IconMoon.svg',
          label: labelMoonset,
          value: moonset,
          isConditional: false,
        ),
      ];

  /// All 8 items in sequence.
  List<PanchangSubItemData> get allItems => [...slide1Items, ...slide2Items];
}

/// Model for an individual sub-item card.
class PanchangSubItemData {
  final String iconAsset;
  final String label;
  final String value;
  final bool isConditional;
  final bool isInactive;

  const PanchangSubItemData({
    required this.iconAsset,
    required this.label,
    required this.value,
    this.isConditional = false,
    this.isInactive = false,
  });
}

/// Reusable Panchang composite widget.
///
/// Features:
/// - Supports 8 standard Vedic Panchang items.
/// - **Mobile**: 2-slide swipeable slider (each slide is a 2x2 grid) with dot indicators.
/// - **Desktop**: Grid layout (responsive 2x4 < 1024px, 4x2 >= 1024px, or fixed 2x4).
/// - **Conditional Formatting**:
///   - "No Vrat" / "No Festival" rendered in [AppColors.onSurface] (#BAC9CB).
///   - Active Vrat / Festival and all other 6 items rendered in [AppColors.onSurfaceVariant] (White).
class ListItemPanchang extends StatefulWidget {
  final PanchangData data;
  final PanchangLayoutMode mode;
  final double spacing;
  final double sliderHeight;
  final ValueChanged<int>? onPageChanged;

  const ListItemPanchang({
    super.key,
    this.data = const PanchangData(),
    this.mode = PanchangLayoutMode.auto,
    this.spacing = AppSpacing.spacing8,
    this.sliderHeight = 180.0,
    this.onPageChanged,
  });

  /// Shorthand constructor with individual parameter overrides.
  factory ListItemPanchang.values({
    Key? key,
    String nakshatra = 'Dhanishtha',
    String month = 'Bhadrapada',
    String? vrat,
    String? festival,
    String sunrise = '06:27 AM',
    String sunset = '06:33 PM',
    String moonrise = '05:08 PM',
    String moonset = '04:56 AM',
    PanchangLayoutMode mode = PanchangLayoutMode.auto,
    double spacing = AppSpacing.spacing8,
    double sliderHeight = 180.0,
    ValueChanged<int>? onPageChanged,
  }) {
    return ListItemPanchang(
      key: key,
      data: PanchangData(
        nakshatra: nakshatra,
        month: month,
        vrat: vrat ?? 'No Vrat',
        festival: festival ?? 'No Festival',
        sunrise: sunrise,
        sunset: sunset,
        moonrise: moonrise,
        moonset: moonset,
      ),
      mode: mode,
      spacing: spacing,
      sliderHeight: sliderHeight,
      onPageChanged: onPageChanged,
    );
  }

  @override
  State<ListItemPanchang> createState() => _ListItemPanchangState();
}

/// Compatibility aliases matching Figma export names.
typedef Panchangitem = ListItemPanchang;
typedef PanchangItem = ListItemPanchang;

class _ListItemPanchangState extends State<ListItemPanchang> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMode = _resolveLayoutMode(context);

    switch (effectiveMode) {
      case PanchangLayoutMode.mobileSlider:
        return _buildMobileSlider(context);
      case PanchangLayoutMode.desktopGrid4x2:
        return _buildGrid4x2(context);
      case PanchangLayoutMode.desktopGrid2x4:
        return _buildGrid2x4(context);
      case PanchangLayoutMode.desktopResponsive:
        final bool isWide = MediaQuery.sizeOf(context).width >= 1024;
        return isWide ? _buildGrid4x2(context) : _buildGrid2x4(context);
      case PanchangLayoutMode.auto:
        // Already resolved in _resolveLayoutMode
        return _buildMobileSlider(context);
    }
  }

  PanchangLayoutMode _resolveLayoutMode(BuildContext context) {
    if (widget.mode != PanchangLayoutMode.auto) {
      return widget.mode;
    }
    // Auto-detect based on context.isDesktop
    if (!context.isDesktop) {
      return PanchangLayoutMode.mobileSlider;
    }
    return PanchangLayoutMode.desktopResponsive;
  }

  // ===========================================================================
  // Mobile Slider Layout (2 slides, 2x2 grid each, dot indicator)
  // ===========================================================================
  Widget _buildMobileSlider(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: widget.sliderHeight,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              widget.onPageChanged?.call(index);
            },
            children: [
              _build2x2Grid(widget.data.slide1Items),
              _build2x2Grid(widget.data.slide2Items),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        _buildDotIndicator(),
      ],
    );
  }

  Widget _build2x2Grid(List<PanchangSubItemData> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: PanchangSubItemCard(item: items[0])),
              SizedBox(width: widget.spacing),
              Expanded(child: PanchangSubItemCard(item: items[1])),
            ],
          ),
        ),
        SizedBox(height: widget.spacing),
        Expanded(
          child: Row(
            children: [
              Expanded(child: PanchangSubItemCard(item: items[2])),
              SizedBox(width: widget.spacing),
              Expanded(child: PanchangSubItemCard(item: items[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (index) {
        final bool isActive = _currentPage == index;
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
            width: isActive ? 20.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.outline,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        );
      }),
    );
  }

  // ===========================================================================
  // Desktop Grid Layouts (Static, No Slider)
  // ===========================================================================

  /// 4 columns across x 2 rows down (Desktop >= 1024px in View 1).
  Widget _buildGrid4x2(BuildContext context) {
    final all = widget.data.allItems;
    final row1 = all.sublist(0, 4);
    final row2 = all.sublist(4, 8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(row1),
        SizedBox(height: widget.spacing),
        _buildRow(row2),
      ],
    );
  }

  /// 2 columns across x 4 rows down (Desktop < 1024px in View 1, & Desktop View 2).
  Widget _buildGrid2x4(BuildContext context) {
    final all = widget.data.allItems;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < all.length; i += 2) ...[
          if (i > 0) SizedBox(height: widget.spacing),
          _buildRow([all[i], all[i + 1]]),
        ],
      ],
    );
  }

  Widget _buildRow(List<PanchangSubItemData> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: widget.spacing),
          Expanded(child: PanchangSubItemCard(item: items[i])),
        ],
      ],
    );
  }
}

/// Single atomic card representing one Panchang sub-item.
///
/// Follows Figma specs:
/// - Background: [AppColors.surface] (5% white fill)
/// - Border: 1px [AppColors.outline] (15% white stroke)
/// - Radius: 24px ([AppRadius.border24])
/// - Padding: 18px (symmetric 16h/14v fallback for compact containers)
/// - Icon: 24x24 SVG
/// - Label: Inter 13px, weight 400, color [AppColors.onSurface]
/// - Value: Inter 16px, weight 400:
///   - Inactive ("No Vrat" / "No Festival"): [AppColors.onSurface]
///   - Active / Default: [AppColors.onSurfaceVariant]
class PanchangSubItemCard extends StatelessWidget {
  final PanchangSubItemData item;
  final EdgeInsetsGeometry? padding;

  const PanchangSubItemCard({
    super.key,
    required this.item,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Conditional formatting rule:
    // If conditional item is inactive, use onSurface (#BAC9CB), otherwise onSurfaceVariant (White).
    final Color valueColor = (item.isConditional && item.isInactive)
        ? AppColors.onSurface
        : AppColors.onSurfaceVariant;

    final Color iconColor = (item.isConditional && item.isInactive)
        ? AppColors.onSurface
        : AppColors.onSurfaceVariant;

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: AppColors.outline,
          ),
          borderRadius: AppRadius.border24,
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
                iconColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: AppTypography.regular,
                    height: 1.60,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.value,
                  style: GoogleFonts.inter(
                    color: valueColor,
                    fontSize: 16,
                    fontWeight: AppTypography.regular,
                    height: 1.50,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
