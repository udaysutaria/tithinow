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
  });

  /// Factory constructor to parse a record from the WordPress REST API JSON response.
  factory FestivalRule.fromWordPressJson(Map<String, dynamic> json) {
    final id = json['id'] as int? ?? 0;
    final modifiedStr = json['modified'] as String?;
    final modified = modifiedStr != null ? DateTime.tryParse(modifiedStr) : null;

    final acf = (json['acf'] as Map<String, dynamic>?) ?? const {};

    // In case festival_id was left blank in ACF, fall back to the WordPress post slug
    final slug = json['slug'] as String? ?? '';
    final festivalId = (acf['festival_id'] as String?)?.trim().isNotEmpty == true
        ? (acf['festival_id'] as String).trim()
        : slug.replaceAll('-', '_');

    // Parse boolean from bool or int (ACF true_false sometimes yields 1/0 or true/false)
    final rawFasting = acf['is_fasting'];
    final bool isFasting = rawFasting is bool
        ? rawFasting
        : (rawFasting is int ? rawFasting == 1 : rawFasting == '1' || rawFasting == 'true');

    return FestivalRule(
      id: id,
      festivalId: festivalId,
      category: (acf['category'] as String?)?.trim() ?? 'festival',
      importanceLevel: (acf['importance_level'] as String?)?.trim() ?? 'major',
      isFasting: isFasting,
      nameEn: (acf['festival_name_en'] as String?)?.trim() ??
          (json['title'] is Map ? (json['title']['rendered'] as String? ?? '') : ''),
      nameHi: (acf['festival_name_hi'] as String?)?.trim() ?? '',
      nameGu: (acf['festival_name_gu'] as String?)?.trim() ?? '',
      descriptionEn: (acf['description_en'] as String?)?.trim() ?? '',
      descriptionHi: (acf['description_hi'] as String?)?.trim() ?? '',
      descriptionGu: (acf['description_gu'] as String?)?.trim() ?? '',
      eventType: (acf['event_type'] as String?)?.trim() ?? 'lunar_tithi',
      daySelectionRule: (acf['day_selection_rule'] as String?)?.trim() ?? 'udaya',
      lunarMonth: (acf['lunar_month'] as String?)?.trim(),
      paksha: (acf['paksha'] as String?)?.trim(),
      tithiNumber: acf['tithi_number'] is int
          ? acf['tithi_number'] as int
          : int.tryParse(acf['tithi_number']?.toString() ?? ''),
      solarMonth: (acf['solar_month'] as String?)?.trim(),
      nakshatraConstraint: (acf['nakshatra_constraint'] as String?)?.trim() == 'none'
          ? null
          : (acf['nakshatra_constraint'] as String?)?.trim(),
      regionVariant: (acf['region_variant'] as String?)?.trim() ?? 'national',
      ruleVersion: acf['rule_version'] is int
          ? acf['rule_version'] as int
          : (int.tryParse(acf['rule_version']?.toString() ?? '') ?? 1),
      modified: modified,
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
