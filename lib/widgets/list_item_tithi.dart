import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/design_system.dart';
import 'button_alarm.dart';
import 'list_item_tab_content.dart' show ItemTemporalState;

/// Compatibility alias for [ItemTemporalState] in the context of Tithi items.
typedef TithiItemState = ItemTemporalState;

/// Tithi list item molecule supporting 3 temporal states:
/// - **PastItem**: Dimmed with 40% opacity, showing moon phase, date, tithi, paksha, vrat, and festival.
/// - **CurrentItem**: Full opacity highlighted with primary brand border ([AppColors.primary]).
/// - **FutureItem**: Full opacity with outline border and embedded [ButtonAlarm] toggle.
///
/// Conditional formatting for Vrat & Festival:
/// - Inactive ("No Vrat", "No Festival", empty): 50% opacity in [AppColors.onSurface] (#BAC9CB).
/// - Active (e.g. "Anant Chaturdashi", "Ekadashi"): Full opacity in [AppColors.tertiary] (#D9B686).
class ListItemTithi extends StatelessWidget {
  final ItemTemporalState state;
  final String date;
  final String tithi;
  final String paksha;
  final String? vrat;
  final String? festival;
  final String? moonPhaseAsset;
  final int? lunarDay;
  final bool isAlarmActive;
  final VoidCallback? onAlarmTap;
  final VoidCallback? onTap;
  final double? maxWidth;

  const ListItemTithi({
    super.key,
    this.state = ItemTemporalState.current,
    required this.date,
    required this.tithi,
    required this.paksha,
    this.vrat = 'No Vrat',
    this.festival = 'No Festival',
    this.moonPhaseAsset,
    this.lunarDay,
    this.isAlarmActive = false,
    this.onAlarmTap,
    this.onTap,
    this.maxWidth = 380.0,
  });

  /// Factory constructor for Past Tithi items.
  factory ListItemTithi.past({
    Key? key,
    required String date,
    required String tithi,
    required String paksha,
    String? vrat = 'No Vrat',
    String? festival = 'No Festival',
    String? moonPhaseAsset,
    int? lunarDay,
    VoidCallback? onTap,
    double? maxWidth = 380.0,
  }) {
    return ListItemTithi(
      key: key,
      state: ItemTemporalState.past,
      date: date,
      tithi: tithi,
      paksha: paksha,
      vrat: vrat,
      festival: festival,
      moonPhaseAsset: moonPhaseAsset,
      lunarDay: lunarDay,
      onTap: onTap,
      maxWidth: maxWidth,
    );
  }

  /// Factory constructor for Current Tithi items (highlighted with primary border).
  factory ListItemTithi.current({
    Key? key,
    required String date,
    required String tithi,
    required String paksha,
    String? vrat = 'No Vrat',
    String? festival = 'No Festival',
    String? moonPhaseAsset,
    int? lunarDay,
    VoidCallback? onTap,
    double? maxWidth = 380.0,
  }) {
    return ListItemTithi(
      key: key,
      state: ItemTemporalState.current,
      date: date,
      tithi: tithi,
      paksha: paksha,
      vrat: vrat,
      festival: festival,
      moonPhaseAsset: moonPhaseAsset,
      lunarDay: lunarDay,
      onTap: onTap,
      maxWidth: maxWidth,
    );
  }

  /// Factory constructor for Future Tithi items (includes ButtonAlarm).
  factory ListItemTithi.future({
    Key? key,
    required String date,
    required String tithi,
    required String paksha,
    String? vrat = 'No Vrat',
    String? festival = 'No Festival',
    String? moonPhaseAsset,
    int? lunarDay,
    bool isAlarmActive = false,
    VoidCallback? onAlarmTap,
    VoidCallback? onTap,
    double? maxWidth = 380.0,
  }) {
    return ListItemTithi(
      key: key,
      state: ItemTemporalState.future,
      date: date,
      tithi: tithi,
      paksha: paksha,
      vrat: vrat,
      festival: festival,
      moonPhaseAsset: moonPhaseAsset,
      lunarDay: lunarDay,
      isAlarmActive: isAlarmActive,
      onAlarmTap: onAlarmTap,
      onTap: onTap,
      maxWidth: maxWidth,
    );
  }

  /// 30 Vedic moon phase asset paths (1 to 30).
  static const List<String> _moonPhaseAssets = [
    'assets/moon_phases/01amavasya.png',
    'assets/moon_phases/02pratipada.png',
    'assets/moon_phases/03dvitiya.png',
    'assets/moon_phases/04trutiya.png',
    'assets/moon_phases/05chaturthi.png',
    'assets/moon_phases/06panchmi.png',
    'assets/moon_phases/07shashthi.png',
    'assets/moon_phases/08saptami.png',
    'assets/moon_phases/09ashtami.png',
    'assets/moon_phases/10navami.png',
    'assets/moon_phases/11dashmi.png',
    'assets/moon_phases/12ekaadashi.png',
    'assets/moon_phases/13dvadashi.png',
    'assets/moon_phases/14trayodashi.png',
    'assets/moon_phases/15chaturdashi.png',
    'assets/moon_phases/16purnima.png',
    'assets/moon_phases/17pratipada.png',
    'assets/moon_phases/18dvitiya.png',
    'assets/moon_phases/19trutiya.png',
    'assets/moon_phases/20chaturthi.png',
    'assets/moon_phases/21panchmi.png',
    'assets/moon_phases/22shashthi.png',
    'assets/moon_phases/23saptami.png',
    'assets/moon_phases/24ashtami.png',
    'assets/moon_phases/25navami.png',
    'assets/moon_phases/26dashmi.png',
    'assets/moon_phases/27ekaadashi.png',
    'assets/moon_phases/28dvadashi.png',
    'assets/moon_phases/29trayodashi.png',
    'assets/moon_phases/30chaturdashi.png',
  ];

  /// Resolves the moon asset path from lunar day number (1..30).
  static String getMoonAsset(int day) {
    final normalized = ((day - 1) % 30);
    return _moonPhaseAssets[normalized];
  }

  /// Determines if a Vrat/Festival string is inactive (empty, "No Vrat", etc.).
  static bool isInactiveValue(String? value) {
    if (value == null) return true;
    final trimmed = value.trim().toLowerCase();
    return trimmed.isEmpty ||
        trimmed == 'no vrat' ||
        trimmed == 'no festival' ||
        trimmed == 'none' ||
        trimmed == 'n/a' ||
        trimmed == '-';
  }

  String _resolveMoonAsset() {
    if (moonPhaseAsset != null) return moonPhaseAsset!;
    if (lunarDay != null) return getMoonAsset(lunarDay!);
    return 'assets/moon_phases/13dvadashi.png';
  }

  @override
  Widget build(BuildContext context) {
    final bool isPast = state == ItemTemporalState.past;
    final bool isCurrent = state == ItemTemporalState.current;
    final bool isFuture = state == ItemTemporalState.future;

    // Current item is highlighted with primary border; past and future use outline.
    final Color borderColor = isCurrent ? AppColors.primary : AppColors.outline;

    Widget topRow = _buildTopRow(context, isFuture: isFuture);
    Widget divider = _buildDivider();
    Widget bottomRow = _buildBottomRow();

    // In PastItem, each section is dimmed to 40% opacity.
    if (isPast) {
      topRow = Opacity(opacity: 0.40, child: topRow);
      divider = Opacity(opacity: 0.40, child: divider);
      bottomRow = Opacity(opacity: 0.40, child: bottomRow);
    }

    Widget content = Container(
      padding: const EdgeInsets.all(18),
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: borderColor,
          ),
          borderRadius: AppRadius.border24,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          topRow,
          const SizedBox(height: AppSpacing.spacing16),
          divider,
          const SizedBox(height: AppSpacing.spacing16),
          bottomRow,
        ],
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.border24,
          child: content,
        ),
      );
    }

    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }

    return content;
  }

  Widget _buildTopRow(BuildContext context, {required bool isFuture}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 48x48 Moon Phase Image
        SizedBox(
          width: 48,
          height: 48,
          child: ClipRRect(
            borderRadius: AppRadius.border8,
            child: Image.asset(
              _resolveMoonAsset(),
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.border8,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing8),

        // Date and Tithi Name + Paksha
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: GoogleFonts.inter(
                  color: AppColors.onSurface,
                  fontSize: 16,
                  fontWeight: AppTypography.regular,
                  height: 1.50,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.spacing4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      tithi,
                      style: GoogleFonts.sora(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 26,
                        fontWeight: AppTypography.semiBold,
                        height: 1.20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing8),
                  Text(
                    paksha,
                    style: GoogleFonts.inter(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: AppTypography.regular,
                      height: 1.60,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Alarm button present only in FutureItem
        if (isFuture) ...[
          const SizedBox(width: AppSpacing.spacing8),
          ButtonAlarm(
            isActive: isAlarmActive,
            onTap: onAlarmTap,
          ),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: AppColors.outline,
    );
  }

  Widget _buildBottomRow() {
    final effectiveVrat = vrat ?? 'No Vrat';
    final effectiveFestival = festival ?? 'No Festival';

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildBadge(
            iconAsset: 'assets/icons/IconVrat.svg',
            text: effectiveVrat,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing16),
        Expanded(
          child: _buildBadge(
            iconAsset: 'assets/icons/IconFestival.svg',
            text: effectiveFestival,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String iconAsset,
    required String text,
  }) {
    final bool isInactive = isInactiveValue(text);

    if (isInactive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.50,
            child: SvgPicture.asset(
              iconAsset,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.onSurface,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Opacity(
              opacity: 0.50,
              child: Text(
                text,
                style: GoogleFonts.inter(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: AppTypography.semiBold,
                  height: 1.60,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            AppColors.tertiary,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.tertiary,
              fontSize: 13,
              fontWeight: AppTypography.semiBold,
              height: 1.60,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Compatibility aliases matching Figma export names.
typedef PastItem = ListItemTithi;
typedef CurrentItem = ListItemTithi;
typedef FutureItem = ListItemTithi;
typedef TithiItem = ListItemTithi;
typedef Past = ListItemTithi;
typedef Current = ListItemTithi;
