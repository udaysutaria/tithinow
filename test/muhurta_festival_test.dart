import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/models/city.dart';
import 'package:tithinow/models/festival_rule.dart';
import 'package:tithinow/services/sweph_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await SwephService.instance.init();
  });

  test('Dussehra 2026 resolves to Oct 20 (not Oct 21) under Aparahna and first_day tie-break', () {
    final service = SwephService.instance;

    const dussehraRule = FestivalRule(
      id: 101,
      festivalId: 'vijayadashami',
      category: 'festival',
      nameEn: 'Vijayadashami',
      eventType: 'lunar_tithi',
      daySelectionRule: 'aparahnna',
      tieBreakRule: 'first_day',
      lunarMonth: 'ashwin',
      paksha: 'shukla',
      tithiNumber: 10,
    );

    final oct20 = service.calculateCalendarDay(
      date: DateTime(2026, 10, 20),
      city: City.mumbai,
      today: DateTime(2026, 1, 1),
      festivalRules: [dussehraRule],
    );

    final oct21 = service.calculateCalendarDay(
      date: DateTime(2026, 10, 21),
      city: City.mumbai,
      today: DateTime(2026, 1, 1),
      festivalRules: [dussehraRule],
    );

    expect(oct20.festival, 'Vijayadashami');
    expect(oct20.festivals.map((f) => f.nameEn), contains('Vijayadashami'));
    expect(oct21.festival, 'No Festival');
    expect(oct21.festivals, isEmpty);
  });

  test('Diwali 2027 resolves to Oct 29 under Pradosha vyapti calculation', () {
    final service = SwephService.instance;

    const diwaliRule = FestivalRule(
      id: 102,
      festivalId: 'diwali',
      category: 'festival',
      nameEn: 'Diwali',
      eventType: 'lunar_tithi',
      daySelectionRule: 'pradosha',
      tieBreakRule: 'first_day',
      lunarMonth: 'ashwin',
      purnimantaMonth: 'kartika',
      paksha: 'krishna',
      tithiNumber: 15,
    );

    final oct28 = service.calculateCalendarDay(
      date: DateTime(2027, 10, 28),
      city: City.mumbai,
      today: DateTime(2027, 1, 1),
      festivalRules: [diwaliRule],
    );
    final oct29 = service.calculateCalendarDay(
      date: DateTime(2027, 10, 29),
      city: City.mumbai,
      today: DateTime(2027, 1, 1),
      festivalRules: [diwaliRule],
    );

    expect(oct28.festival, 'No Festival');
    expect(oct29.festival, 'Diwali');
    expect(oct29.festivals.map((f) => f.nameEn), contains('Diwali'));
  });

  test('Kali Chaudas and Diwali both populate on the same day in 2026, 2028, and 2029', () {
    final service = SwephService.instance;

    const diwaliRule = FestivalRule(
      id: 102,
      festivalId: 'diwali',
      category: 'festival',
      nameEn: 'Diwali',
      eventType: 'lunar_tithi',
      daySelectionRule: 'pradosha',
      tieBreakRule: 'first_day',
      lunarMonth: 'ashwin',
      purnimantaMonth: 'kartika',
      paksha: 'krishna',
      tithiNumber: 15,
    );

    const kaliChaudasRule = FestivalRule(
      id: 103,
      festivalId: 'naraka_chaturdashi',
      category: 'festival',
      nameEn: 'Kali Chaudas',
      eventType: 'lunar_tithi',
      daySelectionRule: 'arunodaya',
      lunarMonth: 'ashwin',
      purnimantaMonth: 'kartika',
      paksha: 'krishna',
      tithiNumber: 14,
    );

    // 2026: Nov 8 has both Kali Chaudas and Diwali
    final nov8_2026 = service.calculateCalendarDay(
      date: DateTime(2026, 11, 8),
      city: City.mumbai,
      today: DateTime(2026, 1, 1),
      festivalRules: [kaliChaudasRule, diwaliRule],
    );
    expect(nov8_2026.festivals.map((f) => f.nameEn).toList(), containsAll(['Kali Chaudas', 'Diwali']));
    expect(nov8_2026.festival, 'Kali Chaudas, Diwali');

    // 2028: Oct 17 has both Kali Chaudas and Diwali
    final oct17_2028 = service.calculateCalendarDay(
      date: DateTime(2028, 10, 17),
      city: City.mumbai,
      today: DateTime(2028, 1, 1),
      festivalRules: [kaliChaudasRule, diwaliRule],
    );
    expect(oct17_2028.festivals.map((f) => f.nameEn).toList(), containsAll(['Kali Chaudas', 'Diwali']));
    expect(oct17_2028.festival, 'Kali Chaudas, Diwali');

    // 2029: Nov 5 has both Kali Chaudas and Diwali
    final nov5_2029 = service.calculateCalendarDay(
      date: DateTime(2029, 11, 5),
      city: City.mumbai,
      today: DateTime(2029, 1, 1),
      festivalRules: [kaliChaudasRule, diwaliRule],
    );
    expect(nov5_2029.festivals.map((f) => f.nameEn).toList(), containsAll(['Kali Chaudas', 'Diwali']));
    expect(nov5_2029.festival, 'Kali Chaudas, Diwali');
  });
}
