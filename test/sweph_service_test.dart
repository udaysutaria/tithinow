import 'package:flutter_test/flutter_test.dart';
import 'package:sweph/sweph.dart';
import 'package:tithinow/models/city.dart';
import 'package:tithinow/models/festival_rule.dart';
import 'package:tithinow/services/sweph_service.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Sweph.init();
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
  });

  test('Sweph initializes and calculates Julian Day', () {
    final jd = Sweph.swe_julday(2026, 9, 22, 6.0, CalendarType.SE_GREG_CAL);
    expect(jd, greaterThan(2460000.0));
  });

  test('Calculates Sidereal Sun and Moon Longitude using Lahiri Ayanamsha', () {
    final jd = Sweph.swe_julday(2026, 9, 22, 6.0, CalendarType.SE_GREG_CAL);

    // Moshier ephemeris flag works 100% offline without needing external ephe files!
    final flags = SwephFlag.SEFLG_MOSEPH | SwephFlag.SEFLG_SIDEREAL;

    final sun = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, flags);
    final moon = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, flags);

    expect(sun.longitude, inInclusiveRange(0.0, 360.0));
    expect(moon.longitude, inInclusiveRange(0.0, 360.0));

    // Elongation: (Moon - Sun) % 360
    final elongation = (moon.longitude - sun.longitude) % 360.0;
    final tithiNumber = (elongation / 12.0).floor() + 1;
    expect(tithiNumber, inInclusiveRange(1, 30));

    // Solilunar Yoga: (Moon + Sun) % 360
    final yogaArc = (moon.longitude + sun.longitude) % 360.0;
    final yogaNumber = (yogaArc / (360.0 / 27.0)).floor() + 1;
    expect(yogaNumber, inInclusiveRange(1, 27));

    // Nakshatra: Moon / (360 / 27)
    final nakshatraNumber = (moon.longitude / (360.0 / 27.0)).floor() + 1;
    expect(nakshatraNumber, inInclusiveRange(1, 27));
  });

  test('Calculates Sunrise and Sunset for Mumbai', () {
    // 2026-09-22 00:00:00 UT
    final jdUt = Sweph.swe_julday(2026, 9, 22, 0.0, CalendarType.SE_GREG_CAL);
    final geoPos = GeoPosition(72.8777, 19.0760, 10.0);

    final riseJd = Sweph.swe_rise_trans(
      jdUt,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_MOSEPH,
      RiseSetTransitFlag.SE_CALC_RISE,
      geoPos,
      0,
      0,
    );

    final setJd = Sweph.swe_rise_trans(
      jdUt,
      HeavenlyBody.SE_SUN,
      SwephFlag.SEFLG_MOSEPH,
      RiseSetTransitFlag.SE_CALC_SET,
      geoPos,
      0,
      0,
    );

    expect(riseJd, isNotNull);
    expect(setJd, isNotNull);

    final riseDtUtc = Sweph.swe_revjul(riseJd!, CalendarType.SE_GREG_CAL);
    final setDtUtc = Sweph.swe_revjul(setJd!, CalendarType.SE_GREG_CAL);

    // Convert UTC to IST (+5:30)
    final riseIst = riseDtUtc.add(const Duration(hours: 5, minutes: 30));
    final setIst = setDtUtc.add(const Duration(hours: 5, minutes: 30));

    // In Mumbai in late September, Sunrise is around 06:25 - 06:35 AM IST
    expect(riseIst.hour, 6);
    expect(riseIst.minute, inInclusiveRange(20, 40));

    // Sunset is around 18:30 - 18:40 PM IST
    expect(setIst.hour, 18);
    expect(setIst.minute, inInclusiveRange(25, 45));
  });

  test('SwephService calculates full Pancha-Anga for Mumbai', () async {
    final mumbai = City(
      id: 1,
      name: 'Mumbai',
      state: 'Maharashtra',
      latitude: 19.0760,
      longitude: 72.8777,
    );

    final service = SwephService.instance;
    final result = await service.calculatePanchang(
      date: DateTime(2026, 9, 22),
      city: mumbai,
    );

    expect(result.sunriseFormatted, '06:27 AM');
    expect(result.sunsetFormatted, '06:34 PM');
    expect(result.moonriseFormatted, contains('03:48 PM'));
    expect(result.moonsetFormatted, contains('03:15 AM, Sep 23'));
    expect(result.hinduMonth, HinduMonth.bhadrapada);
    expect(result.paksha, Paksha.shukla);
    expect(result.tithi, Tithi.ekadashi);
    expect(result.tithiNumber, 11);
    expect(result.nakshatra, Nakshatra.uttaraAshadha);
    expect(result.yoga, Yoga.atiganda);
    expect(result.karana, Karana.vanija);
    expect(result.suryaRashi, Rashi.kanya);
    expect(result.rashi, Rashi.makara);
  });

  test('SwephService calculates calendar days and range fast and accurately', () async {
    final service = SwephService.instance;
    final today = DateTime(2026, 9, 22);

    final dayData = service.calculateCalendarDay(
      date: DateTime(2026, 9, 22),
      city: City.mumbai,
      today: today,
    );

    expect(dayData.tithi, isNotEmpty);
    expect(dayData.paksha, contains('Paksha'));
    expect(dayData.state, ItemTemporalState.current);
    expect(dayData.lunarDay, inInclusiveRange(1, 30));
    expect(dayData.moonPhaseAsset, contains('assets/moon_phases/'));

    final rangeDates = List<DateTime>.generate(30, (i) => DateTime(2026, 9, 1 + i));
    final rangeData = await service.calculateCalendarRange(
      dates: rangeDates,
      city: City.mumbai,
      today: today,
    );

    expect(rangeData.length, 30);
    expect(rangeData.first.date, contains('1 Sep 2026'));
    expect(rangeData.last.date, contains('30 Sep 2026'));
  });

  test('Makar Sankranti matches on exactly one day (Jan 14, 2026) and not for 30 days', () {
    final service = SwephService.instance;
    const makarSankrantiRule = FestivalRule(
      id: 36,
      festivalId: 'makar_sankranti',
      category: 'festival',
      nameEn: 'Makar Sankranti',
      eventType: 'solar_sankranti',
      daySelectionRule: 'punyakaal',
      solarMonth: 'makara',
    );

    // Jan 13: Sun still in Dhanu (should not match)
    final jan13 = service.calculateCalendarDay(
      date: DateTime(2026, 1, 13),
      city: City.mumbai,
      today: DateTime(2026, 1, 1),
      festivalRules: [makarSankrantiRule],
    );
    expect(jan13.festival, 'No Festival');

    // Jan 14: Sun enters Makara (should match)
    final jan14 = service.calculateCalendarDay(
      date: DateTime(2026, 1, 14),
      city: City.mumbai,
      today: DateTime(2026, 1, 1),
      festivalRules: [makarSankrantiRule],
    );
    expect(jan14.festival, 'Makar Sankranti');

    // Jan 15: Sun already in Makara (should not match again)
    final jan15 = service.calculateCalendarDay(
      date: DateTime(2026, 1, 15),
      city: City.mumbai,
      today: DateTime(2026, 1, 1),
      festivalRules: [makarSankrantiRule],
    );
    expect(jan15.festival, 'No Festival');

    // Jan 20: Sun still inside Makara rashi (should not match)
    final jan20 = service.calculateCalendarDay(
      date: DateTime(2026, 1, 20),
      city: City.mumbai,
      today: DateTime(2026, 1, 1),
      festivalRules: [makarSankrantiRule],
    );
    expect(jan20.festival, 'No Festival');
  });

  test('Observances with category "both" or fasting populate both Vrat and Festival', () {
    final service = SwephService.instance;

    // Maha Shivaratri with category "both"
    const shivaratriRule = FestivalRule(
      id: 33,
      festivalId: 'maha_shivaratri',
      category: 'both',
      isFasting: true,
      nameEn: 'Maha Shivaratri',
      eventType: 'lunar_tithi',
      daySelectionRule: 'nishita',
      lunarMonth: 'magha',
      paksha: 'krishna',
      tithiNumber: 14,
    );

    expect(shivaratriRule.isBoth, isTrue);
    expect(shivaratriRule.isFestival, isTrue);
    expect(shivaratriRule.isVrat, isTrue);

    // On Maha Shivaratri (approx Feb 15/16, 2026 in Magha Krishna Chaturdashi)
    final feb15 = service.calculateCalendarDay(
      date: DateTime(2026, 2, 15),
      city: City.mumbai,
      today: DateTime(2026, 2, 1),
      festivalRules: [shivaratriRule],
    );

    // When matched, both vrat and festival are populated
    expect(feb15.vrat, 'Maha Shivaratri');
    expect(feb15.festival, 'Maha Shivaratri');
  });

  test('Pure Vrat and pure Festival populate only their respective fields', () {
    final service = SwephService.instance;

    const pureVrat = FestivalRule(
      id: 35,
      festivalId: 'nirjala_ekadashi',
      category: 'vrat',
      isFasting: true,
      nameEn: 'Nirjala Ekadashi',
      eventType: 'lunar_tithi',
      daySelectionRule: 'udaya',
      lunarMonth: 'any',
      paksha: 'shukla',
      tithiNumber: 11,
    );

    const pureFestival = FestivalRule(
      id: 34,
      festivalId: 'holi',
      category: 'festival',
      isFasting: false,
      nameEn: 'Holika Dahan',
      eventType: 'lunar_tithi',
      daySelectionRule: 'pradosha',
      lunarMonth: 'any',
      paksha: 'shukla',
      tithiNumber: 11, // test matching on tithi 11
    );

    expect(pureVrat.isVrat, isTrue);
    expect(pureVrat.isFestival, isFalse);

    expect(pureFestival.isFestival, isTrue);
    expect(pureFestival.isVrat, isFalse);

    final result = service.calculateCalendarDay(
      date: DateTime(2026, 9, 22), // Ekadashi
      city: City.mumbai,
      today: DateTime(2026, 9, 22),
      festivalRules: [pureVrat, pureFestival],
    );

    expect(result.vrat, 'Nirjala Ekadashi');
    expect(result.festival, 'Holika Dahan');
  });

  test('Purnimanta and Amanta systems: identical in Shukla Paksha, offset by 1 month in Krishna Paksha', () async {
    final service = SwephService.instance;
    final mumbai = City.mumbai;

    // 1. Shukla Paksha date: 22 Sep 2026 (Ekadashi)
    final shuklaAmanta = await service.calculatePanchang(
      date: DateTime(2026, 9, 22),
      city: mumbai,
      lunarSystem: 'amanta',
    );
    final shuklaPurnimanta = await service.calculatePanchang(
      date: DateTime(2026, 9, 22),
      city: mumbai,
      lunarSystem: 'purnimanta',
    );

    expect(shuklaAmanta.paksha, Paksha.shukla);
    expect(shuklaAmanta.amantaMonth, HinduMonth.bhadrapada);
    expect(shuklaAmanta.purnimantaMonth, HinduMonth.bhadrapada);
    expect(shuklaAmanta.hinduMonth, HinduMonth.bhadrapada);

    expect(shuklaPurnimanta.paksha, Paksha.shukla);
    expect(shuklaPurnimanta.amantaMonth, HinduMonth.bhadrapada);
    expect(shuklaPurnimanta.purnimantaMonth, HinduMonth.bhadrapada);
    expect(shuklaPurnimanta.hinduMonth, HinduMonth.bhadrapada);

    // 2. Krishna Paksha date: 1 Oct 2026 (Shasthi Krishna Paksha, after Bhadrapada Purnima)
    final krishnaAmanta = await service.calculatePanchang(
      date: DateTime(2026, 10, 1),
      city: mumbai,
      lunarSystem: 'amanta',
    );
    final krishnaPurnimanta = await service.calculatePanchang(
      date: DateTime(2026, 10, 1),
      city: mumbai,
      lunarSystem: 'purnimanta',
    );

    expect(krishnaAmanta.paksha, Paksha.krishna);
    // In Amanta, month is still Bhadrapada until Amavasya
    expect(krishnaAmanta.amantaMonth, HinduMonth.bhadrapada);
    expect(krishnaAmanta.hinduMonth, HinduMonth.bhadrapada);

    expect(krishnaPurnimanta.paksha, Paksha.krishna);
    // In Purnimanta, month transitioned to Ashwin after Purnima
    expect(krishnaPurnimanta.purnimantaMonth, HinduMonth.ashwin);
    expect(krishnaPurnimanta.hinduMonth, HinduMonth.ashwin);
  });
}
