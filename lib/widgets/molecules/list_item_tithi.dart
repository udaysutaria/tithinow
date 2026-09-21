import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';
import '../atoms/button_alarm.dart';
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

  /// Language for localizing Tithi, Paksha, Date, and Vrat/Festival.
  /// Defaults to [AppLanguage.english].
  final AppLanguage language;

  /// Optional [DateTime] representing the exact Gregorian date for this Tithi item.
  /// If provided, used to derive localized weekday and month when [language] != [AppLanguage.english].
  final DateTime? dateTime;

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
    this.maxWidth,
    this.language = AppLanguage.english,
    this.dateTime,
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
    double? maxWidth,
    AppLanguage language = AppLanguage.english,
    DateTime? dateTime,
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
      language: language,
      dateTime: dateTime,
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
    double? maxWidth,
    AppLanguage language = AppLanguage.english,
    DateTime? dateTime,
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
      language: language,
      dateTime: dateTime,
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
    double? maxWidth,
    AppLanguage language = AppLanguage.english,
    DateTime? dateTime,
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
      language: language,
      dateTime: dateTime,
    );
  }

  /// 30 Vedic moon phase asset paths (1 to 30).
  static const List<String> _moonPhaseAssets = [
    'assets/moon_phases/01amavasya.webp',
    'assets/moon_phases/02pratipada.webp',
    'assets/moon_phases/03dvitiya.webp',
    'assets/moon_phases/04trutiya.webp',
    'assets/moon_phases/05chaturthi.webp',
    'assets/moon_phases/06panchmi.webp',
    'assets/moon_phases/07shashthi.webp',
    'assets/moon_phases/08saptami.webp',
    'assets/moon_phases/09ashtami.webp',
    'assets/moon_phases/10navami.webp',
    'assets/moon_phases/11dashmi.webp',
    'assets/moon_phases/12ekaadashi.webp',
    'assets/moon_phases/13dvadashi.webp',
    'assets/moon_phases/14trayodashi.webp',
    'assets/moon_phases/15chaturdashi.webp',
    'assets/moon_phases/16purnima.webp',
    'assets/moon_phases/17pratipada.webp',
    'assets/moon_phases/18dvitiya.webp',
    'assets/moon_phases/19trutiya.webp',
    'assets/moon_phases/20chaturthi.webp',
    'assets/moon_phases/21panchmi.webp',
    'assets/moon_phases/22shashthi.webp',
    'assets/moon_phases/23saptami.webp',
    'assets/moon_phases/24ashtami.webp',
    'assets/moon_phases/25navami.webp',
    'assets/moon_phases/26dashmi.webp',
    'assets/moon_phases/27ekaadashi.webp',
    'assets/moon_phases/28dvadashi.webp',
    'assets/moon_phases/29trayodashi.webp',
    'assets/moon_phases/30chaturdashi.webp',
  ];

  /// Resolves the moon asset path from lunar day number (1..30).
  static String getMoonAsset(int day) {
    final normalized = ((day - 1) % 30);
    return _moonPhaseAssets[normalized];
  }

  /// Known translations for active demo/common Vrats.
  static const Map<String, ({String hi, String gu})> _knownVrats = {
    'parivartini ekadashi': (hi: 'परिवर्तिनी एकादशी', gu: 'પરિવર્તિની અગિયારસ'),
    'vamana jayanti': (hi: 'वामन जयंती', gu: 'વામન જયંતી'),
    'pradosh vrat': (hi: 'प्रदोष व्रत', gu: 'પ્રદોષ વ્રત'),
    'ekadashi': (hi: 'एकादशी', gu: 'અગિયારસ'),
    'satyanarayan vrat': (hi: 'सत्यनारायण व्रत', gu: 'સત્યનારાયણ વ્રત'),
  };

  /// Known translations for active demo/common Festivals.
  static const Map<String, ({String hi, String gu})> _knownFestivals = {
    'anant chaturdashi': (hi: 'अनंत चतुर्दशी', gu: 'અનંત ચતુર્દશી'),
    'bhadrapada purnima': (hi: 'भाद्रपद पूर्णिमा', gu: 'ભાદ્રપદ પૂર્ણિમા'),
    'pitrupaksha begins': (hi: 'पितृपक्ष प्रारंभ', gu: 'પિતૃપક્ષ પ્રારંભ'),
    'ganesh visarjan': (hi: 'गणेश विसर्जन', gu: 'ગણેશ વિસર્જન'),
  };

  /// Determines if a Vrat/Festival string is inactive (empty, "No Vrat", etc.).
  static bool isInactiveValue(String? value) {
    if (value == null) return true;
    final trimmed = value.trim().toLowerCase();
    return trimmed.isEmpty ||
        trimmed == 'no vrat' ||
        trimmed == 'no festival' ||
        trimmed == 'none' ||
        trimmed == 'n/a' ||
        trimmed == '-' ||
        trimmed == 'कोई व्रत नहीं' ||
        trimmed == 'कोई त्योहार नहीं' ||
        trimmed == 'व्रत नहीं' ||
        trimmed == 'त्योहार नहीं' ||
        trimmed == 'કોઈ વ્રત નથી' ||
        trimmed == 'કોઈ તહેવાર નથી' ||
        trimmed == 'વ્રત નથી' ||
        trimmed == 'તહેવાર નથી';
  }

  String _resolveMoonAsset() {
    if (moonPhaseAsset != null) return moonPhaseAsset!;
    if (lunarDay != null) return getMoonAsset(lunarDay!);
    return 'assets/moon_phases/13dvadashi.webp';
  }

  static Tithi? _findTithi(String input) {
    final clean = input.trim().toLowerCase().replaceAll(' ', '');
    if (clean.isEmpty) return null;
    for (final t in Tithi.values) {
      if (t.en.toLowerCase() == clean ||
          t.hi == input.trim() ||
          t.gu == input.trim()) {
        return t;
      }
    }
    return switch (clean) {
      'dvitiya' => Tithi.dwitiya,
      'trutiya' => Tithi.tritiya,
      'panchmi' => Tithi.panchami,
      'shasthi' => Tithi.shashthi,
      'dashmi' => Tithi.dashami,
      'ekaadashi' => Tithi.ekadashi,
      'dvadashi' => Tithi.dwadashi,
      _ => null,
    };
  }

  String _resolveLocalizedTithi() {
    final matched = _findTithi(tithi);
    if (matched != null) {
      return matched.name(language);
    }
    if (lunarDay != null) {
      return Tithi.fromLunarDay(lunarDay!).name(language);
    }
    return tithi;
  }

  Paksha? _resolvePakshaEnum() {
    final clean = paksha.trim().toLowerCase();
    if (clean.contains('shukla') ||
        clean.contains('शुक्ल') ||
        clean.contains('શુક્લ')) {
      return Paksha.shukla;
    }
    if (clean.contains('krishna') ||
        clean.contains('कृष्ण') ||
        clean.contains('કૃષ્ણ')) {
      return Paksha.krishna;
    }
    if (lunarDay != null) {
      return Paksha.fromLunarDay(lunarDay!);
    }
    return null;
  }

  String _resolveLocalizedPaksha() {
    final resolved = _resolvePakshaEnum();
    if (resolved == null) return paksha;

    final clean = paksha.trim().toLowerCase();
    final bool isShort = !clean.contains('paksha') &&
        !clean.contains('पक्ष') &&
        !clean.contains('પક્ષ');

    if (isShort) {
      return switch (language) {
        AppLanguage.english =>
          resolved == Paksha.shukla ? 'Shukla' : 'Krishna',
        AppLanguage.hindi => resolved == Paksha.shukla ? 'शुक्ल' : 'कृष्ण',
        AppLanguage.gujarati => resolved == Paksha.shukla ? 'શુક્લ' : 'કૃષ્ણ',
      };
    } else {
      return resolved.name(language);
    }
  }

  static Weekday? _parseWeekday(String input) {
    final clean = input.trim().toLowerCase();
    for (final w in Weekday.values) {
      final prefix3 = w.en.toLowerCase().substring(0, 3);
      if (clean.startsWith(prefix3) ||
          clean.startsWith(w.en.toLowerCase()) ||
          clean.startsWith(w.hi.toLowerCase()) ||
          clean.startsWith(w.gu.toLowerCase())) {
        return w;
      }
    }
    return null;
  }

  static EnglishMonth? _parseMonth(String token) {
    final clean = token.trim().toLowerCase();
    for (final m in EnglishMonth.values) {
      final prefix3 = m.en.toLowerCase().substring(0, 3);
      if (clean.startsWith(prefix3) ||
          clean.startsWith(m.en.toLowerCase()) ||
          clean == m.hi.toLowerCase() ||
          clean == m.gu.toLowerCase()) {
        return m;
      }
    }
    return null;
  }

  static ({int day, EnglishMonth month, int year})? _parseDateString(String input) {
    final regex = RegExp(r'(\d{1,2})\s+([A-Za-z\u0900-\u097F\u0A80-\u0AFF]+)\s+(\d{4})');
    final match = regex.firstMatch(input);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final monthStr = match.group(2)!;
    final year = int.tryParse(match.group(3)!);

    if (day == null || year == null) return null;

    final month = _parseMonth(monthStr);
    if (month == null) return null;

    return (day: day, month: month, year: year);
  }

  static String _shortWeekdayEn(DateTime d) {
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return w[d.weekday - 1];
  }

  static String _shortMonthEn(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[d.month - 1];
  }

  static String _formatDateEn(DateTime d) {
    return '${_shortWeekdayEn(d)}, ${d.day} ${_shortMonthEn(d)} ${d.year}';
  }

  String _resolveLocalizedDate() {
    if (language == AppLanguage.english && date.isNotEmpty) {
      return date;
    }

    if (dateTime != null) {
      if (language == AppLanguage.english) {
        return date.isNotEmpty ? date : _formatDateEn(dateTime!);
      }
      final weekdayName = Weekday.fromDateTime(dateTime!).name(language);
      final monthName = EnglishMonth.fromDateTime(dateTime!).name(language);
      return '$weekdayName, ${dateTime!.day} $monthName ${dateTime!.year}';
    }

    if (date.isEmpty) return date;

    final weekday = _parseWeekday(date);
    final parsedDateInfo = _parseDateString(date);

    if (parsedDateInfo != null) {
      final day = parsedDateInfo.day;
      final month = parsedDateInfo.month;
      final year = parsedDateInfo.year;

      final localizedWeekday = weekday?.name(language);
      final localizedMonth = month.name(language);

      if (localizedWeekday != null) {
        return '$localizedWeekday, $day $localizedMonth $year';
      } else {
        return '$day $localizedMonth $year';
      }
    }

    return date;
  }

  String _resolveLocalizedVrat() {
    if (isInactiveValue(vrat)) {
      return PanchangLabels.noVrat(language);
    }
    final raw = (vrat ?? '').trim();
    if (language == AppLanguage.english) return raw;
    final lower = raw.toLowerCase();
    if (_knownVrats.containsKey(lower)) {
      return language == AppLanguage.hindi
          ? _knownVrats[lower]!.hi
          : _knownVrats[lower]!.gu;
    }
    return raw;
  }

  String _resolveLocalizedFestival() {
    if (isInactiveValue(festival)) {
      return PanchangLabels.noFestival(language);
    }
    final raw = (festival ?? '').trim();
    if (language == AppLanguage.english) return raw;
    final lower = raw.toLowerCase();
    if (_knownFestivals.containsKey(lower)) {
      return language == AppLanguage.hindi
          ? _knownFestivals[lower]!.hi
          : _knownFestivals[lower]!.gu;
    }
    return raw;
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
          const SizedBox(height: AppSpacing.spacing12),
          divider,
          const SizedBox(height: AppSpacing.spacing12),
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
    final localizedDate = _resolveLocalizedDate();
    final localizedTithi = _resolveLocalizedTithi();
    final localizedPaksha = _resolveLocalizedPaksha();

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
                localizedDate,
                style: AppTypography.bodyStyle(
                  language: language,
                  color: AppColors.onSurface,
                  fontSize: 16,
                  weight: AppTypography.regular,
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
                      localizedTithi,
                      style: AppTypography.headingStyle(
                        language: language,
                        color: AppColors.onSurfaceVariant,
                        fontSize: 26,
                        weight: AppTypography.semiBold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing8),
                  Text(
                    localizedPaksha,
                    style: AppTypography.bodyStyle(
                      language: language,
                      color: AppColors.onSurface,
                      fontSize: 13,
                      weight: AppTypography.regular,
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
    final effectiveVrat = _resolveLocalizedVrat();
    final effectiveFestival = _resolveLocalizedFestival();

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
                style: AppTypography.bodyStyle(
                  language: language,
                  color: AppColors.onSurface,
                  fontSize: 13,
                  weight: AppTypography.semiBold,
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
            style: AppTypography.bodyStyle(
              language: language,
              color: AppColors.tertiary,
              fontSize: 13,
              weight: AppTypography.semiBold,
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
