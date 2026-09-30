import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweph/sweph.dart';
import 'package:tithinow/constants/muhurta_data.dart';
import 'package:tithinow/constants/panchang_terms.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/models/city.dart';
import 'package:tithinow/services/sweph_service.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/widgets.dart';

List<MuhurtaInterval> createMockAll17Intervals({DateTime? date}) {
  final d = date ?? DateTime(2026, 9, 6);
  return [
    for (int i = 0; i < Muhurta.values.length; i++)
      MuhurtaInterval(
        muhurta: Muhurta.values[i],
        timeRange:
            '${(i % 12 + 1).toString().padLeft(2, '0')}:00 am - ${(i % 12 + 2).toString().padLeft(2, '0')}:00 am',
        startTime: d.add(Duration(hours: i)),
        endTime: d.add(Duration(hours: i + 1)),
        index: i,
      ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListTabContentMuhurta Tests', () {
    testWidgets('Renders all 17 Muhurtas mentioned in panchang_terms.dart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              customIntervals: createMockAll17Intervals(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 17 items rendered using ListItemTabContent
      final itemFinders = find.byType(ListItemTabContent);
      expect(itemFinders, findsNWidgets(17));

      // Verify each of the 17 Muhurtas from panchang_terms.dart is present
      for (final muhurta in Muhurta.values) {
        expect(find.text(muhurta.name(AppLanguage.english)), findsOneWidget);
      }
    });

    testWidgets(
        'Contains combination of all 3 variables (past, current, future) with 2 CurrentItems on Sunday',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6), // Sunday
              currentTime: DateTime(2026, 9, 6, 12, 35),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On Sunday, 11 base intervals are generated (without ephemeris)
      final itemFinders = find.byType(ListItemTabContent);
      expect(itemFinders, findsNWidgets(11));

      int pastCount = 0;
      int currentCount = 0;
      int futureCount = 0;
      final List<String> currentTitles = [];

      for (int i = 0; i < 11; i++) {
        final ListItemTabContent item = tester.widget(itemFinders.at(i));
        if (item.state == ItemTemporalState.past) pastCount++;
        if (item.state == ItemTemporalState.current) {
          currentCount++;
          currentTitles.add(item.title);
        }
        if (item.state == ItemTemporalState.future) futureCount++;
      }

      // Combination of all 3 variables:
      expect(pastCount, greaterThan(0));
      expect(futureCount, greaterThan(0));

      // Strictly 2 CurrentItems on this date (Abhijit Muhurta and Yamaganda)
      expect(currentCount, 2);
      expect(currentTitles, contains('Abhijit Muhurta'));
      expect(currentTitles, contains('Yamaganda'));

      // 2 past + 2 current + 7 future = 11 items total
      expect(pastCount, 2);
      expect(futureCount, 7);
      expect(pastCount + currentCount + futureCount, 11);
    });

    testWidgets('Supports explicit currentIndices with 2 CurrentItems', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6),
              currentIndices: const {2, 5},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinders = find.byType(ListItemTabContent);
      expect(itemFinders, findsNWidgets(11));

      final ListItemTabContent item2 = tester.widget(itemFinders.at(2));
      final ListItemTabContent item5 = tester.widget(itemFinders.at(5));

      expect(item2.state, ItemTemporalState.current);
      expect(item5.state, ItemTemporalState.current);

      // Prior items are past
      final ListItemTabContent item0 = tester.widget(itemFinders.at(0));
      final ListItemTabContent item1 = tester.widget(itemFinders.at(1));
      expect(item0.state, ItemTemporalState.past);
      expect(item1.state, ItemTemporalState.past);

      // Subsequent items after max current index are future
      final ListItemTabContent item6 = tester.widget(itemFinders.at(6));
      expect(item6.state, ItemTemporalState.future);
    });

    testWidgets('Renders correct indicator dot colors based on PeriodNature (Good vs Bad)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              customIntervals: createMockAll17Intervals(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinders = find.byType(ListItemTabContent);
      for (int i = 0; i < 17; i++) {
        final ListItemTabContent item = tester.widget(itemFinders.at(i));
        // Find matching Muhurta enum by title
        final muhurta = Muhurta.values.firstWhere(
          (m) => m.name(AppLanguage.english) == item.title,
        );

        if (muhurta.isGood) {
          expect(item.indicatorColor, AppColors.indicatorGood);
        } else {
          expect(item.indicatorColor, AppColors.indicatorBad);
        }
      }
    });

    testWidgets('Supports interactive alarm toggle on future items', (tester) async {
      int? tappedIndex;
      Muhurta? tappedMuhurta;
      bool? tappedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6),
              currentTime: DateTime(2026, 9, 6, 12, 35),
              onAlarmTap: (index, muhurta, isActive) {
                tappedIndex = index;
                tappedMuhurta = muhurta;
                tappedState = isActive;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find alarm buttons rendered for future items
      final alarmButtons = find.byType(ButtonAlarm);
      expect(alarmButtons, findsWidgets);

      // Ensure first future alarm button is visible in viewport before tapping
      await tester.ensureVisible(alarmButtons.first);
      await tester.pumpAndSettle();

      // Tap first future item's alarm button
      await tester.tap(alarmButtons.first);
      await tester.pumpAndSettle();

      expect(tappedIndex, isNotNull);
      expect(tappedMuhurta, isNotNull);
      expect(tappedState, isTrue);

      // Tap again to toggle off
      await tester.tap(alarmButtons.first);
      await tester.pumpAndSettle();
      expect(tappedState, isFalse);
    });

    testWidgets(
        'When one CurrentItem ends, it transitions to PastItem while other CurrentItem remains current',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6),
              currentTime: DateTime(2026, 9, 6, 12, 35),
            ),
          ),
        ),
      );
      await tester.pump();

      // On Sunday, 2 items are current: Abhijit Muhurta and Yamaganda
      final itemFindersBefore = find.byType(ListItemTabContent);
      final List<int> currentIndices = [];
      for (int i = 0; i < 11; i++) {
        final ListItemTabContent item = tester.widget(itemFindersBefore.at(i));
        if (item.state == ItemTemporalState.current) {
          currentIndices.add(i);
        }
      }
      expect(currentIndices.length, 2);

      final firstCurrentIdx = currentIndices[0];
      final secondCurrentIdx = currentIndices[1];

      final ListItemTabContent firstCurrentBefore =
          tester.widget(itemFindersBefore.at(firstCurrentIdx));
      final ListItemTabContent secondCurrentBefore =
          tester.widget(itemFindersBefore.at(secondCurrentIdx));

      expect(firstCurrentBefore.state, ItemTemporalState.current);
      expect(secondCurrentBefore.state, ItemTemporalState.current);

      // End countdown on the first CurrentItem only
      firstCurrentBefore.onCountdownEnded?.call();
      await tester.pumpAndSettle();

      // Verify after first countdown ends:
      final itemFindersAfter = find.byType(ListItemTabContent);
      final ListItemTabContent firstCurrentAfter =
          tester.widget(itemFindersAfter.at(firstCurrentIdx));
      final ListItemTabContent secondCurrentAfter =
          tester.widget(itemFindersAfter.at(secondCurrentIdx));

      // First item transitioned to past!
      expect(firstCurrentAfter.state, ItemTemporalState.past);
      // Second item remains current!
      expect(secondCurrentAfter.state, ItemTemporalState.current);

      // End countdown on the second CurrentItem
      secondCurrentAfter.onCountdownEnded?.call();
      await tester.pumpAndSettle();

      final itemFindersFinal = find.byType(ListItemTabContent);
      final ListItemTabContent secondCurrentFinal =
          tester.widget(itemFindersFinal.at(secondCurrentIdx));
      expect(secondCurrentFinal.state, ItemTemporalState.past);
    });

    testWidgets('Supports Hindi localization for all 17 Muhurtas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              customIntervals: createMockAll17Intervals(),
              language: AppLanguage.hindi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ब्रह्म मुहूर्त'), findsOneWidget);
      expect(find.text('अभिजीत मुहूर्त'), findsOneWidget);
      expect(find.text('राहु काल'), findsOneWidget);
      expect(find.text('यमगण्ड काल'), findsOneWidget);
      expect(find.text('विजय मुहूर्त'), findsOneWidget);
      expect(find.text('अमृत काल'), findsOneWidget);
      expect(find.text('निशीथ मुहूर्त'), findsOneWidget);
      expect(find.text('सर्वार्थ सिद्धि योग'), findsOneWidget);
      expect(find.text('रवि योग'), findsOneWidget);
      expect(find.text('वर्ज्य'), findsOneWidget);
      expect(find.text('गोधूलि मुहूर्त'), findsOneWidget);
    });

    testWidgets('Supports Gujarati localization for all 17 Muhurtas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              customIntervals: createMockAll17Intervals(),
              language: AppLanguage.gujarati,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('બ્રહ્મ મુહૂર્ત'), findsOneWidget);
      expect(find.text('અભિજિત મુહૂર્ત'), findsOneWidget);
      expect(find.text('રાહુ કાળ'), findsOneWidget);
      expect(find.text('યમગંડ કાળ'), findsOneWidget);
      expect(find.text('વિજય મુહૂર્ત'), findsOneWidget);
      expect(find.text('અમૃત કાળ'), findsOneWidget);
      expect(find.text('નિશિથ મુહૂર્ત'), findsOneWidget);
      expect(find.text('સર્વાર્થ સિદ્ધિ યોગ'), findsOneWidget);
      expect(find.text('રવિ યોગ'), findsOneWidget);
      expect(find.text('વર્જ્ય કાળ'), findsOneWidget);
      expect(find.text('ગોધૂલિ મુહૂર્ત'), findsOneWidget);
    });

    testWidgets('Renders optional header title with tertiary styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6),
              title: 'Today Muhurta',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.text('Today Muhurta');
      expect(headerFinder, findsOneWidget);
      final Text headerText = tester.widget(headerFinder);
      expect(headerText.style?.color, AppColors.tertiary);
      expect(headerText.style?.fontSize, 16.0);
      expect(headerText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('Renders optional tag pill when showTag is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              customIntervals: createMockAll17Intervals(),
              showTag: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tag 'Muhurta' rendered across all 17 items
      expect(find.text('Muhurta'), findsNWidgets(17));
    });

    testWidgets('Reacts dynamically when AppDatabase.languageNotifier changes', (tester) async {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Abhijit Muhurta'), findsOneWidget);
      expect(find.text('Brahma Muhurta'), findsOneWidget);

      // Switch to Hindi
      AppDatabase.instance.languageNotifier.value = AppLanguage.hindi;
      await tester.pumpAndSettle();

      expect(find.text('अभिजीत मुहूर्त'), findsOneWidget);
      expect(find.text('ब्रह्म मुहूर्त'), findsOneWidget);

      // Switch to Gujarati
      AppDatabase.instance.languageNotifier.value = AppLanguage.gujarati;
      await tester.pumpAndSettle();

      expect(find.text('અભિજિત મુહૂર્ત'), findsOneWidget);
      expect(find.text('બ્રહ્મ મુહૂર્ત'), findsOneWidget);

      // Reset
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
      await tester.pumpAndSettle();
    });

    testWidgets('At 10:36 PM, daytime items are past and no past items are falsely active', (tester) async {
      final eveningTime = DateTime(2026, 9, 23, 22, 36);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 23), // Wednesday
              currentTime: eveningTime,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinders = find.byType(ListItemTabContent);
      int pastCount = 0;
      int currentCount = 0;
      int futureCount = 0;

      for (int i = 0; i < itemFinders.evaluate().length; i++) {
        final ListItemTabContent item = tester.widget(itemFinders.at(i));
        if (item.state == ItemTemporalState.past) pastCount++;
        if (item.state == ItemTemporalState.current) currentCount++;
        if (item.state == ItemTemporalState.future) futureCount++;

        // Verify midday items are strictly past
        if (item.title == 'Yamaganda' || item.title == 'Dur Muhurtam') {
          expect(item.state, ItemTemporalState.past);
        }
        // Nishita Muhurta starting at ~23:43 is future
        if (item.title == 'Nishita Muhurta') {
          expect(item.state, ItemTemporalState.future);
        }
      }

      // Abhijit is rightly omitted on Wednesday per classical Vedic rules
      expect(find.text('Abhijit Muhurta'), findsNothing);

      // At 10:36 PM on Wednesday: 0 active items, 9 past items, 1 future item (Nishita)
      expect(currentCount, 0);
      expect(pastCount, 9);
      expect(futureCount, 1);
    });

    testWidgets('Renders 12 base items with 2 separate Dur Muhurtam list items on Monday', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 7), // Monday
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinders = find.byType(ListItemTabContent);
      expect(itemFinders, findsNWidgets(12));

      // Exactly 2 items have title 'Dur Muhurtam'
      final durMuhurtaWidgets = <ListItemTabContent>[];
      for (int i = 0; i < 12; i++) {
        final ListItemTabContent item = tester.widget(itemFinders.at(i));
        if (item.title == 'Dur Muhurtam') {
          durMuhurtaWidgets.add(item);
        }
      }

      expect(durMuhurtaWidgets.length, 2);
      expect(durMuhurtaWidgets[0].timeRange, '12:54 pm - 01:42 pm');
      expect(durMuhurtaWidgets[1].timeRange, '03:19 pm - 04:07 pm');
      expect(durMuhurtaWidgets[0].indicatorColor, AppColors.indicatorBad);
      expect(durMuhurtaWidgets[1].indicatorColor, AppColors.indicatorBad);
    });

    testWidgets('Renders 12 base items with 2 separate Dur Muhurtam list items on Tuesday (daytime and night)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 8), // Tuesday
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinders = find.byType(ListItemTabContent);
      expect(itemFinders, findsNWidgets(12));

      final durMuhurtaWidgets = <ListItemTabContent>[];
      for (int i = 0; i < 12; i++) {
        final ListItemTabContent item = tester.widget(itemFinders.at(i));
        if (item.title == 'Dur Muhurtam') {
          durMuhurtaWidgets.add(item);
        }
      }

      expect(durMuhurtaWidgets.length, 2);
      expect(durMuhurtaWidgets[0].timeRange, '08:52 am - 09:40 am');
      // Tuesday 7th night muhurta matching classical Vedic standard (11:18 pm - 12:06 am with default 06:27/18:33 times)
      expect(durMuhurtaWidgets[1].timeRange, '11:18 pm - 12:06 am');
    });

    test('MuhurtaData interval counts across all weekdays', () {
      final sunday = MuhurtaData.generateIntervals(date: DateTime(2026, 9, 6));
      expect(sunday.length, 11);

      final monday = MuhurtaData.generateIntervals(date: DateTime(2026, 9, 7));
      expect(monday.length, 12);

      final tuesday = MuhurtaData.generateIntervals(date: DateTime(2026, 9, 8));
      expect(tuesday.length, 12);

      // Wednesday strictly excludes Abhijit
      final wednesday = MuhurtaData.generateIntervals(date: DateTime(2026, 9, 9));
      expect(wednesday.length, 10);
      expect(wednesday.any((i) => i.muhurta == Muhurta.abhijitMuhurta), isFalse);

      final thursday = MuhurtaData.generateIntervals(date: DateTime(2026, 9, 10));
      expect(thursday.length, 12);

      final friday = MuhurtaData.generateIntervals(date: DateTime(2026, 9, 11));
      expect(friday.length, 12);

      final saturday = MuhurtaData.generateIntervals(date: DateTime(2026, 9, 12));
      expect(saturday.length, 12);
    });

    test('Vedic rule: Wednesday strictly omits Abhijit and has midday Dur Muhurtam', () {
      final wed = MuhurtaData.generateIntervals(
        date: DateTime(2026, 9, 23),
        sunrise: const TimeOfDay(hour: 6, minute: 9),
        sunset: const TimeOfDay(hour: 18, minute: 17),
      );

      // Abhijit must NOT be present on Wednesday
      expect(wed.any((i) => i.muhurta == Muhurta.abhijitMuhurta), isFalse);

      // Dur Muhurtam covers the 8th daytime muhurta (11:48 am - 12:37 pm)
      final durMuhurtam = wed.where((i) => i.muhurta == Muhurta.durMuhurtam).first;
      expect(durMuhurtam.timeRange, '11:48 am - 12:37 pm');
    });

    test('Vedic rule: Godhuli Muhurta starts at sunset and lasts 24 minutes', () {
      final sun = MuhurtaData.generateIntervals(
        date: DateTime(2026, 9, 20),
        sunrise: const TimeOfDay(hour: 6, minute: 8),
        sunset: const TimeOfDay(hour: 18, minute: 21),
      );

      final godhuli = sun.firstWhere((i) => i.muhurta == Muhurta.godhuliMuhurta);
      expect(godhuli.startTime, DateTime(2026, 9, 20, 18, 21));
      expect(godhuli.endTime, DateTime(2026, 9, 20, 18, 45));
      expect(godhuli.timeRange, '06:21 pm - 06:45 pm');
    });

    test('Vedic rule: Pratah Sandhya and Sayahna Sandhya have 3 ghatis duration', () {
      final sun = MuhurtaData.generateIntervals(
        date: DateTime(2026, 9, 20),
        sunrise: const TimeOfDay(hour: 6, minute: 8),
        sunset: const TimeOfDay(hour: 18, minute: 21),
      );

      final pratah = sun.firstWhere((i) => i.muhurta == Muhurta.pratahSandhya);
      expect(pratah.endTime, DateTime(2026, 9, 20, 6, 8));
      // 3 ghatis = 72 minutes (approx 71 mins for autumn night)
      expect(pratah.endTime.difference(pratah.startTime).inMinutes, inInclusiveRange(70, 73));

      final sayahna = sun.firstWhere((i) => i.muhurta == Muhurta.sayahnaSandhya);
      expect(sayahna.startTime, DateTime(2026, 9, 20, 18, 21));
      expect(sayahna.endTime.difference(sayahna.startTime).inMinutes, inInclusiveRange(70, 73));
    });

    test('Astronomical Muhurtas integration with Swiss Ephemeris', () async {
      await Sweph.init();
      Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);

      const delhi = City(
        id: 2,
        name: 'New Delhi',
        state: 'Delhi',
        latitude: 28.6139,
        longitude: 77.2090,
      );

      final intervals = MuhurtaData.generateIntervals(
        date: DateTime(2026, 9, 23),
        sunriseDateTime: DateTime(2026, 9, 23, 6, 9),
        sunsetDateTime: DateTime(2026, 9, 23, 18, 17),
        nextSunriseDateTime: DateTime(2026, 9, 24, 6, 10),
        city: delhi,
      );

      // Wednesday: Abhijit is excluded
      expect(intervals.any((i) => i.muhurta == Muhurta.abhijitMuhurta), isFalse);

      // Varjyam and Amrit Kalam are calculated from Moon nakshatra transit
      final varjyam = intervals.where((i) => i.muhurta == Muhurta.varjyam);
      final amrit = intervals.where((i) => i.muhurta == Muhurta.amritKalam);

      expect(varjyam.isNotEmpty, isTrue);
      expect(amrit.isNotEmpty, isTrue);
      expect(varjyam.first.startTime.isBefore(varjyam.first.endTime), isTrue);
      expect(amrit.first.startTime.isBefore(amrit.first.endTime), isTrue);
    });

    testWidgets('CardTimings.fromCalculationResult renders active Muhurta in Now Tab and correct states in Muhurta Tab', (tester) async {
      await Sweph.init();
      Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);

      // Simulate 09:00 AM on Friday Sep 25, 2026
      final simTime = DateTime(2026, 9, 25, 9, 0);
      final result = await SwephService.instance.calculatePanchang(
        date: DateTime(2026, 9, 25),
        city: City.mumbai,
      );

      // 1. In Now Tab (initialTabIndex: 0):
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardTimings.fromCalculationResult(
                result,
                currentTime: simTime,
                initialTabIndex: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Now tab, active running items (Choghadiya + active Muhurtas) are displayed
      final nowTabItems = find.byType(ListItemTabContent);
      expect(nowTabItems, findsWidgets);

      // All items in Now tab are strictly current (with live counter and NO ButtonAlarm)
      for (int i = 0; i < nowTabItems.evaluate().length; i++) {
        final ListItemTabContent item = tester.widget(nowTabItems.at(i));
        expect(item.state, ItemTemporalState.current);
      }
      expect(find.descendant(of: find.byType(CardTimings), matching: find.byType(ButtonAlarm)), findsNothing);

      // 2. In Muhurta Tab (initialTabIndex: 2):
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardTimings.fromCalculationResult(
                result,
                currentTime: simTime,
                initialTabIndex: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final muhurtaItems = find.byType(ListItemTabContent);
      expect(muhurtaItems, findsWidgets);

      int pastCount = 0;
      int currentCount = 0;
      int futureCount = 0;

      for (int i = 0; i < muhurtaItems.evaluate().length; i++) {
        final ListItemTabContent item = tester.widget(muhurtaItems.at(i));
        if (item.state == ItemTemporalState.past) pastCount++;
        if (item.state == ItemTemporalState.current) currentCount++;
        if (item.state == ItemTemporalState.future) futureCount++;
      }

      // Past items exist (e.g. Brahma Muhurta, Pratah Sandhya)
      expect(pastCount, greaterThan(0));
      // Current items exist (active right now at 9:00 AM, e.g. Gulikai Kalam, Dur Muhurtam, Yogas)
      expect(currentCount, greaterThan(0));
      // Future items exist (e.g. Rahu Kalam, Abhijit, Nishita)
      expect(futureCount, greaterThan(0));

      // Alarm buttons are present only on future items
      final alarms = find.descendant(of: find.byType(CardTimings), matching: find.byType(ButtonAlarm));
      expect(alarms, findsNWidgets(futureCount));
    });

    test('Panchang and Muhurta intervals for Valsad, Gujarat on Sep 25, 2026', () async {
      await Sweph.init();
      Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);

      const valsad = City(
        id: 380,
        name: 'Valsad',
        state: 'Gujarat',
        latitude: 20.61,
        longitude: 72.926,
      );

      final result = await SwephService.instance.calculatePanchang(
        date: DateTime(2026, 9, 25),
        city: valsad,
      );

      expect(result.sunrise.hour, 6);
      expect(result.sunrise.minute, inInclusiveRange(26, 30));
      expect(result.sunset.hour, 18);
      expect(result.sunset.minute, inInclusiveRange(30, 34));

      // Ravi Yoga is formed from Sunrise until Shatabhisha Nakshatra ends at ~11:22 AM
      final ravi = result.muhurtaIntervals.where((i) => i.muhurta == Muhurta.raviYoga);
      expect(ravi.isNotEmpty, isTrue);

      // Aadal Yoga is also formed during Shatabhisha Nakshatra (distance 14 in 28-nakshatra system)
      final aadal = result.muhurtaIntervals.where((i) => i.muhurta == Muhurta.aadalYoga);
      expect(aadal.isNotEmpty, isTrue);

      // Varjyam is formed in Purva Bhadrapada during the evening
      final varjyam = result.muhurtaIntervals.where((i) => i.muhurta == Muhurta.varjyam);
      expect(varjyam.isNotEmpty, isTrue);

      // Amrit Kalam is formed in Purva Bhadrapada late night
      final amrit = result.muhurtaIntervals.where((i) => i.muhurta == Muhurta.amritKalam);
      expect(amrit.isNotEmpty, isTrue);
    });

    test('Vidaal Yoga and Aadal Yoga transitions when Sun transits into Hasta on Sep 27, 2026', () async {
      await Sweph.init();
      Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);

      const delhi = City(
        id: 2,
        name: 'New Delhi',
        state: 'Delhi',
        latitude: 28.6139,
        longitude: 77.2090,
      );

      final result = await SwephService.instance.calculatePanchang(
        date: DateTime(2026, 9, 27),
        city: delhi,
      );

      final vidaal = result.muhurtaIntervals.where((i) => i.muhurta == Muhurta.vidaalYoga).toList();
      final aadal = result.muhurtaIntervals.where((i) => i.muhurta == Muhurta.aadalYoga).toList();
      final ssy = result.muhurtaIntervals.where((i) => i.muhurta == Muhurta.sarvarthaSiddhiYoga).toList();

      expect(vidaal.isNotEmpty, isTrue);
      // Vidaal Yoga starts when Moon enters Revati (~11:08 AM)
      expect(vidaal.first.startTime.hour, 11);
      expect(vidaal.first.startTime.minute, inInclusiveRange(7, 10));

      // Vidaal Yoga terminates in early afternoon when Sun enters Hasta (~01:20 PM - 01:25 PM), NOT next sunrise
      expect(vidaal.first.endTime.hour, 13);
      expect(vidaal.first.endTime.minute, inInclusiveRange(18, 26));

      // Aadal Yoga is formed both morning (before Revati) and afternoon (after Sun enters Hasta)
      expect(aadal.length, 2);
      expect(aadal[0].startTime.hour, 6);
      expect(aadal[0].endTime.hour, 11);
      expect(aadal[1].startTime.hour, 13);

      // Sarvartha Siddhi Yoga runs until Uttara Bhadrapada ends at ~11:08 AM
      expect(ssy.isNotEmpty, isTrue);
      expect(ssy.first.endTime.hour, 11);
      expect(ssy.first.endTime.minute, inInclusiveRange(7, 10));
    });
  });
}
