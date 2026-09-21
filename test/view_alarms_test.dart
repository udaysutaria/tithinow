import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/views/view_alarms.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('AlarmsView Structure Tests', () {
    setUp(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    tearDown(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    testWidgets('Mobile renders Appbar with title, ListAlarms without duplicate label, and NavBottom', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Appbar), findsOneWidget);
      expect(find.byType(ListAlarms), findsOneWidget);
      expect(find.byType(ListItemAlarms), findsNWidgets(4));
      expect(find.byType(NavBottom), findsOneWidget);

      // Verify no language dropdown in AppBar
      expect(find.byKey(const ValueKey('button_language_switch')), findsNothing);

      // Verify English demo content
      expect(find.text('Amrit'), findsOneWidget);
      expect(find.text('Choghadiya'), findsOneWidget);
      expect(find.text('Abhijit Muhurt'), findsOneWidget);
      expect(find.text('Brahma Muhurta'), findsOneWidget);
      expect(find.text('Dashmi'), findsOneWidget);

      // Open drawer via menu button
      final menuButtonFinder = find.descendant(
        of: find.byType(Appbar),
        matching: find.byType(InkWell),
      );
      await tester.tap(menuButtonFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(NavDrawer), findsOneWidget);
    });

    testWidgets('Desktop renders 2-column with NavSide, Appbar, and ListAlarms without duplicate label', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(),
          size: const Size(1200, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavSide), findsOneWidget);
      expect(find.byType(Appbar), findsOneWidget);
      expect(find.byType(ListAlarms), findsOneWidget);
      expect(find.byType(ListItemAlarms), findsNWidgets(4));
      expect(find.byKey(const ValueKey('button_language_switch')), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });
  });

  group('AlarmsView Language Switching Tests', () {
    setUp(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    tearDown(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    testWidgets('Renders Hindi content when initialLanguage is Hindi', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(
            initialLanguage: AppLanguage.hindi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only Appbar title has 'अलार्म' (no duplicate label above list)
      expect(find.text('अलार्म'), findsOneWidget);
      expect(find.text('अमृत'), findsOneWidget);
      expect(find.text('चौघड़िया'), findsOneWidget);
      expect(find.text('अभिजीत मुहूर्त'), findsOneWidget);
      expect(find.text('ब्रह्म मुहूर्त'), findsOneWidget);
      expect(find.text('दशमी'), findsOneWidget);
      expect(find.text('तिथि'), findsOneWidget);
    });

    testWidgets('Renders Gujarati content when initialLanguage is Gujarati', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(
            initialLanguage: AppLanguage.gujarati,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only Appbar title has 'એલાર્મ' (no duplicate label above list)
      expect(find.text('એલાર્મ'), findsOneWidget);
      expect(find.text('અમૃત'), findsOneWidget);
      expect(find.text('ચોઘડિયા'), findsOneWidget);
      expect(find.text('અભિજિત મુહૂર્ત'), findsOneWidget);
      expect(find.text('બ્રહ્મ મુહૂર્ત'), findsOneWidget);
      expect(find.text('દશમ'), findsOneWidget);
      expect(find.text('તિથિ'), findsOneWidget);
    });

    testWidgets('Reacts dynamically when AppDatabase.languageNotifier changes', (tester) async {
      AppLanguage? notifiedLanguage;

      await tester.pumpWidget(
        buildTestableWidget(
          AlarmsView(
            onLanguageChanged: (lang) {
              notifiedLanguage = lang;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially English
      expect(find.text('Amrit'), findsOneWidget);
      expect(find.text('Alarms'), findsNWidgets(2)); // Appbar + NavBottom

      // Switch to Hindi dynamically
      AppDatabase.instance.languageNotifier.value = AppLanguage.hindi;
      await tester.pumpAndSettle();

      expect(notifiedLanguage, AppLanguage.hindi);
      expect(find.text('अमृत'), findsOneWidget);
      expect(find.text('चौघड़िया'), findsOneWidget);
      expect(find.text('अलार्म'), findsNWidgets(2)); // Appbar + NavBottom

      // Switch to Gujarati dynamically
      AppDatabase.instance.languageNotifier.value = AppLanguage.gujarati;
      await tester.pumpAndSettle();

      expect(notifiedLanguage, AppLanguage.gujarati);
      expect(find.text('અમૃત'), findsOneWidget);
      expect(find.text('ચોઘડિયા'), findsOneWidget);
      expect(find.text('એલાર્મ'), findsNWidgets(2)); // Appbar + NavBottom

      // Switch back to English
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
      await tester.pumpAndSettle();

      expect(notifiedLanguage, AppLanguage.english);
      expect(find.text('Amrit'), findsOneWidget);
      expect(find.text('Alarms'), findsNWidgets(2)); // Appbar + NavBottom
    });
  });

  group('AlarmsView Interactivity Tests', () {
    setUp(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    tearDown(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    testWidgets('Tapping alarm toggle button invokes onAlarmTap callback', (tester) async {
      int? tappedIndex;
      bool? tappedActive;

      await tester.pumpWidget(
        buildTestableWidget(
          AlarmsView(
            onAlarmTap: (index, isActive) {
              tappedIndex = index;
              tappedActive = isActive;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alarmButtons = find.byType(ButtonAlarm);
      expect(alarmButtons, findsNWidgets(4));

      await tester.tap(alarmButtons.first);
      await tester.pumpAndSettle();

      expect(tappedIndex, 0);
      expect(tappedActive, isFalse);
    });

    testWidgets('Tapping edit button on Tithi item invokes onEditTap callback', (tester) async {
      int? editedIndex;

      await tester.pumpWidget(
        buildTestableWidget(
          AlarmsView(
            onEditTap: (index) {
              editedIndex = index;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editButton = find.byType(ButtonEdit);
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(editedIndex, 3);
    });
  });
}
