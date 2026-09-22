import 'package:flutter/material.dart';
import '../../constants/panchang_terms.dart';
import '../../services/sweph_service.dart' show PanchangCalculationResult;
import '../../theme/design_system.dart';
import '../atoms/button_alarm.dart';
import 'list_item_tithi.dart';

export '../../constants/panchang_terms.dart' show AppLanguage, Paksha, Tithi;

/// Card widget displaying Tithi header details.
///
/// Used in:
/// - [TodayView]: without alarm button, with 96px moon image ([CardTithi.today]).
/// - [TithiDetailView]: with [ButtonAlarm], with 72px moon image ([CardTithi.detail]).
///
/// Follows Figma specs:
/// - Container: [AppColors.surface] fill (5% white), 1px [AppColors.outline] (15% white),
///   24px radius ([AppRadius.border24]), 18px padding.
/// - Moon image: rounded with 8px radius ([AppRadius.border8]).
/// - Date: Inter 22px, weight 600, color [AppColors.onSurface] (#BAC9CB).
/// - Tithi: Sora 26px, weight 600, color [AppColors.onSurfaceVariant] (White).
/// - Paksha: Inter 16px, weight 600, color [AppColors.onSurface] (#BAC9CB).
/// - Alarm: 48x48 [ButtonAlarm] with primary border when [showAlarmButton] is true.
/// - Language Switching:
///   - Follows [AppDatabase.instance.languageNotifier] when [language] is null.
///   - Uses explicit [language] when provided.
///   - Automatically localizes Date, Tithi, and Paksha.
class CardTithi extends StatefulWidget {
  final String date;
  final DateTime? dateTime;
  final String tithi;
  final Tithi? tithiEnum;
  final String paksha;
  final Paksha? pakshaEnum;
  final String? moonPhaseAsset;
  final int? lunarDay;
  final bool showAlarmButton;
  final double moonSize;
  final bool isAlarmActive;
  final VoidCallback? onAlarmTap;
  final VoidCallback? onTap;

  /// Language for localizing terms. If not specified, dynamically follows [AppDatabase.languageNotifier].
  final AppLanguage? language;

  const CardTithi({
    super.key,
    this.date = 'Thu, 24 Sep 2026',
    this.dateTime,
    this.tithi = 'Trayodashi',
    this.tithiEnum,
    this.paksha = 'Shukla Paksha',
    this.pakshaEnum,
    this.moonPhaseAsset,
    this.lunarDay,
    this.showAlarmButton = false,
    this.moonSize = 96.0,
    this.isAlarmActive = false,
    this.onAlarmTap,
    this.onTap,
    this.language,
  });

  /// Named constructor for Today View:
  /// - No alarm button
  /// - Moon image size 96x96
  const CardTithi.today({
    super.key,
    this.date = 'Thu, 24 Sep 2026',
    this.dateTime,
    this.tithi = 'Trayodashi',
    this.tithiEnum,
    this.paksha = 'Shukla Paksha',
    this.pakshaEnum,
    this.moonPhaseAsset,
    this.lunarDay = 13,
    this.onTap,
    this.language,
  })  : showAlarmButton = false,
        moonSize = 96.0,
        isAlarmActive = false,
        onAlarmTap = null;

  /// Named constructor for Tithi Detail View:
  /// - Has alarm button toggle
  /// - Moon image size 72x72
  const CardTithi.detail({
    super.key,
    this.date = 'Thu, 24 Sep 2026',
    this.dateTime,
    this.tithi = 'Trayodashi',
    this.tithiEnum,
    this.paksha = 'Shukla Paksha',
    this.pakshaEnum,
    this.moonPhaseAsset,
    this.lunarDay = 13,
    this.isAlarmActive = false,
    this.onAlarmTap,
    this.onTap,
    this.language,
  })  : showAlarmButton = true,
        moonSize = 72.0;

  /// Named factory constructor to render directly from a [PanchangCalculationResult].
  factory CardTithi.fromCalculationResult(
    PanchangCalculationResult result, {
    Key? key,
    bool isDetail = false,
    bool isAlarmActive = false,
    VoidCallback? onAlarmTap,
    VoidCallback? onTap,
    AppLanguage? language,
  }) {
    final int lunarDay = result.paksha == Paksha.shukla
        ? result.tithiNumber
        : (15 + result.tithiNumber);

    return CardTithi(
      key: key,
      date: _formatDateEn(result.date),
      dateTime: result.date,
      tithiEnum: result.tithi,
      pakshaEnum: result.paksha,
      lunarDay: lunarDay,
      showAlarmButton: isDetail,
      moonSize: isDetail ? 72.0 : 96.0,
      isAlarmActive: isAlarmActive,
      onAlarmTap: onAlarmTap,
      onTap: onTap,
      language: language,
    );
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

  @override
  State<CardTithi> createState() => _CardTithiState();
}

/// Compatibility aliases matching Figma export names.
typedef Cardtithidetail = CardTithi;
typedef CardTithiDetail = CardTithi;

class _CardTithiState extends State<CardTithi> {
  late AppLanguage _databaseLanguage;

  @override
  void initState() {
    super.initState();
    _databaseLanguage = appLanguageNotifier.value;
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    if (mounted && _databaseLanguage != appLanguageNotifier.value) {
      setState(() {
        _databaseLanguage = appLanguageNotifier.value;
      });
    }
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  AppLanguage get _effectiveLanguage => widget.language ?? _databaseLanguage;

  String _resolveMoonAsset() {
    if (widget.moonPhaseAsset != null) return widget.moonPhaseAsset!;
    if (widget.lunarDay != null) return ListItemTithi.getMoonAsset(widget.lunarDay!);
    return 'assets/moon_phases/13dvadashi.webp';
  }

  static String _formatDateEn(DateTime d) => CardTithi._formatDateEn(d);

  static ({int day, EnglishMonth month, int year})? _parseDateString(String input) {
    final regex = RegExp(r'(\d{1,2})\s+([A-Za-z\u0900-\u097F\u0A80-\u0AFF]+)\s+(\d{4})');
    final match = regex.firstMatch(input);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final monthStr = match.group(2)!;
    final year = int.tryParse(match.group(3)!);

    if (day == null || year == null) return null;

    final month = EnglishMonth.fromName(monthStr);
    if (month == null) return null;

    return (day: day, month: month, year: year);
  }

  String _resolveLocalizedDate(AppLanguage lang) {
    if (widget.dateTime != null) {
      if (lang == AppLanguage.english) {
        return _formatDateEn(widget.dateTime!);
      }
      final weekdayName = Weekday.fromDateTime(widget.dateTime!).name(lang);
      final monthName = EnglishMonth.fromDateTime(widget.dateTime!).name(lang);
      return '$weekdayName, ${widget.dateTime!.day} $monthName ${widget.dateTime!.year}';
    }

    if (widget.date.isEmpty) return widget.date;

    if (lang == AppLanguage.english) {
      return widget.date;
    }

    final weekday = Weekday.fromName(widget.date);
    final parsedDateInfo = _parseDateString(widget.date);

    if (parsedDateInfo != null) {
      final day = parsedDateInfo.day;
      final month = parsedDateInfo.month;
      final year = parsedDateInfo.year;

      if (lang == AppLanguage.english) {
        return widget.date;
      }

      final localizedWeekday = weekday?.name(lang);
      final localizedMonth = month.name(lang);

      if (localizedWeekday != null) {
        return '$localizedWeekday, $day $localizedMonth $year';
      } else {
        return '$day $localizedMonth $year';
      }
    }

    return widget.date;
  }

  String _resolveLocalizedTithi(AppLanguage lang) {
    if (widget.tithiEnum != null) {
      return widget.tithiEnum!.name(lang);
    }
    final matched = Tithi.fromName(widget.tithi);
    if (matched != null) {
      return matched.name(lang);
    }
    if (widget.lunarDay != null) {
      return Tithi.fromLunarDay(widget.lunarDay!).name(lang);
    }
    return widget.tithi;
  }

  String _resolveLocalizedPaksha(AppLanguage lang) {
    if (widget.pakshaEnum != null) {
      return widget.pakshaEnum!.name(lang);
    }
    final resolved = Paksha.fromName(widget.paksha) ??
        (widget.lunarDay != null ? Paksha.fromLunarDay(widget.lunarDay!) : null);
    if (resolved == null) return widget.paksha;

    final clean = widget.paksha.trim().toLowerCase();
    final bool isShort = !clean.contains('paksha') &&
        !clean.contains('पक्ष') &&
        !clean.contains('પક્ષ');

    if (isShort) {
      return switch (lang) {
        AppLanguage.english => resolved == Paksha.shukla ? 'Shukla' : 'Krishna',
        AppLanguage.hindi => resolved == Paksha.shukla ? 'शुक्ल' : 'कृष्ण',
        AppLanguage.gujarati => resolved == Paksha.shukla ? 'શુક્લ' : 'કૃષ્ણ',
      };
    }
    return resolved.name(lang);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = context.isDesktop;
    final lang = _effectiveLanguage;
    final localizedDate = _resolveLocalizedDate(lang);
    final localizedTithi = _resolveLocalizedTithi(lang);
    final localizedPaksha = _resolveLocalizedPaksha(lang);

    Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          // Moon image
          SizedBox(
            width: widget.moonSize,
            height: widget.moonSize,
            child: ClipRRect(
              borderRadius: AppRadius.border8,
              child: Image.asset(
                _resolveMoonAsset(),
                width: widget.moonSize,
                height: widget.moonSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: widget.moonSize,
                  height: widget.moonSize,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.border8,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing16),

          // Details Column
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedDate,
                  style: AppTypography.bodyStyle(
                    language: _effectiveLanguage,
                    color: AppColors.onSurface,
                    fontSize: isDesktop ? 22 : 18,
                    weight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  localizedTithi,
                  style: AppTypography.headingStyle(
                    language: _effectiveLanguage,
                    color: AppColors.onSurfaceVariant,
                    fontSize: isDesktop ? 28 : 26,
                    weight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  localizedPaksha,
                  style: AppTypography.bodyStyle(
                    language: _effectiveLanguage,
                    color: AppColors.onSurface,
                    fontSize: isDesktop ? 16 : 15,
                    weight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Alarm Button
          if (widget.showAlarmButton) ...[
            const SizedBox(width: AppSpacing.spacing16),
            ButtonAlarm(
              isActive: widget.isAlarmActive,
              onTap: widget.onAlarmTap,
            ),
          ],
        ],
      ),
    );

    if (widget.onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.border24,
          child: content,
        ),
      );
    }

    return content;
  }
}
