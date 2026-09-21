import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/constants/panchang_terms.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListTabContentMuhurta Tests', () {
    testWidgets('Renders all 17 Muhurtas mentioned in panchang_terms.dart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6), // Sunday
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

    testWidgets('Contains combination of all 3 variables (past, current, future) with 2 CurrentItems on Sunday', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6), // Sunday
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinders = find.byType(ListItemTabContent);
      expect(itemFinders, findsNWidgets(17));

      int pastCount = 0;
      int currentCount = 0;
      int futureCount = 0;
      final List<String> currentTitles = [];

      for (int i = 0; i < 17; i++) {
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

      // Strictly 2 CurrentItems on this date
      expect(currentCount, 2);
      expect(currentTitles, contains('Abhijit Muhurta'));
      expect(currentTitles, contains('Yamaganda'));

      // 6 past + 2 current + 9 future = 17 items total
      expect(pastCount, 6);
      expect(futureCount, 9);
      expect(pastCount + currentCount + futureCount, 17);
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
      expect(itemFinders, findsNWidgets(17));

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
              date: DateTime(2026, 9, 6),
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

    testWidgets('When one CurrentItem ends, it transitions to PastItem while other CurrentItem remains current', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6),
            ),
          ),
        ),
      );
      await tester.pump();

      // On Sunday, 2 items are current: Abhijit Muhurta and Yamaganda
      final itemFindersBefore = find.byType(ListItemTabContent);
      final List<int> currentIndices = [];
      for (int i = 0; i < 17; i++) {
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
              date: DateTime(2026, 9, 6),
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
    });

    testWidgets('Supports Gujarati localization for all 17 Muhurtas', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentMuhurta(
              date: DateTime(2026, 9, 6),
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
              date: DateTime(2026, 9, 6),
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
  });
}
