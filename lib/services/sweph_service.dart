import 'package:flutter/widgets.dart';
import 'package:sweph/sweph.dart';
import '../constants/muhurta_data.dart';
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
  final bool isAdhikaMasa;
  final String lunarSystem;
  final Nakshatra nakshatra;
  final Yoga yoga;
  final Karana karana;
  final Rashi rashi; // Chandra Rashi (Moon sign)
  final Rashi suryaRashi; // Sun sign
  final List<FestivalRule> matchedFestivals;
  final List<MuhurtaInterval> muhurtaIntervals;

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
    this.isAdhikaMasa = false,
    this.lunarSystem = 'purnimanta',
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.rashi,
    required this.suryaRashi,
    this.matchedFestivals = const [],
    this.muhurtaIntervals = const [],
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
    final list = matchedFestivals.where((f) => f.isFestival);
    return list.isNotEmpty ? list.first : null;
  }

  /// Primary vrat / fasting observance (if any) matching this day
  FestivalRule? get primaryVrat {
    final list = matchedFestivals.where((f) => f.isVrat);
    return list.isNotEmpty ? list.first : null;
  }

  /// All festivals matching this day
  List<FestivalRule> get festivals =>
      matchedFestivals.where((f) => f.isFestival).toList();

  /// All vrats / fasting observances matching this day
  List<FestivalRule> get vrats =>
      matchedFestivals.where((f) => f.isVrat).toList();

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

  Future<PanchangCalculationResult?>? _activePreload;

  /// Preloads today's panchang in the background during app startup/splash.
  Future<PanchangCalculationResult?> preloadTodayPanchang() async {
    if (cachedTodayResult != null) return cachedTodayResult;
    if (_activePreload != null) return _activePreload!;

    final future = _performPreloadTodayPanchang();
    _activePreload = future;
    try {
      return await future;
    } finally {
      _activePreload = null;
    }
  }

  Future<PanchangCalculationResult?> _performPreloadTodayPanchang() async {
    try {
      await init();
      final city = await AppDatabase.instance.getSavedCity() ?? City.mumbai;
      final lunarSystem = await AppDatabase.instance.getSavedLunarSystem();
      final rules = await AppDatabase.instance.getAllFestivalRules();
      if (rules.isNotEmpty) {
        FestivalRule.registerRules(rules);
      }
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

    // Standard atmospheric refraction (1013.25 mbar, 15°C) for accurate horizon events
    const double atPress = 1013.25;
    const double atTemp = 15.0;

    // 1. Calculate Sunrise & Sunset
    final sunTimes = _calculateSunTimes(
      date: date,
      city: city,
      tzOffset: tzOffset,
    );
    final sunrise = sunTimes.sunrise;
    final sunset = sunTimes.sunset;
    final nextSunrise = sunTimes.nextSunrise;
    final sunriseJdUt = sunTimes.sunriseJdUt;
    final sunsetJdUt = sunTimes.sunsetJdUt;
    final nextSunriseJdUt = sunTimes.nextSunriseJdUt;

    DateTime toLocalTime(DateTime utc) {
      final shifted = utc.add(tzOffset);
      return DateTime(
        shifted.year,
        shifted.month,
        shifted.day,
        shifted.hour,
        shifted.minute,
        shifted.second,
        shifted.millisecond,
        shifted.microsecond,
      );
    }

    // 2. Calculate Moonrise & Moonset
    // In Vedic Panchang, events are reckoned from Sunrise to Sunrise.
    // The Moonrise for this Panchang day occurs after Sunrise.

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
      moonrise = toLocalTime(mrUtc);
    }
    if (moonsetJd != null) {
      final msUtc = Sweph.swe_revjul(moonsetJd, CalendarType.SE_GREG_CAL);
      moonset = toLocalTime(msUtc);
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
    final amantaInfo = _calculateAmantaMonthAndAdhika(sunriseJdUt, elongation, flags);
    final HinduMonth amantaMonth = amantaInfo.month;
    final bool isAdhikaMasa = amantaInfo.isAdhika;

    // In Purnimanta calendar, the month starts after Purnima.
    // In Shukla Paksha (waxing), Purnimanta month name is identical to Amanta.
    // In Krishna Paksha (waning), Purnimanta month is one month ahead (+1) of Amanta.
    final HinduMonth purnimantaMonth = paksha == Paksha.shukla
        ? amantaMonth
        : HinduMonth.values[(amantaMonth.index + 1) % 12];

    final HinduMonth hinduMonth =
        effectiveSystem == 'amanta' ? amantaMonth : purnimantaMonth;

    if (festivalRules != null && festivalRules.isNotEmpty) {
      FestivalRule.registerRules(festivalRules);
    }

    // 4. Evaluate Festival & Vrat Rules
    final matchedRules = _evaluateFestivalRules(
      date: date,
      sunrise: sunrise,
      sunset: sunset,
      tzOffset: tzOffset,
      flags: flags,
      sunriseJdUt: sunriseJdUt,
      sunsetJdUt: sunsetJdUt,
      nextSunriseJdUt: nextSunriseJdUt,
      hinduMonth: hinduMonth,
      amantaMonth: amantaMonth,
      purnimantaMonth: purnimantaMonth,
      isAdhikaMasa: isAdhikaMasa,
      paksha: paksha,
      tithiNumber: tithiNumber,
      nakshatra: nakshatra,
      suryaRashi: suryaRashi,
      rules: festivalRules ?? const [],
    );

    // 5. Generate Muhurta intervals matching classical Vedic Drik-Ganita rules
    final muhurtaIntervals = MuhurtaData.generateIntervals(
      date: date,
      sunriseDateTime: sunrise,
      sunsetDateTime: sunset,
      nextSunriseDateTime: nextSunrise,
      city: city,
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
      isAdhikaMasa: isAdhikaMasa,
      lunarSystem: effectiveSystem,
      nakshatra: nakshatra,
      yoga: yoga,
      karana: karana,
      rashi: rashi,
      suryaRashi: suryaRashi,
      matchedFestivals: matchedRules,
      muhurtaIntervals: muhurtaIntervals,
    );

    _cache[dateKey] = result;
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      cachedTodayResult = result;
    }
    return result;
  }

  /// Calculates Amanta Hindu month and evaluates whether it is an Adhika Masa (intercalary month).
  ({HinduMonth month, bool isAdhika}) _calculateAmantaMonthAndAdhika(
    double sunriseJdUt,
    double currentElongation,
    SwephFlag flags,
  ) {
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
    final month = HinduMonth.values[monthIndex];

    // Find next Amavasya:
    double nextAmavasyaJd = searchJd + 29.53059;
    for (int i = 0; i < 4; i++) {
      final sun = Sweph.swe_calc_ut(nextAmavasyaJd, HeavenlyBody.SE_SUN, flags);
      final moon = Sweph.swe_calc_ut(nextAmavasyaJd, HeavenlyBody.SE_MOON, flags);
      double el = (moon.longitude - sun.longitude + 360.0) % 360.0;
      if (el > 180.0) el -= 360.0;
      nextAmavasyaJd -= el / 12.19075;
    }
    final sunAtNextAmavasya = Sweph.swe_calc_ut(nextAmavasyaJd, HeavenlyBody.SE_SUN, flags);
    final nextAmavasyaRashi = Rashi.fromDegrees(sunAtNextAmavasya.longitude);

    // If Sun did not transition into a new Rashi between Amavasya 1 and Amavasya 2,
    // this month has no Sankranti and is an Adhika Masa!
    final bool isAdhika = (amavasyaRashi == nextAmavasyaRashi);

    return (month: month, isAdhika: isAdhika);
  }

  /// Calculates Amanta Hindu month based on the Sun's Rashi at the preceding New Moon (Amavasya).
  HinduMonth calculateHinduMonth(double sunriseJdUt, double currentElongation, SwephFlag flags) {
    return _calculateAmantaMonthAndAdhika(sunriseJdUt, currentElongation, flags).month;
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

  /// Computes accurate sunrise, sunset, and next sunrise times and Julian Days (UT).
  ({
    DateTime sunrise,
    DateTime sunset,
    DateTime nextSunrise,
    double sunriseJdUt,
    double sunsetJdUt,
    double nextSunriseJdUt,
  }) _calculateSunTimes({
    required DateTime date,
    required City city,
    required Duration tzOffset,
    bool needSunset = true,
  }) {
    final localMidnight = DateTime(date.year, date.month, date.day);
    final utcMidnight = localMidnight.subtract(tzOffset);
    final jdMidnightUt = Sweph.swe_julday(
      utcMidnight.year,
      utcMidnight.month,
      utcMidnight.day,
      utcMidnight.hour + utcMidnight.minute / 60.0 + utcMidnight.second / 3600.0,
      CalendarType.SE_GREG_CAL,
    );
    final geoPos = GeoPosition(city.longitude, city.latitude, 10.0);
    Sweph.swe_set_topo(city.longitude, city.latitude, 10.0);
    const double atPress = 1013.25;
    const double atTemp = 15.0;

    final riseJd = Sweph.swe_rise_trans(
      jdMidnightUt,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_MOSEPH,
      RiseSetTransitFlag.SE_CALC_RISE,
      geoPos,
      atPress,
      atTemp,
    );

    final setJd = needSunset
        ? Sweph.swe_rise_trans(
            jdMidnightUt,
            HeavenlyBody.SE_SUN,
            SwephFlag.SEFLG_MOSEPH,
            RiseSetTransitFlag.SE_CALC_SET,
            geoPos,
            atPress,
            atTemp,
          )
        : null;

    DateTime toLocalTime(DateTime utc) {
      final shifted = utc.add(tzOffset);
      return DateTime(
        shifted.year,
        shifted.month,
        shifted.day,
        shifted.hour,
        shifted.minute,
        shifted.second,
        shifted.millisecond,
        shifted.microsecond,
      );
    }

    final effectiveRiseJd = riseJd ?? (jdMidnightUt + (6.0 - tzOffset.inMinutes / 60.0) / 24.0);
    final effectiveSetJd = setJd ?? (effectiveRiseJd + (12.5 / 24.0));
    final effectiveNextRiseJd = effectiveRiseJd + 1.0;

    final sunrise = riseJd != null
        ? toLocalTime(Sweph.swe_revjul(riseJd, CalendarType.SE_GREG_CAL))
        : DateTime(date.year, date.month, date.day, 6, 0);
    final sunset = setJd != null
        ? toLocalTime(Sweph.swe_revjul(setJd, CalendarType.SE_GREG_CAL))
        : sunrise.add(const Duration(hours: 12, minutes: 30));
    final nextSunrise = sunrise.add(const Duration(days: 1));

    return (
      sunrise: sunrise,
      sunset: sunset,
      nextSunrise: nextSunrise,
      sunriseJdUt: effectiveRiseJd,
      sunsetJdUt: effectiveSetJd,
      nextSunriseJdUt: effectiveNextRiseJd,
    );
  }

  /// Calculates sidereal Sun and Moon elongation in degrees (0 to 360).
  double _calculateElongation(double jd, SwephFlag flags) {
    final sun = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, flags);
    final moon = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, flags);
    return (moon.longitude - sun.longitude + 360.0) % 360.0;
  }

  /// Resolves the Julian Day UT start and end span for a Muhurta / day selection rule.
  ({double startJd, double endJd}) _resolveWindowSpan(
    String ruleStr, {
    required double sunriseJdUt,
    required double sunsetJdUt,
    required double nextSunriseJdUt,
  }) {
    final clean = ruleStr.toLowerCase().trim();
    final dayDuration = sunsetJdUt - sunriseJdUt;
    final nightDuration = nextSunriseJdUt - sunsetJdUt;

    if (clean.contains('aparahna') || clean.contains('aparahnna') || clean.contains('afternoon')) {
      // Aparahna: 4th part of 5-fold daytime division (0.6 to 0.8 of day)
      return (
        startJd: sunriseJdUt + 0.6 * dayDuration,
        endJd: sunriseJdUt + 0.8 * dayDuration,
      );
    }

    if (clean.contains('arunodaya') || clean.contains('arunoday')) {
      // Arunodaya: 4 Ghatikas (96 minutes) before sunrise
      return (
        startJd: sunriseJdUt - (96.0 / 1440.0),
        endJd: sunriseJdUt,
      );
    }

    if (clean.contains('pradosh')) {
      // Pradosha: 6 Ghatikas (144 minutes) after sunset
      return (
        startJd: sunsetJdUt,
        endJd: sunsetJdUt + (144.0 / 1440.0),
      );
    }

    if (clean.contains('madhyahna') || clean.contains('madhyan') || clean.contains('midday') || clean.contains('noon')) {
      // Madhyahna: 3rd part of 5-fold daytime division (0.4 to 0.6 of day)
      return (
        startJd: sunriseJdUt + 0.4 * dayDuration,
        endJd: sunriseJdUt + 0.6 * dayDuration,
      );
    }

    if (clean.contains('nishita') || clean.contains('nishitha') || clean.contains('midnight')) {
      // Nishita: 8th Muhurta of the night (centered at midnight)
      final midNightJd = sunsetJdUt + 0.5 * nightDuration;
      final muhurtaLen = nightDuration / 15.0;
      return (
        startJd: midNightJd - 0.5 * muhurtaLen,
        endJd: midNightJd + 0.5 * muhurtaLen,
      );
    }

    if (clean.contains('sayahna') || clean.contains('sayankal') || clean.contains('evening')) {
      // Sayahna: 5th part of 5-fold daytime division (0.8 to 1.0 of day)
      return (
        startJd: sunriseJdUt + 0.8 * dayDuration,
        endJd: sunsetJdUt,
      );
    }

    if (clean.contains('purvahna') || clean.contains('morning')) {
      // Purvahna: 1st/2nd part of daytime division (0.0 to 0.4 of day)
      return (
        startJd: sunriseJdUt,
        endJd: sunriseJdUt + 0.4 * dayDuration,
      );
    }

    if (clean.contains('astachala') || clean.contains('sunset')) {
      // Astachala: Sunset (+/- 24 minutes)
      return (
        startJd: sunsetJdUt - (24.0 / 1440.0),
        endJd: sunsetJdUt + (24.0 / 1440.0),
      );
    }

    // Default: Udaya (at sunrise instant)
    return (
      startJd: sunriseJdUt,
      endJd: sunriseJdUt,
    );
  }

  /// Computes the overlap duration in minutes of [targetTithiNumber] (1..15) and [targetPaksha]
  /// within the time window [[startJd], [endJd]].
  double _getTithiOverlapMinutes({
    required double startJd,
    required double endJd,
    required int targetTithiNumber,
    required String? targetPaksha,
    required SwephFlag flags,
  }) {
    final windowDurationMins = (endJd - startJd) * 1440.0;
    if (windowDurationMins <= 0.001) {
      // Instantaneous check (e.g. Udaya at sunrise)
      final el = _calculateElongation(startJd, flags);
      final lunarDay = (el / 12.0).floor() + 1; // 1 to 30
      final tithiNum = lunarDay <= 15 ? lunarDay : lunarDay - 15;
      final pakshaStr = lunarDay <= 15 ? 'shukla' : 'krishna';
      final matchesPaksha = targetPaksha == null ||
          targetPaksha == 'both' ||
          targetPaksha.toLowerCase().trim() == pakshaStr;
      return (tithiNum == targetTithiNumber && matchesPaksha) ? 1.0 : 0.0;
    }

    final el1 = _calculateElongation(startJd, flags);
    final el2 = _calculateElongation(endJd, flags);

    final l1 = (el1 / 12.0).floor() + 1;
    final l2 = (el2 / 12.0).floor() + 1;

    final t1 = l1 <= 15 ? l1 : l1 - 15;
    final p1 = l1 <= 15 ? 'shukla' : 'krishna';

    final t2 = l2 <= 15 ? l2 : l2 - 15;
    final p2 = l2 <= 15 ? 'shukla' : 'krishna';

    final normPaksha = targetPaksha?.toLowerCase().trim();
    final bool matchPaksha1 = normPaksha == null || normPaksha == 'both' || normPaksha == p1;
    final bool matchPaksha2 = normPaksha == null || normPaksha == 'both' || normPaksha == p2;

    final matchesStart = (t1 == targetTithiNumber && matchPaksha1);
    final matchesEnd = (t2 == targetTithiNumber && matchPaksha2);

    if (matchesStart && matchesEnd) {
      // Prevails for the entire window
      return windowDurationMins;
    }

    // Delta elongation across window (with 360 wrap-around)
    final deltaEl = (el2 - el1 + 360.0) % 360.0;
    if (deltaEl <= 0.0001) {
      return matchesStart ? windowDurationMins : 0.0;
    }

    if (matchesStart && !matchesEnd) {
      // Tithi ended inside the window
      final endAngle = (l1 * 12.0) % 360.0;
      final coveredEl = (endAngle - el1 + 360.0) % 360.0;
      final fraction = (coveredEl / deltaEl).clamp(0.0, 1.0);
      return fraction * windowDurationMins;
    }

    if (!matchesStart && matchesEnd) {
      // Tithi started inside the window
      final startAngle = ((l2 - 1) * 12.0) % 360.0;
      final coveredEl = (el2 - startAngle + 360.0) % 360.0;
      final fraction = (coveredEl / deltaEl).clamp(0.0, 1.0);
      return fraction * windowDurationMins;
    }

    return 0.0;
  }

  /// Evaluates which festival rules match the astronomical conditions of this date.
  List<FestivalRule> _evaluateFestivalRules({
    required DateTime date,
    required DateTime sunrise,
    required DateTime sunset,
    required Duration tzOffset,
    required SwephFlag flags,
    required double sunriseJdUt,
    double? sunsetJdUt,
    double? nextSunriseJdUt,
    required HinduMonth hinduMonth,
    HinduMonth? amantaMonth,
    HinduMonth? purnimantaMonth,
    bool isAdhikaMasa = false,
    required Paksha paksha,
    required int tithiNumber,
    required Nakshatra nakshatra,
    required Rashi suryaRashi,
    required List<FestivalRule> rules,
  }) {
    if (rules.isEmpty) return const [];

    final effectiveSunsetJdUt = sunsetJdUt ??
        (sunriseJdUt + (sunset.difference(sunrise).inMinutes / 1440.0));
    final effectiveNextSunriseJdUt =
        nextSunriseJdUt ?? (sunriseJdUt + 1.0);

    final matched = <FestivalRule>[];

    for (final rule in rules) {
      if (rule.eventType == 'lunar_tithi') {
        // 1. Adhika Masa policy check
        final adhikaPolicy = rule.adhikaMasaPolicy?.toLowerCase().trim();
        if (adhikaPolicy == 'adhika_only' && !isAdhikaMasa) {
          continue;
        }
        if (adhikaPolicy == 'nija_only' && isAdhikaMasa) {
          continue;
        }

        // 2. Match lunar month (or 'any')
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
            final isDirectMatch = _matchesMonthName(ruleMonth, hinduMonth);
            final isAmantaMatch = amantaMonth != null &&
                _matchesMonthName(ruleMonth, amantaMonth);
            final rulePurnimanta = rule.purnimantaMonth?.toLowerCase().trim();
            final isPurnimantaMatch = rulePurnimanta != null &&
                purnimantaMonth != null &&
                _matchesMonthName(rulePurnimanta, purnimantaMonth);
            if (!isDirectMatch && !isAmantaMatch && !isPurnimantaMatch) {
              continue;
            }
          }
        }

        // Day selection rule override for Janmashtami:
        // Janmashtami calendar observance is anchored to Udaya Tithi (Ashtami at sunrise)
        // to match standard panchang practice and avoid Saptami-viddha daytimes.
        final effectiveDayRule = (rule.festivalId == 'krishna_janmashtami')
            ? 'udaya'
            : rule.daySelectionRule;

        final cleanDayRule = effectiveDayRule.toLowerCase().trim();
        final isUdaya = cleanDayRule == 'udaya' ||
            cleanDayRule == 'sunrise' ||
            cleanDayRule.isEmpty;

        if (isUdaya) {
          // Match paksha (or 'both') for Udaya Tithi
          final rulePaksha = rule.paksha?.toLowerCase().trim();
          final currentPakshaStr = paksha == Paksha.shukla ? 'shukla' : 'krishna';
          if (rulePaksha != null && rulePaksha != 'both' && rulePaksha != currentPakshaStr) {
            continue;
          }

          // Prevailing tithi at Sunrise
          if (rule.tithiNumber != null && rule.tithiNumber != tithiNumber) {
            continue;
          }

          // Ekadashi avoid_viddha check
          final tieRule = rule.tieBreakRule?.toLowerCase().trim() ?? '';
          if (tieRule.contains('viddha') && rule.tithiNumber == 11) {
            final arunodayaJd = sunriseJdUt - (96.0 / 1440.0);
            final elAtArunodaya = _calculateElongation(arunodayaJd, flags);
            final tithiAtArunodaya = ((elAtArunodaya / 12.0).floor() % 15) + 1;

            if (tithiAtArunodaya == 10) {
              continue; // Avoid Dashami contamination at Arunodaya
            }
          }

          // Udaya tie break rules (e.g. Vridhi tithi spanning two consecutive sunrises)
          if (tieRule.contains('first')) {
            final yesterdaySunriseJd = sunriseJdUt - 1.0;
            final yEl = _calculateElongation(yesterdaySunriseJd, flags);
            final yLunarDay = (yEl / 12.0).floor() + 1;
            final yTithiNum = yLunarDay <= 15 ? yLunarDay : yLunarDay - 15;
            final yPaksha = yLunarDay <= 15 ? 'shukla' : 'krishna';
            final yMatchesPaksha = rulePaksha == null || rulePaksha == 'both' || rulePaksha == yPaksha;
            if (yTithiNum == rule.tithiNumber && yMatchesPaksha) {
              continue; // Already observed on first day
            }
          } else if (tieRule.contains('second')) {
            final tomorrowSunriseJd = effectiveNextSunriseJdUt;
            final tEl = _calculateElongation(tomorrowSunriseJd, flags);
            final tLunarDay = (tEl / 12.0).floor() + 1;
            final tTithiNum = tLunarDay <= 15 ? tLunarDay : tLunarDay - 15;
            final tPaksha = tLunarDay <= 15 ? 'shukla' : 'krishna';
            final tMatchesPaksha = rulePaksha == null || rulePaksha == 'both' || rulePaksha == tPaksha;
            if (tTithiNum == rule.tithiNumber && tMatchesPaksha) {
              continue; // Defer to second day
            }
          }

          // Nakshatra constraint
          final nakConstraint = rule.nakshatraConstraint?.toLowerCase().trim();
          if (nakConstraint != null &&
              nakConstraint != 'none' &&
              rule.festivalId != 'krishna_janmashtami') {
            final moonAtSunrise = Sweph.swe_calc_ut(sunriseJdUt, HeavenlyBody.SE_MOON, flags);
            final nakAtSunrise = Nakshatra.fromLongitude(moonAtSunrise.longitude);
            if (nakAtSunrise.name(AppLanguage.english).toLowerCase() != nakConstraint) {
              continue;
            }
          }

          matched.add(rule);
        } else {
          // Window-based day selection rule (aparahnna, pradosha, arunodaya, madhyahna, nishita, sayahna)
          if (rule.tithiNumber == null) {
            continue;
          }

          final todaySpan = _resolveWindowSpan(
            cleanDayRule,
            sunriseJdUt: sunriseJdUt,
            sunsetJdUt: effectiveSunsetJdUt,
            nextSunriseJdUt: effectiveNextSunriseJdUt,
          );

          final todayOverlap = _getTithiOverlapMinutes(
            startJd: todaySpan.startJd,
            endJd: todaySpan.endJd,
            targetTithiNumber: rule.tithiNumber!,
            targetPaksha: rule.paksha,
            flags: flags,
          );

          if (todayOverlap <= 0.0) {
            continue;
          }

          // Compute yesterday's and tomorrow's overlap to resolve tie breaks
          final yesterdaySunriseJd = sunriseJdUt - 1.0;
          final yesterdaySunsetJd = effectiveSunsetJdUt - 1.0;
          final tomorrowSunriseJd = effectiveNextSunriseJdUt;
          final tomorrowSunsetJd = effectiveSunsetJdUt + 1.0;

          final yesterdaySpan = _resolveWindowSpan(
            cleanDayRule,
            sunriseJdUt: yesterdaySunriseJd,
            sunsetJdUt: yesterdaySunsetJd,
            nextSunriseJdUt: sunriseJdUt,
          );
          final tomorrowSpan = _resolveWindowSpan(
            cleanDayRule,
            sunriseJdUt: tomorrowSunriseJd,
            sunsetJdUt: tomorrowSunsetJd,
            nextSunriseJdUt: tomorrowSunriseJd + 1.0,
          );

          final yesterdayOverlap = _getTithiOverlapMinutes(
            startJd: yesterdaySpan.startJd,
            endJd: yesterdaySpan.endJd,
            targetTithiNumber: rule.tithiNumber!,
            targetPaksha: rule.paksha,
            flags: flags,
          );
          final tomorrowOverlap = _getTithiOverlapMinutes(
            startJd: tomorrowSpan.startJd,
            endJd: tomorrowSpan.endJd,
            targetTithiNumber: rule.tithiNumber!,
            targetPaksha: rule.paksha,
            flags: flags,
          );

          final tieRule = rule.tieBreakRule?.toLowerCase().trim() ?? '';
          final hasYesterdayOverlap = yesterdayOverlap > 0.0;
          final hasTomorrowOverlap = tomorrowOverlap > 0.0;

          if (hasYesterdayOverlap || hasTomorrowOverlap) {
            if (tieRule.contains('first')) {
              // First day: if tithi prevailed in window yesterday, today is 2nd day -> skip!
              if (hasYesterdayOverlap) {
                continue;
              }
            } else if (tieRule.contains('second')) {
              // Second day: if tithi prevails in window tomorrow, today is 1st day -> skip!
              if (hasTomorrowOverlap) {
                continue;
              }
            } else if (tieRule.contains('longer') || tieRule.contains('vyapti') || tieRule.contains('overlap')) {
              // Day with longer overlap / higher vyapti
              if (yesterdayOverlap >= todayOverlap) {
                continue;
              }
              if (tomorrowOverlap > todayOverlap) {
                continue;
              }
            } else {
              // Classical Dharmashastra default: pick day with longer overlap; if equal, first day
              if (yesterdayOverlap > todayOverlap) {
                continue;
              }
              if (tomorrowOverlap > todayOverlap) {
                continue;
              }
              if (hasYesterdayOverlap && yesterdayOverlap >= todayOverlap) {
                continue;
              }
            }
          }

          // Ekadashi avoid_viddha check if applicable
          if (tieRule.contains('viddha') && rule.tithiNumber == 11) {
            final arunodayaJd = sunriseJdUt - (96.0 / 1440.0);
            final elAtArunodaya = _calculateElongation(arunodayaJd, flags);
            final tithiAtArunodaya = ((elAtArunodaya / 12.0).floor() % 15) + 1;
            if (tithiAtArunodaya == 10) {
              continue;
            }
          }

          // Nakshatra constraint
          final nakConstraint = rule.nakshatraConstraint?.toLowerCase().trim();
          if (nakConstraint != null &&
              nakConstraint != 'none' &&
              rule.festivalId != 'krishna_janmashtami') {
            final windowMidJd = (todaySpan.startJd + todaySpan.endJd) / 2.0;
            final moonAtWindow = Sweph.swe_calc_ut(windowMidJd, HeavenlyBody.SE_MOON, flags);
            final nakAtWindow = Nakshatra.fromLongitude(moonAtWindow.longitude);
            if (nakAtWindow.name(AppLanguage.english).toLowerCase() != nakConstraint) {
              continue;
            }
          }

          matched.add(rule);
        }
      } else if (rule.eventType == 'solar_sankranti') {
        // Solar ingress (Sankranti) into specified solar month
        final targetRashi = _resolveRashiFromName(rule.solarMonth);
        if (targetRashi != null) {
          final targetLongitude = (targetRashi.index * 30.0) % 360.0;

          final daylightMinutes = sunset.difference(sunrise).inMinutes.toDouble();
          final sunsetJdUt = effectiveSunsetJdUt;
          final nextSunriseJdUt = effectiveNextSunriseJdUt;
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
  double resolveWindowJulianDay(
    String rule, {
    required DateTime sunrise,
    required DateTime sunset,
    required Duration tzOffset,
    required double sunriseJdUt,
    double? sunsetJdUt,
    double? nextSunriseJdUt,
  }) {
    final sJd = sunsetJdUt ??
        (sunriseJdUt + (sunset.difference(sunrise).inMinutes / 1440.0));
    final nJd = nextSunriseJdUt ?? (sunriseJdUt + 1.0);
    final span = _resolveWindowSpan(
      rule,
      sunriseJdUt: sunriseJdUt,
      sunsetJdUt: sJd,
      nextSunriseJdUt: nJd,
    );
    return (span.startJd + span.endJd) / 2.0;
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

  /// Matches a lunar month string from a rule (which may have alternate transliterations
  /// like 'ashvina' vs 'ashwin' or 'kartik' vs 'kartika') against a canonical HinduMonth enum.
  static bool _matchesMonthName(String ruleMonth, HinduMonth month) {
    final clean = ruleMonth.toLowerCase().trim();
    final enumName = month.toString().split('.').last.toLowerCase();
    final englishName = month.name(AppLanguage.english).toLowerCase();

    if (clean == enumName || clean == englishName) return true;
    if ((clean == 'ashvina' || clean == 'asvina' || clean == 'ashwayuja') &&
        (enumName == 'ashwin' || englishName == 'ashwin')) {
      return true;
    }
    if ((clean == 'kartik' || clean == 'kartika') &&
        (enumName == 'kartika' || englishName == 'kartika')) {
      return true;
    }
    if ((clean == 'margashirsha' || clean == 'margasirsha' || clean == 'agrahayana') &&
        (enumName == 'margashirsha' || englishName == 'margashirsha')) {
      return true;
    }
    return false;
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

    final sunTimes = _calculateSunTimes(
      date: date,
      city: city,
      tzOffset: tzOffset,
      needSunset: festivalRules.isNotEmpty,
    );
    final jdUt = sunTimes.sunriseJdUt;
    final sunrise = sunTimes.sunrise;
    final sunset = sunTimes.sunset;
    final sunsetJdUt = sunTimes.sunsetJdUt;
    final nextSunriseJdUt = sunTimes.nextSunriseJdUt;

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
      final amantaInfo = _calculateAmantaMonthAndAdhika(jdUt, elongation, flags);
      final HinduMonth amantaMonth = amantaInfo.month;
      final bool isAdhikaMasa = amantaInfo.isAdhika;
      final HinduMonth purnimantaMonth = paksha == Paksha.shukla
          ? amantaMonth
          : HinduMonth.values[(amantaMonth.index + 1) % 12];
      final effectiveSystem = (lunarSystem?.toLowerCase().trim() == 'amanta') ? 'amanta' : 'purnimanta';
      final HinduMonth hinduMonth = effectiveSystem == 'amanta' ? amantaMonth : purnimantaMonth;

      final Nakshatra nakshatra = Nakshatra.fromLongitude(moonCoords.longitude);
      final Rashi suryaRashi = Rashi.fromDegrees(sunCoords.longitude);

      final matched = _evaluateFestivalRules(
        date: date,
        sunrise: sunrise,
        sunset: sunset,
        tzOffset: tzOffset,
        flags: flags,
        sunriseJdUt: jdUt,
        sunsetJdUt: sunsetJdUt,
        nextSunriseJdUt: nextSunriseJdUt,
        hinduMonth: hinduMonth,
        amantaMonth: amantaMonth,
        purnimantaMonth: purnimantaMonth,
        isAdhikaMasa: isAdhikaMasa,
        paksha: paksha,
        tithiNumber: tithiNumber,
        nakshatra: nakshatra,
        suryaRashi: suryaRashi,
        rules: festivalRules,
      );

      final matchedVratRules = <FestivalRule>[];
      final matchedFestivalRules = <FestivalRule>[];

      for (final rule in matched) {
        if (rule.isVrat) {
          matchedVratRules.add(rule);
        }
        if (rule.isFestival) {
          matchedFestivalRules.add(rule);
        }
      }

      if (matchedVratRules.isNotEmpty) {
        vrat = matchedVratRules.map((r) => r.nameEn).join(', ');
      }
      if (matchedFestivalRules.isNotEmpty) {
        festival = matchedFestivalRules.map((r) => r.nameEn).join(', ');
      }

      return TithiData(
        date: dateString,
        dateTime: itemDate,
        tithi: tithi.name(AppLanguage.english),
        paksha: paksha.name(AppLanguage.english),
        vrat: vrat,
        festival: festival,
        vratRule: matchedVratRules.isNotEmpty ? matchedVratRules.first : null,
        festivalRule: matchedFestivalRules.isNotEmpty ? matchedFestivalRules.first : null,
        vrats: matchedVratRules,
        festivals: matchedFestivalRules,
        lunarDay: tithiTotalIndex,
        moonPhaseAsset: ListItemTithi.getMoonAsset(tithiTotalIndex),
        state: state,
        isAlarmActive: isAlarmActive,
      );
    }

    return TithiData(
      date: dateString,
      dateTime: itemDate,
      tithi: tithi.name(AppLanguage.english),
      paksha: paksha.name(AppLanguage.english),
      vrat: vrat,
      festival: festival,
      vrats: const [],
      festivals: const [],
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
    int chunkSize = 60,
  }) async {
    await init();
    if (festivalRules.isNotEmpty) {
      FestivalRule.registerRules(festivalRules);
    }
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    final result = <TithiData>[];
    for (int i = 0; i < dates.length; i += chunkSize) {
      final end = (i + chunkSize < dates.length) ? i + chunkSize : dates.length;
      for (int j = i; j < end; j++) {
        result.add(calculateCalendarDay(
          date: dates[j],
          city: city,
          today: today,
          lunarSystem: lunarSystem,
          festivalRules: festivalRules,
          isAlarmActive: false,
        ));
      }
      if (!isTest && end < dates.length) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    return result;
  }
}
