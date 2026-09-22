import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListTabContentNow Tests', () {
    final testDate = DateTime(2026, 9, 22); // Tuesday
    const testSunrise = TimeOfDay(hour: 6, minute: 27);
    const testSunset = TimeOfDay(hour: 18, minute: 33);

    testWidgets('Populates strictly active items only (1 Choghadiya when no Muhurta active)', (tester) async {
      // 12:02 PM on Tuesday: Labh Choghadiya is active, no daytime Muhurtas are active
      final testTime = DateTime(2026, 9, 22, 12, 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(
              date: testDate,
              sunrise: testSunrise,
              sunset: testSunset,
              currentTime: testTime,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only 1 item displayed (Labh Choghadiya)
      expect(find.byType(ListItemTabContent), findsOneWidget);
      expect(find.text('Labh'), findsOneWidget);
      expect(find.text('Choghadiya'), findsOneWidget);
      expect(find.text('Muhurta'), findsNothing);
    });

    testWidgets('Populates 1 Choghadiya and 1 Muhurta when exactly 1 Muhurta is active', (tester) async {
      // 12:15 PM on Tuesday: Labh Choghadiya + Abhijit Muhurta are active
      final testTime = DateTime(2026, 9, 22, 12, 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(
              date: testDate,
              sunrise: testSunrise,
              sunset: testSunset,
              currentTime: testTime,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 2 active items
      expect(find.byType(ListItemTabContent), findsNWidgets(2));
      expect(find.text('Labh'), findsOneWidget);
      expect(find.text('Choghadiya'), findsOneWidget);
      expect(find.text('Abhijit Muhurta'), findsOneWidget);
      expect(find.text('Muhurta'), findsOneWidget);
    });

    testWidgets('Populates 1 Choghadiya and multiple Muhurtas when multiple Muhurtas overlap', (tester) async {
      // 12:35 PM on Tuesday: Amrit Choghadiya + Abhijit Muhurta + Gulikai Kalam are active
      final testTime = DateTime(2026, 9, 22, 12, 35);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(
              date: testDate,
              sunrise: testSunrise,
              sunset: testSunset,
              currentTime: testTime,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 active items (1 Choghadiya + 2 Muhurtas)
      expect(find.byType(ListItemTabContent), findsNWidgets(3));
      expect(find.text('Amrit'), findsOneWidget);
      expect(find.text('Choghadiya'), findsOneWidget);
      expect(find.text('Abhijit Muhurta'), findsOneWidget);
      expect(find.text('Gulikai Kalam'), findsOneWidget);
      expect(find.text('Muhurta'), findsNWidgets(2));
    });

    testWidgets('Removes expired item and advances to next CurrentItem when interval ends', (tester) async {
      // Start at 12:29:58 PM on Tuesday (Labh Choghadiya is active)
      var currentTime = DateTime(2026, 9, 22, 12, 29, 58);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: ListTabContentNow(
                        date: testDate,
                        sunrise: testSunrise,
                        sunset: testSunset,
                        currentTime: currentTime,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Advance past 12:30:00 PM (Labh ends, Amrit starts)
                          currentTime = DateTime(2026, 9, 22, 12, 30, 05);
                        });
                      },
                      child: const Text('Advance'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Before transition: Labh is active
      expect(find.text('Labh'), findsOneWidget);
      expect(find.text('Amrit'), findsNothing);

      // Tap Advance button to step past interval boundary
      await tester.tap(find.text('Advance'));
      await tester.pumpAndSettle();

      // After transition: Labh was removed (no past item shown), Amrit is now active
      expect(find.text('Labh'), findsNothing);
      expect(find.text('Amrit'), findsOneWidget);
    });

    testWidgets('Past items are never displayed in Now tab', (tester) async {
      // In custom items test, verify that past items are filtered out strictly
      final pastItem = ListItemTabContent(
        title: 'Past Interval',
        timeRange: '08:00 am - 09:00 am',
        indicatorColor: Colors.grey,
        state: ItemTemporalState.past,
      );
      final currentItem = ListItemTabContent(
        title: 'Active Interval',
        timeRange: '11:00 am - 12:00 pm',
        indicatorColor: Colors.green,
        state: ItemTemporalState.current,
      );
      final futureItem = ListItemTabContent(
        title: 'Future Interval',
        timeRange: '02:00 pm - 03:00 pm',
        indicatorColor: Colors.blue,
        state: ItemTemporalState.future,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(
              items: [pastItem, currentItem, futureItem],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Past Interval'), findsNothing);
      expect(find.text('Future Interval'), findsNothing);
      expect(find.text('Active Interval'), findsOneWidget);
      expect(find.byType(ListItemTabContent), findsOneWidget);
    });

    testWidgets('Supports Hindi localization', (tester) async {
      final testTime = DateTime(2026, 9, 22, 12, 35);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(
              date: testDate,
              sunrise: testSunrise,
              sunset: testSunset,
              currentTime: testTime,
              language: AppLanguage.hindi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('अमृत'), findsOneWidget);
      expect(find.text('चौघड़िया'), findsOneWidget);
      expect(find.text('अभिजीत मुहूर्त'), findsOneWidget);
      expect(find.text('गुलिक काल'), findsOneWidget);
      expect(find.text('मुहूर्त'), findsNWidgets(2));
    });

    testWidgets('Supports Gujarati localization', (tester) async {
      final testTime = DateTime(2026, 9, 22, 12, 35);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(
              date: testDate,
              sunrise: testSunrise,
              sunset: testSunset,
              currentTime: testTime,
              language: AppLanguage.gujarati,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('અમૃત'), findsOneWidget);
      expect(find.text('ચોઘડિયા'), findsOneWidget);
      expect(find.text('અભિજિત મુહૂર્ત'), findsOneWidget);
      expect(find.text('ગુલિક કાળ'), findsOneWidget);
      expect(find.text('મુહૂર્ત'), findsNWidgets(2));
    });

    testWidgets('Reacts dynamically when AppDatabase.languageNotifier changes', (tester) async {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
      final testTime = DateTime(2026, 9, 22, 12, 35);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentNow(
              date: testDate,
              sunrise: testSunrise,
              sunset: testSunset,
              currentTime: testTime,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Amrit'), findsOneWidget);
      expect(find.text('Choghadiya'), findsOneWidget);

      // Switch to Hindi
      AppDatabase.instance.languageNotifier.value = AppLanguage.hindi;
      await tester.pumpAndSettle();

      expect(find.text('अमृत'), findsOneWidget);
      expect(find.text('चौघड़िया'), findsOneWidget);

      // Switch to Gujarati
      AppDatabase.instance.languageNotifier.value = AppLanguage.gujarati;
      await tester.pumpAndSettle();

      expect(find.text('અમૃત'), findsOneWidget);
      expect(find.text('ચોઘડિયા'), findsOneWidget);

      // Reset
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
      await tester.pumpAndSettle();
    });
  });
}
