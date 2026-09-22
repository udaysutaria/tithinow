import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CardTimings and Timingtabs Tests', () {
    testWidgets('Renders all 3 tabs and defaults to Now tab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardTimings(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check tab labels inside Timingtabs
      final timingTabs = find.byType(Timingtabs);
      expect(find.descendant(of: timingTabs, matching: find.text('Now')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('Choghadiya')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('Muhurta')), findsOneWidget);

      // Defaults to Now tab
      expect(find.byType(ListTabContentNow), findsOneWidget);
      expect(find.byType(ListTabContentChoghadiya), findsNothing);
      expect(find.byType(ListTabContentMuhurta), findsNothing);
    });

    testWidgets('Switches between Now, Choghadiya, and Muhurta tabs on tap', (tester) async {
      int? changedIndex;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardTimings(
                onTabChanged: (index) => changedIndex = index,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final timingTabs = find.byType(Timingtabs);

      // Tap Choghadiya tab
      await tester.tap(find.descendant(of: timingTabs, matching: find.text('Choghadiya')));
      await tester.pumpAndSettle();

      expect(changedIndex, 1);
      expect(find.byType(ListTabContentNow), findsNothing);
      expect(find.byType(ListTabContentChoghadiya), findsOneWidget);
      expect(find.byType(ListTabContentMuhurta), findsNothing);

      // Tap Muhurta tab
      await tester.tap(find.descendant(of: timingTabs, matching: find.text('Muhurta')));
      await tester.pumpAndSettle();

      expect(changedIndex, 2);
      expect(find.byType(ListTabContentNow), findsNothing);
      expect(find.byType(ListTabContentChoghadiya), findsNothing);
      expect(find.byType(ListTabContentMuhurta), findsOneWidget);

      // Tap Now tab back
      await tester.tap(find.descendant(of: timingTabs, matching: find.text('Now')));
      await tester.pumpAndSettle();

      expect(changedIndex, 0);
      expect(find.byType(ListTabContentNow), findsOneWidget);
    });

    testWidgets('Respects initialTabIndex parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardTimings(initialTabIndex: 2),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListTabContentMuhurta), findsOneWidget);
    });

    testWidgets('Renders tabs and contents in Hindi when language is set to Hindi', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardTimings(
              language: AppLanguage.hindi,
              currentTime: DateTime(2026, 9, 22, 12, 35),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final timingTabs = find.byType(Timingtabs);
      expect(find.descendant(of: timingTabs, matching: find.text('अभी')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('चौघड़िया')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('मुहूर्त')), findsOneWidget);

      // Now tab content localized in Hindi
      expect(find.text('अमृत'), findsOneWidget);
      expect(find.text('अभिजीत मुहूर्त'), findsOneWidget);
    });

    testWidgets('Renders tabs and contents in Gujarati when language is set to Gujarati', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardTimings(
              language: AppLanguage.gujarati,
              currentTime: DateTime(2026, 9, 22, 12, 35),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final timingTabs = find.byType(Timingtabs);
      expect(find.descendant(of: timingTabs, matching: find.text('અત્યારે')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('ચોઘડિયા')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('મુહૂર્ત')), findsOneWidget);

      // Now tab content localized in Gujarati
      expect(find.text('અમૃત'), findsOneWidget);
      expect(find.text('અભિજિત મુહૂર્ત'), findsOneWidget);
    });

    testWidgets('Reacts dynamically when AppDatabase.languageNotifier changes', (tester) async {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardTimings(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final timingTabs = find.byType(Timingtabs);
      expect(find.descendant(of: timingTabs, matching: find.text('Now')), findsOneWidget);

      // Change to Hindi
      AppDatabase.instance.languageNotifier.value = AppLanguage.hindi;
      await tester.pumpAndSettle();

      expect(find.descendant(of: timingTabs, matching: find.text('अभी')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('चौघड़िया')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('मुहूर्त')), findsOneWidget);

      // Change to Gujarati
      AppDatabase.instance.languageNotifier.value = AppLanguage.gujarati;
      await tester.pumpAndSettle();

      expect(find.descendant(of: timingTabs, matching: find.text('અત્યારે')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('ચોઘડિયા')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('મુહૂર્ત')), findsOneWidget);

      // Reset to English
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
      await tester.pumpAndSettle();
    });
  });
}
