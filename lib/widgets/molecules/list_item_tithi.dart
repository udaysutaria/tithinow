import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/panchang_terms.dart';
import '../../theme/design_system.dart';
import '../atoms/button_alarm.dart';
import '../atoms/skeleton_loader.dart';
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
  ///
  /// - Days 1..14 (Shukla Pratipada to Chaturdashi): 02*.webp to 15*.webp
  /// - Day 15 (Shukla Purnima): 16purnima.webp
  /// - Days 16..29 (Krishna Pratipada to Chaturdashi): 17*.webp to 30*.webp
  /// - Day 30 (Krishna Amavasya): 01amavasya.webp
  static const List<String> _moonPhaseAssets = [
    // Shukla Paksha: Days 1 to 14 (02*.webp to 15*.webp)
    'assets/moon_phases/02pratipada.webp',   // 1: Shukla Pratipada
    'assets/moon_phases/03dvitiya.webp',     // 2: Shukla Dwitiya
    'assets/moon_phases/04trutiya.webp',     // 3: Shukla Tritiya
    'assets/moon_phases/05chaturthi.webp',   // 4: Shukla Chaturthi
    'assets/moon_phases/06panchmi.webp',     // 5: Shukla Panchami
    'assets/moon_phases/07shashthi.webp',    // 6: Shukla Shashthi
    'assets/moon_phases/08saptami.webp',     // 7: Shukla Saptami
    'assets/moon_phases/09ashtami.webp',     // 8: Shukla Ashtami
    'assets/moon_phases/10navami.webp',      // 9: Shukla Navami
    'assets/moon_phases/11dashmi.webp',      // 10: Shukla Dashami
    'assets/moon_phases/12ekaadashi.webp',   // 11: Shukla Ekadashi
    'assets/moon_phases/13dvadashi.webp',    // 12: Shukla Dwadashi
    'assets/moon_phases/14trayodashi.webp',  // 13: Shukla Trayodashi
    'assets/moon_phases/15chaturdashi.webp', // 14: Shukla Chaturdashi
    // Day 15: Purnima (16purnima.webp)
    'assets/moon_phases/16purnima.webp',     // 15: Purnima
    // Krishna Paksha: Days 16 to 29 (17*.webp to 30*.webp)
    'assets/moon_phases/17pratipada.webp',   // 16: Krishna Pratipada
    'assets/moon_phases/18dvitiya.webp',     // 17: Krishna Dwitiya
    'assets/moon_phases/19trutiya.webp',     // 18: Krishna Tritiya
    'assets/moon_phases/20chaturthi.webp',   // 19: Krishna Chaturthi
    'assets/moon_phases/21panchmi.webp',     // 20: Krishna Panchami
    'assets/moon_phases/22shashthi.webp',    // 21: Krishna Shashthi
    'assets/moon_phases/23saptami.webp',     // 22: Krishna Saptami
    'assets/moon_phases/24ashtami.webp',     // 23: Krishna Ashtami
    'assets/moon_phases/25navami.webp',      // 24: Krishna Navami
    'assets/moon_phases/26dashmi.webp',      // 25: Krishna Dashami
    'assets/moon_phases/27ekaadashi.webp',   // 26: Krishna Ekadashi
    'assets/moon_phases/28dvadashi.webp',    // 27: Krishna Dwadashi
    'assets/moon_phases/29trayodashi.webp',  // 28: Krishna Trayodashi
    'assets/moon_phases/30chaturdashi.webp', // 29: Krishna Chaturdashi
    // Day 30: Amavasya (01amavasya.webp)
    'assets/moon_phases/01amavasya.webp',    // 30: Amavasya
  ];

  /// Resolves the moon asset path from lunar day number (1..30).
  static String getMoonAsset(int day) {
    final normalized = ((day - 1) % 30);
    return _moonPhaseAssets[normalized];
  }

  /// Resolves the moon asset path from [Tithi] and [Paksha].
  static String getMoonAssetForTithi({
    required Tithi tithi,
    required Paksha paksha,
  }) {
    if (tithi == Tithi.amavasya || (paksha == Paksha.krishna && tithi == Tithi.purnima)) {
      return 'assets/moon_phases/01amavasya.webp';
    }
    if (tithi == Tithi.purnima) {
      return 'assets/moon_phases/16purnima.webp';
    }
    final index = tithi.index.clamp(0, 13);
    if (paksha == Paksha.shukla) {
      return _moonPhaseAssets[index];
    } else {
      return _moonPhaseAssets[15 + index];
    }
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
    final tithiEnum = _findTithi(tithi);
    final pakshaEnum = _resolvePakshaEnum();
    if (tithiEnum != null && pakshaEnum != null) {
      return getMoonAssetForTithi(tithi: tithiEnum, paksha: pakshaEnum);
    }
    return 'assets/moon_phases/02pratipada.webp';
  }

  static Tithi? _findTithi(String input) {
    return Tithi.fromName(input);
  }

  String _resolveLocalizedTithi() {
    final pakshaEnum = _resolvePakshaEnum();
    final matched = _findTithi(tithi);
    if (matched != null) {
      if (matched == Tithi.purnima && (pakshaEnum == Paksha.krishna || lunarDay == 30)) {
        return Tithi.amavasya.name(language);
      }
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
    if (tithi.isEmpty) {
      final skeleton = ListItemTithiSkeleton(maxWidth: maxWidth);
      if (onTap != null) {
        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: skeleton,
        );
      }
      return skeleton;
    }

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
