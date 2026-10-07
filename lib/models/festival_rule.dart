import '../constants/panchang_terms.dart';

/// Data model representing a Vedic festival, vrat, or astronomical observance rule.
///
/// Synced from the WordPress REST API (`/wp-json/wp/v2/festivals`) and cached in local SQLite.
class FestivalRule {
  final int id;
  final String festivalId;
  final String category;
  final String importanceLevel;
  final bool isFasting;
  final String nameEn;
  final String nameHi;
  final String nameGu;
  final String descriptionEn;
  final String descriptionHi;
  final String descriptionGu;
  final String eventType;
  final String daySelectionRule;
  final String? lunarMonth;
  final String? paksha;
  final int? tithiNumber;
  final String? solarMonth;
  final String? nakshatraConstraint;
  final String regionVariant;
  final int ruleVersion;
  final DateTime? modified;
  final String? fastingType;
  final String? paranaRule;
  final int durationDays;
  final String? endFestivalId;
  final String? parentFestivalId;
  final int? offsetDays;
  final int? fixedMonth;
  final int? fixedDay;
  final String? eclipseType;
  final bool sutakApplies;
  final String? tieBreakRule;
  final String? adhikaMasaPolicy;
  final String? weekday;
  final String? weekdayRule;
  final bool repeatWeekday;
  final bool avoidBhadra;
  final String? purnimantaMonth;
  final String? nakshatraTrigger;
  final String? nakshatraSolarMonth;
  final String? nakshatraLunarMonth;
  final String? sampradaya;
  final String? sourceReference;
  final String? ayanamsa;
  final bool verified;
  final String? verificationNotes;

  const FestivalRule({
    required this.id,
    required this.festivalId,
    required this.category,
    this.importanceLevel = 'major',
    this.isFasting = false,
    required this.nameEn,
    this.nameHi = '',
    this.nameGu = '',
    this.descriptionEn = '',
    this.descriptionHi = '',
    this.descriptionGu = '',
    this.eventType = 'lunar_tithi',
    this.daySelectionRule = 'udaya',
    this.lunarMonth,
    this.paksha,
    this.tithiNumber,
    this.solarMonth,
    this.nakshatraConstraint,
    this.regionVariant = 'national',
    this.ruleVersion = 1,
    this.modified,
    this.fastingType,
    this.paranaRule,
    this.durationDays = 1,
    this.endFestivalId,
    this.parentFestivalId,
    this.offsetDays,
    this.fixedMonth,
    this.fixedDay,
    this.eclipseType,
    this.sutakApplies = false,
    this.tieBreakRule,
    this.adhikaMasaPolicy,
    this.weekday,
    this.weekdayRule,
    this.repeatWeekday = false,
    this.avoidBhadra = false,
    this.purnimantaMonth,
    this.nakshatraTrigger,
    this.nakshatraSolarMonth,
    this.nakshatraLunarMonth,
    this.sampradaya,
    this.sourceReference,
    this.ayanamsa,
    this.verified = false,
    this.verificationNotes,
  });

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is bool) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is bool) return null;
    return int.tryParse(value.toString().trim());
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final str = value.toString().trim().toLowerCase();
    if (str == 'true' || str == '1' || str == 'yes') return true;
    if (str == 'false' || str == '0' || str == 'no' || str == '') return false;
    return defaultValue;
  }

  /// Factory constructor to parse a record from the WordPress REST API JSON response.
  factory FestivalRule.fromWordPressJson(Map<String, dynamic> json) {
    final id = _parseInt(json['id']) ?? 0;
    final modifiedStr = _parseString(json['modified']);
    final modified = modifiedStr != null ? DateTime.tryParse(modifiedStr) : null;

    final acf = (json['acf'] is Map<String, dynamic>)
        ? json['acf'] as Map<String, dynamic>
        : (json['acf'] is Map
            ? Map<String, dynamic>.from(json['acf'] as Map)
            : const <String, dynamic>{});

    // In case festival_id was left blank in ACF, fall back to the WordPress post slug
    final slug = _parseString(json['slug']) ?? '';
    final festivalId = _parseString(acf['festival_id']) ?? slug.replaceAll('-', '_');

    final bool isFasting = _parseBool(acf['is_fasting'], defaultValue: false);
    final nakConstraint = _parseString(acf['nakshatra_constraint']);

    return FestivalRule(
      id: id,
      festivalId: festivalId,
      category: _parseString(acf['category']) ?? 'festival',
      importanceLevel: _parseString(acf['importance_level']) ?? 'major',
      isFasting: isFasting,
      nameEn: _parseString(acf['festival_name_en']) ??
          (json['title'] is Map ? _parseString(json['title']['rendered']) ?? '' : ''),
      nameHi: _parseString(acf['festival_name_hi']) ?? '',
      nameGu: _parseString(acf['festival_name_gu']) ?? '',
      descriptionEn: _parseString(acf['description_en']) ?? '',
      descriptionHi: _parseString(acf['description_hi']) ?? '',
      descriptionGu: _parseString(acf['description_gu']) ?? '',
      eventType: _parseString(acf['event_type']) ?? 'lunar_tithi',
      daySelectionRule: _parseString(acf['day_selection_rule']) ?? 'udaya',
      lunarMonth: _parseString(acf['lunar_month']),
      paksha: _parseString(acf['paksha']),
      tithiNumber: _parseInt(acf['tithi_number']),
      solarMonth: _parseString(acf['solar_month']),
      nakshatraConstraint: (nakConstraint == 'none') ? null : nakConstraint,
      regionVariant: _parseString(acf['region_variant']) ?? 'national',
      ruleVersion: _parseInt(acf['rule_version']) ?? 1,
      modified: modified,
      fastingType: _parseString(acf['fasting_type']),
      paranaRule: _parseString(acf['parana_rule']),
      durationDays: _parseInt(acf['duration_days']) ?? 1,
      endFestivalId: _parseString(acf['end_festival_id']),
      parentFestivalId: _parseString(acf['parent_festival_id']),
      offsetDays: _parseInt(acf['offset_days']),
      fixedMonth: _parseInt(acf['fixed_month']),
      fixedDay: _parseInt(acf['fixed_day']),
      eclipseType: _parseString(acf['eclipse_type']),
      sutakApplies: _parseBool(acf['sutak_applies'], defaultValue: false),
      tieBreakRule: _parseString(acf['tie_break_rule']),
      adhikaMasaPolicy: _parseString(acf['adhika_masa_policy']),
      weekday: _parseString(acf['weekday']),
      weekdayRule: _parseString(acf['weekday_rule']),
      repeatWeekday: _parseBool(acf['repeat_weekday'], defaultValue: false),
      avoidBhadra: _parseBool(acf['avoid_bhadra'], defaultValue: false),
      purnimantaMonth: _parseString(acf['purnimanta_month']),
      nakshatraTrigger: _parseString(acf['nakshatra_trigger']),
      nakshatraSolarMonth: _parseString(acf['nakshatra_solar_month']),
      nakshatraLunarMonth: _parseString(acf['nakshatra_lunar_month']),
      sampradaya: _parseString(acf['sampradaya']),
      sourceReference: _parseString(acf['source_reference']),
      ayanamsa: _parseString(acf['ayanamsa']),
      verified: _parseBool(acf['verified'], defaultValue: false),
      verificationNotes: _parseString(acf['verification_notes']),
    );
  }

  /// Factory constructor to parse a record from SQLite row map.
  factory FestivalRule.fromMap(Map<String, dynamic> map) {
    final modifiedStr = map['modified'] as String?;
    return FestivalRule(
      id: map['id'] as int? ?? 0,
      festivalId: map['festival_id'] as String? ?? '',
      category: map['category'] as String? ?? 'festival',
      importanceLevel: map['importance_level'] as String? ?? 'major',
      isFasting: (map['is_fasting'] as int? ?? 0) == 1,
      nameEn: map['name_en'] as String? ?? '',
      nameHi: map['name_hi'] as String? ?? '',
      nameGu: map['name_gu'] as String? ?? '',
      descriptionEn: map['desc_en'] as String? ?? '',
      descriptionHi: map['desc_hi'] as String? ?? '',
      descriptionGu: map['desc_gu'] as String? ?? '',
      eventType: map['event_type'] as String? ?? 'lunar_tithi',
      daySelectionRule: map['day_selection_rule'] as String? ?? 'udaya',
      lunarMonth: map['lunar_month'] as String?,
      paksha: map['paksha'] as String?,
      tithiNumber: map['tithi_number'] as int?,
      solarMonth: map['solar_month'] as String?,
      nakshatraConstraint: map['nakshatra_constraint'] as String?,
      regionVariant: map['region_variant'] as String? ?? 'national',
      ruleVersion: map['rule_version'] as int? ?? 1,
      modified: modifiedStr != null ? DateTime.tryParse(modifiedStr) : null,
      fastingType: map['fasting_type'] as String?,
      paranaRule: map['parana_rule'] as String?,
      durationDays: map['duration_days'] as int? ?? 1,
      endFestivalId: map['end_festival_id'] as String?,
      parentFestivalId: map['parent_festival_id'] as String?,
      offsetDays: map['offset_days'] as int?,
      fixedMonth: map['fixed_month'] as int?,
      fixedDay: map['fixed_day'] as int?,
      eclipseType: map['eclipse_type'] as String?,
      sutakApplies: (map['sutak_applies'] as int? ?? 0) == 1,
      tieBreakRule: map['tie_break_rule'] as String?,
      adhikaMasaPolicy: map['adhika_masa_policy'] as String?,
      weekday: map['weekday'] as String?,
      weekdayRule: map['weekday_rule'] as String?,
      repeatWeekday: (map['repeat_weekday'] as int? ?? 0) == 1,
      avoidBhadra: (map['avoid_bhadra'] as int? ?? 0) == 1,
      purnimantaMonth: map['purnimanta_month'] as String?,
      nakshatraTrigger: map['nakshatra_trigger'] as String?,
      nakshatraSolarMonth: map['nakshatra_solar_month'] as String?,
      nakshatraLunarMonth: map['nakshatra_lunar_month'] as String?,
      sampradaya: map['sampradaya'] as String?,
      sourceReference: map['source_reference'] as String?,
      ayanamsa: map['ayanamsa'] as String?,
      verified: (map['verified'] as int? ?? 0) == 1,
      verificationNotes: map['verification_notes'] as String?,
    );
  }

  /// Converts this rule to a map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'festival_id': festivalId,
      'category': category,
      'importance_level': importanceLevel,
      'is_fasting': isFasting ? 1 : 0,
      'name_en': nameEn,
      'name_hi': nameHi,
      'name_gu': nameGu,
      'desc_en': descriptionEn,
      'desc_hi': descriptionHi,
      'desc_gu': descriptionGu,
      'event_type': eventType,
      'day_selection_rule': daySelectionRule,
      'lunar_month': lunarMonth,
      'paksha': paksha,
      'tithi_number': tithiNumber,
      'solar_month': solarMonth,
      'nakshatra_constraint': nakshatraConstraint,
      'region_variant': regionVariant,
      'rule_version': ruleVersion,
      'modified': modified?.toIso8601String(),
      'fasting_type': fastingType,
      'parana_rule': paranaRule,
      'duration_days': durationDays,
      'end_festival_id': endFestivalId,
      'parent_festival_id': parentFestivalId,
      'offset_days': offsetDays,
      'fixed_month': fixedMonth,
      'fixed_day': fixedDay,
      'eclipse_type': eclipseType,
      'sutak_applies': sutakApplies ? 1 : 0,
      'tie_break_rule': tieBreakRule,
      'adhika_masa_policy': adhikaMasaPolicy,
      'weekday': weekday,
      'weekday_rule': weekdayRule,
      'repeat_weekday': repeatWeekday ? 1 : 0,
      'avoid_bhadra': avoidBhadra ? 1 : 0,
      'purnimanta_month': purnimantaMonth,
      'nakshatra_trigger': nakshatraTrigger,
      'nakshatra_solar_month': nakshatraSolarMonth,
      'nakshatra_lunar_month': nakshatraLunarMonth,
      'sampradaya': sampradaya,
      'source_reference': sourceReference,
      'ayanamsa': ayanamsa,
      'verified': verified ? 1 : 0,
      'verification_notes': verificationNotes,
    };
  }

  /// Returns localized festival name, falling back to English if localized is empty.
  String name(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:
        return nameHi.isNotEmpty ? nameHi : nameEn;
      case AppLanguage.gujarati:
        return nameGu.isNotEmpty ? nameGu : nameEn;
      case AppLanguage.english:
        return nameEn;
    }
  }

  /// Returns localized description, falling back to English if localized is empty.
  String description(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:
        return descriptionHi.isNotEmpty ? descriptionHi : descriptionEn;
      case AppLanguage.gujarati:
        return descriptionGu.isNotEmpty ? descriptionGu : descriptionEn;
      case AppLanguage.english:
        return descriptionEn;
    }
  }

  /// Whether this is marked as a major festival.
  bool get isMajor => importanceLevel.toLowerCase() == 'major';

  /// Whether this observance is marked as both a festival and a vrat.
  bool get isBoth {
    final cat = category.toLowerCase().trim();
    return cat == 'both' ||
        cat.contains('both') ||
        cat.contains('&') ||
        cat == 'festival_and_vrat' ||
        cat == 'festival_vrat';
  }

  /// Whether this observance is a festival.
  bool get isFestival {
    final cat = category.toLowerCase().trim();
    if (isBoth) return true;
    if (cat == 'festival') return true;
    return cat != 'vrat';
  }

  /// Whether this observance is a fasting day or vrat.
  bool get isVrat {
    final cat = category.toLowerCase().trim();
    if (isBoth) return true;
    if (cat == 'vrat') return true;
    if (isFasting) return true;
    return false;
  }
}
