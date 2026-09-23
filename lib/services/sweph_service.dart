import 'package:sweph/sweph.dart';
import '../constants/panchang_terms.dart';
import '../database/app_database.dart';
import '../models/city.dart';
import '../models/festival_rule.dart';
import '../widgets/organisms/list_tithis.dart' show TithiData, ItemTemporalState, ListItemTithi;

/// Calculation output encapsulating all astronomical and Pancha-Anga parameters for a given day.
class PanchangCalculationResult {
  final DateTime date;
  final City city;
  final DateTime sunrise;
  final DateTime sunset;
  final DateTime? moonrise;
  final DateTime? moonset;
  final Tithi tithi;
  final Paksha paksha;
  final int tithiNumber;
  final HinduMonth hinduMonth;
  final HinduMonth amantaMonth;
  final HinduMonth purnimantaMonth;
  final String lunarSystem;
  final Nakshatra nakshatra;
  final Yoga yoga;
  final Karana karana;
  final Rashi rashi; // Chandra Rashi (Moon sign)
  final Rashi suryaRashi; // Sun sign
  final List<FestivalRule> matchedFestivals;

  const PanchangCalculationResult({
    required this.date,
    required this.city,
    required this.sunrise,
    required this.sunset,
    this.moonrise,
    this.moonset,
    required this.tithi,
    required this.paksha,
    required this.tithiNumber,
    required this.hinduMonth,
    HinduMonth? amantaMonth,
    HinduMonth? purnimantaMonth,
    this.lunarSystem = 'purnimanta',
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.rashi,
    required this.suryaRashi,
    this.matchedFestivals = const [],
  })  : amantaMonth = amantaMonth ?? hinduMonth,
        purnimantaMonth = purnimantaMonth ?? hinduMonth;

  /// Formatted 12-hour strings for UI cards
  String get sunriseFormatted => _format12Hour(sunrise);
  String get sunsetFormatted => _format12Hour(sunset);
  String get moonriseFormatted {
    if (moonrise == null) return '--:--';
    final timeStr = _format12Hour(moonrise!);
    if (moonrise!.day != date.day) {
      return '$timeStr, ${_shortMonthEn(moonrise!)} ${moonrise!.day}';
    }
    return timeStr;
  }

  String get moonsetFormatted {
    if (moonset == null) return '--:--';
    final timeStr = _format12Hour(moonset!);
    if (moonset!.day != date.day) {
      return '$timeStr, ${_shortMonthEn(moonset!)} ${moonset!.day}';
    }
    return timeStr;
  }

  /// Primary festival (if any) matching this day
  FestivalRule? get primaryFestival {
    final list = matchedFestivals.where((f) => f.category == 'festival');
    return list.isNotEmpty ? list.first : null;
  }

  /// Primary vrat / fasting observance (if any) matching this day
  FestivalRule? get primaryVrat {
    final list = matchedFestivals.where((f) => f.isVrat);
    return list.isNotEmpty ? list.first : null;
  }

  static String _format12Hour(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$min $period';
  }

  static String _shortMonthEn(DateTime dt) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[dt.month - 1];
  }
}

/// Core calculation engine for high-precision Vedic Panchang based on Swiss Ephemeris.
///
/// Features:
/// - Initialized once with Lahiri Ayanamsha (`SE_SIDM_LAHIRI`).
/// - Evaluates exact topocentric planetary positions, tithi, nakshatra, yoga, karana, and rashis.
/// - Calculates topocentric sunrise, sunset, moonrise, and moonset for any city.
/// - Evaluates festival & vrat rules across Udaya, Nishita, Pradosha, and Punyakaal windows.
/// - Built-in in-memory caching for sub-millisecond calendar scrolling.
class SwephService {
  static final SwephService instance = SwephService._init();
  SwephService._init();

  static bool _isInitialized = false;

  /// Cache of pre-calculated results: key = "YYYY-MM-DD_cityId"
  final Map<String, PanchangCalculationResult> _cache = {};

  /// Cached calculation result for today's date for immediate display on app open.
  PanchangCalculationResult? cachedTodayResult;

  /// Ensures Swiss Ephemeris native library is initialized with Lahiri ayanamsha.
  Future<void> init() async {
    if (_isInitialized) return;
    await Sweph.init();
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
    _isInitialized = true;
  }

  /// Preloads today's panchang in the background during app startup/splash.
  Future<PanchangCalculationResult?> preloadTodayPanchang() async {
    try {
      await init();
      final city = await AppDatabase.instance.getSavedCity() ?? City.mumbai;
      final lunarSystem = await AppDatabase.instance.getSavedLunarSystem();
      final rules = await AppDatabase.instance.getAllFestivalRules();
      final now = DateTime.now();
      final result = await calculatePanchang(
        date: DateTime(now.year, now.month, now.day),
        city: city,
        lunarSystem: lunarSystem,
        festivalRules: rules,
      );
      cachedTodayResult = result;
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Clears the in-memory calculation cache (useful on city or rule changes).
  void clearCache() {
    _cache.clear();
    cachedTodayResult = null;
  }

  /// Calculates complete Pancha-Anga parameters for [date] at the given [city].
  ///
  /// Optionally evaluates against [festivalRules]. If null, queries [AppDatabase].
  Future<PanchangCalculationResult> calculatePanchang({
    required DateTime date,
    required City city,
    String? lunarSystem,
    List<FestivalRule>? festivalRules,
  }) async {
    await init();

    final effectiveSystem =
        (lunarSystem?.toLowerCase().trim() == 'amanta') ? 'amanta' : 'purnimanta';

    final dateKey =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${city.id}_$effectiveSystem';
    if (_cache.containsKey(dateKey) && festivalRules == null) {
      return _cache[dateKey]!;
    }

    // Determine observer location
    final geoPos = GeoPosition(city.longitude, city.latitude, 10.0);
    Sweph.swe_set_topo(city.longitude, city.latitude, 10.0);

    // Moshier ephemeris flag + Sidereal mode
    final flags = SwephFlag.SEFLG_MOSEPH | SwephFlag.SEFLG_SIDEREAL;

    // Local timezone offset (defaults to +5:30 for Indian subcontinental locations)
    final Duration tzOffset = _resolveTimezoneOffset(city);

    // 00:00 local time converted to UTC
    final localMidnight = DateTime(date.year, date.month, date.day);
    final utcMidnight = localMidnight.subtract(tzOffset);

    final jdMidnightUt = Sweph.swe_julday(
      utcMidnight.year,
      utcMidnight.month,
      utcMidnight.day,
      utcMidnight.hour + utcMidnight.minute / 60.0 + utcMidnight.second / 3600.0,
      CalendarType.SE_GREG_CAL,
    );

    // Standard atmospheric refraction (1013.25 mbar, 15°C) for accurate horizon events
    const double atPress = 1013.25;
    const double atTemp = 15.0;

    // 1. Calculate Sunrise & Sunset
    final riseJd = Sweph.swe_rise_trans(
      jdMidnightUt,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_MOSEPH,
      RiseSetTransitFlag.SE_CALC_RISE,
      geoPos,
      atPress,
      atTemp,
    );

    final setJd = Sweph.swe_rise_trans(
      jdMidnightUt,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_MOSEPH,
      RiseSetTransitFlag.SE_CALC_SET,
      geoPos,
      atPress,
      atTemp,
    );

    final DateTime sunrise;
    final DateTime sunset;

    if (riseJd != null) {
      final riseUtc = Sweph.swe_revjul(riseJd, CalendarType.SE_GREG_CAL);
      sunrise = riseUtc.add(tzOffset);
    } else {
      sunrise = DateTime(date.year, date.month, date.day, 6, 0);
    }

    if (setJd != null) {
      final setUtc = Sweph.swe_revjul(setJd, CalendarType.SE_GREG_CAL);
      sunset = setUtc.add(tzOffset);
    } else {
      sunset = DateTime(date.year, date.month, date.day, 18, 30);
    }

    // 2. Calculate Moonrise & Moonset
    // In Vedic Panchang, events are reckoned from Sunrise to Sunrise.
    // The Moonrise for this Panchang day occurs after Sunrise.
    final sunriseJdUt = riseJd ?? jdMidnightUt + 0.25;

    final moonriseJd = Sweph.swe_rise_trans(
      sunriseJdUt,
      HeavenlyBody.SE_MOON,
      SwephFlag.SEFLG_MOSEPH,
      RiseSetTransitFlag.SE_CALC_RISE,
      geoPos,
      atPress,
      atTemp,
    );

    // In Vedic Panchang, Moonset corresponds to the Moon that rose during the Panchang day (setting after Moonrise)
    final searchSetJd = moonriseJd ?? sunriseJdUt;
    final moonsetJd = Sweph.swe_rise_trans(
      searchSetJd,
      HeavenlyBody.SE_MOON,
      SwephFlag.SEFLG_MOSEPH,
      RiseSetTransitFlag.SE_CALC_SET,
      geoPos,
      atPress,
      atTemp,
    );

    DateTime? moonrise;
    DateTime? moonset;

    if (moonriseJd != null) {
      final mrUtc = Sweph.swe_revjul(moonriseJd, CalendarType.SE_GREG_CAL);
      moonrise = mrUtc.add(tzOffset);
    }
    if (moonsetJd != null) {
      final msUtc = Sweph.swe_revjul(moonsetJd, CalendarType.SE_GREG_CAL);
      moonset = msUtc.add(tzOffset);
    }

    // 3. Calculate Pancha-Anga prevailing at Sunrise (Udaya Lagna)
    final sunCoords = Sweph.swe_calc_ut(sunriseJdUt, HeavenlyBody.SE_SUN, flags);
    final moonCoords = Sweph.swe_calc_ut(sunriseJdUt, HeavenlyBody.SE_MOON, flags);

    // Elongation: (Moon - Sun) % 360
    final elongation = (moonCoords.longitude - sunCoords.longitude + 360.0) % 360.0;
    final tithiTotalIndex = (elongation / 12.0).floor() + 1; // 1 to 30

    final Paksha paksha = tithiTotalIndex <= 15 ? Paksha.shukla : Paksha.krishna;
    final int tithiNumber = tithiTotalIndex <= 15 ? tithiTotalIndex : tithiTotalIndex - 15;
    final Tithi tithi = Tithi.fromLunarDay(tithiTotalIndex);

    // Nakshatra: Moon Longitude / 13°20'
    final Nakshatra nakshatra = Nakshatra.fromLongitude(moonCoords.longitude);

    // Solilunar Yoga: (Moon + Sun) % 360 / 13°20'
    final Yoga yoga = Yoga.fromArc(moonCoords.longitude + sunCoords.longitude);

    // Karana: Half-tithi (6° slot)
    final int karanaSlot = (elongation / 6.0).floor() + 1;
    final Karana karana = Karana.fromSlot(karanaSlot);

    // Rashis
    final Rashi rashi = Rashi.fromDegrees(moonCoords.longitude);
    final Rashi suryaRashi = Rashi.fromDegrees(sunCoords.longitude);

    // Hindu Month:
    // In Amanta calendar, the lunar month is named after the Sun's Rashi at the preceding New Moon (Amavasya).
    final HinduMonth amantaMonth = _calculateHinduMonth(sunriseJdUt, elongation, flags);

    // In Purnimanta calendar, the month starts after Purnima.
    // In Shukla Paksha (waxing), Purnimanta month name is identical to Amanta.
    // In Krishna Paksha (waning), Purnimanta month is one month ahead (+1) of Amanta.
    final HinduMonth purnimantaMonth = paksha == Paksha.shukla
        ? amantaMonth
        : HinduMonth.values[(amantaMonth.index + 1) % 12];

    final HinduMonth hinduMonth =
        effectiveSystem == 'amanta' ? amantaMonth : purnimantaMonth;

    // 4. Evaluate Festival & Vrat Rules
    final matchedRules = _evaluateFestivalRules(
      date: date,
      sunrise: sunrise,
      sunset: sunset,
      tzOffset: tzOffset,
      flags: flags,
      sunriseJdUt: sunriseJdUt,
      hinduMonth: hinduMonth,
      amantaMonth: amantaMonth,
      purnimantaMonth: purnimantaMonth,
      paksha: paksha,
      tithiNumber: tithiNumber,
      nakshatra: nakshatra,
      suryaRashi: suryaRashi,
      rules: festivalRules ?? const [],
    );

    final result = PanchangCalculationResult(
      date: date,
      city: city,
      sunrise: sunrise,
      sunset: sunset,
      moonrise: moonrise,
      moonset: moonset,
      tithi: tithi,
      paksha: paksha,
      tithiNumber: tithiNumber,
      hinduMonth: hinduMonth,
      amantaMonth: amantaMonth,
      purnimantaMonth: purnimantaMonth,
      lunarSystem: effectiveSystem,
      nakshatra: nakshatra,
      yoga: yoga,
      karana: karana,
      rashi: rashi,
      suryaRashi: suryaRashi,
      matchedFestivals: matchedRules,
    );

    _cache[dateKey] = result;
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      cachedTodayResult = result;
    }
    return result;
  }

  /// Calculates Amanta Hindu month based on the Sun's Rashi at the preceding New Moon (Amavasya).
  HinduMonth _calculateHinduMonth(double sunriseJdUt, double currentElongation, SwephFlag flags) {
    // A synodic month is ~29.53 days, elongation progresses ~12.19 deg/day.
    final daysSinceAmavasya = currentElongation / 12.19075;
    double searchJd = sunriseJdUt - daysSinceAmavasya;

    // Refine to find exact Amavasya moment (elongation = 0) with Newton-Raphson iterations
    for (int i = 0; i < 4; i++) {
      final sun = Sweph.swe_calc_ut(searchJd, HeavenlyBody.SE_SUN, flags);
      final moon = Sweph.swe_calc_ut(searchJd, HeavenlyBody.SE_MOON, flags);
      double el = (moon.longitude - sun.longitude + 360.0) % 360.0;
      if (el > 180.0) el -= 360.0; // Angle difference
      searchJd -= el / 12.19075;
    }

    final sunAtAmavasya = Sweph.swe_calc_ut(searchJd, HeavenlyBody.SE_SUN, flags);
    final amavasyaRashi = Rashi.fromDegrees(sunAtAmavasya.longitude);

    // In Amanta calendar:
    // Sun in Meena (Pisces, index 11) at Amavasya -> Chaitra (index 0)
    // Sun in Mesha (Aries, index 0) at Amavasya -> Vaishakha (index 1)
    // ...
    // Sun in Simha (Leo, index 4) at Amavasya -> Bhadrapada (index 5)
    final monthIndex = (amavasyaRashi.index + 1) % 12;
    return HinduMonth.values[monthIndex];
  }

  /// Canonical lunar month pair (Amanta and Purnimanta) for known Krishna Paksha festivals.
  ///
  /// In the Hindu calendar, Amanta and Purnimanta systems use different month names
  /// for the exact same Krishna Paksha fortnight (Purnimanta month = Amanta month + 1).
  /// Canonical anchoring prevents a festival rule from matching in two consecutive months
  /// or matching the wrong month depending on active lunar system settings.
  static const Map<String, ({HinduMonth amanta, HinduMonth purnimanta})>
      _canonicalKrishnaFestivals = {
    'maha_shivaratri': (
      amanta: HinduMonth.magha,
      purnimanta: HinduMonth.phalguna,
    ),
    'krishna_janmashtami': (
      amanta: HinduMonth.shravana,
      purnimanta: HinduMonth.bhadrapada,
    ),
    'karwa_chauth': (
      amanta: HinduMonth.ashwin,
      purnimanta: HinduMonth.kartika,
    ),
    'ahoi_ashtami': (
      amanta: HinduMonth.ashwin,
      purnimanta: HinduMonth.kartika,
    ),
    'dhanteras': (
      amanta: HinduMonth.ashwin,
      purnimanta: HinduMonth.kartika,
    ),
    'naraka_chaturdashi': (
      amanta: HinduMonth.ashwin,
      purnimanta: HinduMonth.kartika,
    ),
    'diwali': (
      amanta: HinduMonth.ashwin,
      purnimanta: HinduMonth.kartika,
    ),
    'lakshmi_puja': (
      amanta: HinduMonth.ashwin,
      purnimanta: HinduMonth.kartika,
    ),
  };

  /// Evaluates which festival rules match the astronomical conditions of this date.
  List<FestivalRule> _evaluateFestivalRules({
    required DateTime date,
    required DateTime sunrise,
    required DateTime sunset,
    required Duration tzOffset,
    required SwephFlag flags,
    required double sunriseJdUt,
    required HinduMonth hinduMonth,
    HinduMonth? amantaMonth,
    HinduMonth? purnimantaMonth,
    required Paksha paksha,
    required int tithiNumber,
    required Nakshatra nakshatra,
    required Rashi suryaRashi,
    required List<FestivalRule> rules,
  }) {
    if (rules.isEmpty) return const [];

    final matched = <FestivalRule>[];

    for (final rule in rules) {
      if (rule.eventType == 'lunar_tithi') {
        // Match lunar month (or 'any')
        final ruleMonth = rule.lunarMonth?.toLowerCase().trim();
        if (ruleMonth != null && ruleMonth != 'any') {
          final canonical = _canonicalKrishnaFestivals[rule.festivalId];
          if (canonical != null) {
            // Anchor to the true canonical lunation (same across all traditions)
            if (amantaMonth != canonical.amanta ||
                purnimantaMonth != canonical.purnimanta) {
              continue;
            }
          } else {
            final isDirectMatch =
                ruleMonth == hinduMonth.name(AppLanguage.english).toLowerCase();
            final isAmantaMatch = amantaMonth != null &&
                ruleMonth == amantaMonth.name(AppLanguage.english).toLowerCase();
            final isPurnimantaMatch = purnimantaMonth != null &&
                ruleMonth == purnimantaMonth.name(AppLanguage.english).toLowerCase();
            if (!isDirectMatch && !isAmantaMatch && !isPurnimantaMatch) {
              continue;
            }
          }
        }

        // Match paksha (or 'both')
        final rulePaksha = rule.paksha?.toLowerCase().trim();
        final currentPakshaStr = paksha == Paksha.shukla ? 'shukla' : 'krishna';
        if (rulePaksha != null && rulePaksha != 'both' && rulePaksha != currentPakshaStr) {
          continue;
        }

        // Day selection rule override for Janmashtami:
        // Janmashtami calendar observance is anchored to Udaya Tithi (Ashtami at sunrise)
        // to match standard panchang practice and avoid Saptami-viddha daytimes.
        final effectiveDayRule = (rule.festivalId == 'krishna_janmashtami')
            ? 'udaya'
            : rule.daySelectionRule;

        // Check prevailing tithi and nakshatra at the rule's specific window
        final windowJd = _resolveWindowJulianDay(
          effectiveDayRule,
          sunrise: sunrise,
          sunset: sunset,
          tzOffset: tzOffset,
          sunriseJdUt: sunriseJdUt,
        );

        final sunAtWindow = Sweph.swe_calc_ut(windowJd, HeavenlyBody.SE_SUN, flags);
        final moonAtWindow = Sweph.swe_calc_ut(windowJd, HeavenlyBody.SE_MOON, flags);
        final elAtWindow = (moonAtWindow.longitude - sunAtWindow.longitude + 360.0) % 360.0;
        final tithiAtWindow = ((elAtWindow / 12.0).floor() % 15) + 1;

        if (rule.tithiNumber != null && rule.tithiNumber != tithiAtWindow) {
          continue;
        }

        // Nakshatra constraint (e.g. Rohini for Sri Jayanti).
        // Rohini is an auspicious attribute but does not block generic Krishna Janmashtami.
        final nakConstraint = rule.nakshatraConstraint?.toLowerCase().trim();
        if (nakConstraint != null &&
            nakConstraint != 'none' &&
            rule.festivalId != 'krishna_janmashtami') {
          final nakAtWindow = Nakshatra.fromLongitude(moonAtWindow.longitude);
          if (nakAtWindow.name(AppLanguage.english).toLowerCase() != nakConstraint) {
            continue;
          }
        }

        matched.add(rule);
      } else if (rule.eventType == 'solar_sankranti') {
        // Solar ingress (Sankranti) into specified solar month
        final targetRashi = _resolveRashiFromName(rule.solarMonth);
        if (targetRashi != null) {
          final targetLongitude = (targetRashi.index * 30.0) % 360.0;

          final daylightMinutes = sunset.difference(sunrise).inMinutes.toDouble();
          final sunsetJdUt = sunriseJdUt + (daylightMinutes / 1440.0);
          final nextSunriseJdUt = sunriseJdUt + 1.0;
          final yesterdaySunsetJdUt = sunriseJdUt - ((1440.0 - daylightMinutes) / 1440.0);

          final sunAtSunrise = Sweph.swe_calc_ut(sunriseJdUt, HeavenlyBody.SE_SUN, flags).longitude;
          final sunAtSunset = Sweph.swe_calc_ut(sunsetJdUt, HeavenlyBody.SE_SUN, flags).longitude;
          final sunAtNextSunrise = Sweph.swe_calc_ut(nextSunriseJdUt, HeavenlyBody.SE_SUN, flags).longitude;
          final sunAtYesterdaySunset = Sweph.swe_calc_ut(yesterdaySunsetJdUt, HeavenlyBody.SE_SUN, flags).longitude;

          // Ingress during today's daylight (sunrise to sunset)
          final ingressInDaylight = _isDegreeCrossed(sunAtSunrise, sunAtSunset, targetLongitude);

          // Ingress during last night (yesterday sunset to today sunrise)
          final ingressLastNight = _isDegreeCrossed(sunAtYesterdaySunset, sunAtSunrise, targetLongitude);

          // Ingress tonight after sunset (sunset to tomorrow sunrise)
          final ingressTonight = _isDegreeCrossed(sunAtSunset, sunAtNextSunrise, targetLongitude);

          final bool matches;
          if (rule.daySelectionRule.toLowerCase() == 'punyakaal') {
            // Under Punya Kaal rules:
            // - If ingress is during daytime, celebrate today.
            // - If ingress was last night after sunset, celebrate this morning.
            matches = ingressInDaylight || ingressLastNight;
          } else {
            // Standard Vedic day (sunrise to sunrise):
            matches = ingressInDaylight || ingressTonight;
          }

          if (matches) {
            matched.add(rule);
          }
        }
      }
    }

    return matched;
  }

  /// Calculates the Julian Day corresponding to a specific Vedic day selection window.
  double _resolveWindowJulianDay(
    String rule, {
    required DateTime sunrise,
    required DateTime sunset,
    required Duration tzOffset,
    required double sunriseJdUt,
  }) {
    switch (rule.toLowerCase()) {
      case 'nishita':
        // Local midnight: midpoint between sunset today and next sunrise (~sunset + 6 hours)
        final nishitaTime = sunset.add(const Duration(hours: 5, minutes: 30));
        final nishitaUtc = nishitaTime.subtract(tzOffset);
        return Sweph.swe_julday(
          nishitaUtc.year,
          nishitaUtc.month,
          nishitaUtc.day,
          nishitaUtc.hour + nishitaUtc.minute / 60.0,
          CalendarType.SE_GREG_CAL,
        );

      case 'pradosha':
        // Pradosha: Sunset to ~2h 24m after sunset
        final pradoshaTime = sunset.add(const Duration(hours: 1));
        final pradoshaUtc = pradoshaTime.subtract(tzOffset);
        return Sweph.swe_julday(
          pradoshaUtc.year,
          pradoshaUtc.month,
          pradoshaUtc.day,
          pradoshaUtc.hour + pradoshaUtc.minute / 60.0,
          CalendarType.SE_GREG_CAL,
        );

      case 'madhyahna':
        // Midday: midpoint between sunrise and sunset
        final middayDiff = sunset.difference(sunrise);
        final middayTime = sunrise.add(Duration(milliseconds: middayDiff.inMilliseconds ~/ 2));
        final middayUtc = middayTime.subtract(tzOffset);
        return Sweph.swe_julday(
          middayUtc.year,
          middayUtc.month,
          middayUtc.day,
          middayUtc.hour + middayUtc.minute / 60.0,
          CalendarType.SE_GREG_CAL,
        );

      case 'udaya':
      default:
        return sunriseJdUt;
    }
  }

  /// Checks whether the angle [targetDeg] is crossed in forward (direct) motion between [startDeg] and [endDeg].
  bool _isDegreeCrossed(double startDeg, double endDeg, double targetDeg) {
    final startRel = (startDeg - targetDeg + 360.0) % 360.0;
    final endRel = (endDeg - targetDeg + 360.0) % 360.0;
    return startRel > 180.0 && endRel < 180.0;
  }

  /// Resolves a [Rashi] enum from a string name (e.g. 'makara', 'mesha', etc.).
  Rashi? _resolveRashiFromName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final clean = name.toLowerCase().trim();
    for (final r in Rashi.values) {
      final rName = r.name(AppLanguage.english).toLowerCase();
      final rEnum = r.toString().split('.').last.toLowerCase();
      if (rEnum == clean ||
          rName.contains(clean) ||
          clean.contains(rEnum)) {
        return r;
      }
    }
    return null;
  }

  /// Resolves the timezone offset for the city (default +5:30 for Indian cities).
  Duration _resolveTimezoneOffset(City city) {
    // If city is in India (lat 6-37, lon 68-98), standard IST is +5:30
    if (city.latitude >= 6.0 &&
        city.latitude <= 38.0 &&
        city.longitude >= 68.0 &&
        city.longitude <= 98.0) {
      return const Duration(hours: 5, minutes: 30);
    }
    // Fall back to system timezone
    return DateTime.now().timeZoneOffset;
  }

  /// Fast calculation of Tithi, Paksha, lunar day, and matched festivals for calendar list views.
  TithiData calculateCalendarDay({
    required DateTime date,
    required City city,
    required DateTime today,
    String? lunarSystem,
    List<FestivalRule> festivalRules = const [],
    bool isAlarmActive = false,
  }) {
    // Determine observer location
    final Duration tzOffset = _resolveTimezoneOffset(city);

    // 06:00 local time converted to UTC
    final localMorning = DateTime(date.year, date.month, date.day, 6, 0);
    final utcMorning = localMorning.subtract(tzOffset);

    final jdUt = Sweph.swe_julday(
      utcMorning.year,
      utcMorning.month,
      utcMorning.day,
      utcMorning.hour + utcMorning.minute / 60.0,
      CalendarType.SE_GREG_CAL,
    );

    final flags = SwephFlag.SEFLG_MOSEPH | SwephFlag.SEFLG_SIDEREAL;
    final sunCoords = Sweph.swe_calc_ut(jdUt, HeavenlyBody.SE_SUN, flags);
    final moonCoords = Sweph.swe_calc_ut(jdUt, HeavenlyBody.SE_MOON, flags);

    final elongation = (moonCoords.longitude - sunCoords.longitude + 360.0) % 360.0;
    final tithiTotalIndex = (elongation / 12.0).floor() + 1; // 1 to 30

    final Paksha paksha = tithiTotalIndex <= 15 ? Paksha.shukla : Paksha.krishna;
    final int tithiNumber = tithiTotalIndex <= 15 ? tithiTotalIndex : tithiTotalIndex - 15;
    final Tithi tithi = Tithi.fromLunarDay(tithiTotalIndex);

    final itemDate = DateTime(date.year, date.month, date.day);
    final ItemTemporalState state;
    if (itemDate.isBefore(today)) {
      state = ItemTemporalState.past;
    } else if (itemDate.isAfter(today)) {
      state = ItemTemporalState.future;
    } else {
      state = ItemTemporalState.current;
    }

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateString =
        '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';

    String vrat = 'No Vrat';
    String festival = 'No Festival';

    if (festivalRules.isNotEmpty) {
      final HinduMonth amantaMonth = _calculateHinduMonth(jdUt, elongation, flags);
      final HinduMonth purnimantaMonth = paksha == Paksha.shukla
          ? amantaMonth
          : HinduMonth.values[(amantaMonth.index + 1) % 12];
      final effectiveSystem = (lunarSystem?.toLowerCase().trim() == 'amanta') ? 'amanta' : 'purnimanta';
      final HinduMonth hinduMonth = effectiveSystem == 'amanta' ? amantaMonth : purnimantaMonth;

      final Nakshatra nakshatra = Nakshatra.fromLongitude(moonCoords.longitude);
      final Rashi suryaRashi = Rashi.fromDegrees(sunCoords.longitude);

      final matched = _evaluateFestivalRules(
        date: date,
        sunrise: DateTime(date.year, date.month, date.day, 6, 0),
        sunset: DateTime(date.year, date.month, date.day, 18, 30),
        tzOffset: tzOffset,
        flags: flags,
        sunriseJdUt: jdUt,
        hinduMonth: hinduMonth,
        amantaMonth: amantaMonth,
        purnimantaMonth: purnimantaMonth,
        paksha: paksha,
        tithiNumber: tithiNumber,
        nakshatra: nakshatra,
        suryaRashi: suryaRashi,
        rules: festivalRules,
      );

      for (final rule in matched) {
        if (rule.isVrat && vrat == 'No Vrat') {
          vrat = rule.nameEn;
        }
        if (rule.isFestival && festival == 'No Festival') {
          festival = rule.nameEn;
        }
      }
    }

    return TithiData(
      date: dateString,
      dateTime: itemDate,
      tithi: tithi.name(AppLanguage.english),
      paksha: paksha.name(AppLanguage.english),
      vrat: vrat,
      festival: festival,
      lunarDay: tithiTotalIndex,
      moonPhaseAsset: ListItemTithi.getMoonAsset(tithiTotalIndex),
      state: state,
      isAlarmActive: isAlarmActive,
    );
  }

  /// Calculates a batch list of [TithiData] for multiple dates.
  Future<List<TithiData>> calculateCalendarRange({
    required List<DateTime> dates,
    required City city,
    required DateTime today,
    String? lunarSystem,
    List<FestivalRule> festivalRules = const [],
  }) async {
    await init();
    return List<TithiData>.generate(
      dates.length,
      (i) {
        final date = dates[i];
        return calculateCalendarDay(
          date: date,
          city: city,
          today: today,
          lunarSystem: lunarSystem,
          festivalRules: festivalRules,
          isAlarmActive: false,
        );
      },
      growable: false,
    );
  }
}
