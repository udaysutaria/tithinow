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

  const sampleAlarms = [
    AlarmData(
      title: 'Amrit',
      date: 'Sun, 06 Sep 2026',
      time: '02:00 pm - 03:31 pm',
      type: AlarmType.choghadiya,
      tag: 'Choghadiya',
      isAlarmActive: true,
    ),
    AlarmData(
      title: 'Abhijit Muhurt',
      date: 'Sun, 06 Sep 2026',
      time: '11:50 am - 12:42 pm',
      type: AlarmType.muhurta,
      tag: 'Muhurta',
      isAlarmActive: true,
    ),
    AlarmData(
      title: 'Brahma Muhurta',
      date: 'Mon, 07 Sep 2026',
      time: '04:51 am - 05:39 am',
      type: AlarmType.muhurta,
      tag: 'Muhurta',
      isAlarmActive: true,
    ),
    AlarmData(
      title: 'Dashmi',
      date: 'Sun, 06 Sep 2026',
      time: '02:18 am',
      type: AlarmType.tithi,
      tag: 'Tithi',
      isAlarmActive: true,
    ),
  ];

  group('AlarmsView Structure Tests', () {
    setUp(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    tearDown(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    testWidgets('Mobile renders EmptyAlarmsState when no alarms scheduled', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Appbar), findsOneWidget);
      expect(find.byType(EmptyAlarmsState), findsOneWidget);
      expect(find.byType(ListAlarms), findsNothing);
      expect(find.byType(NavBottom), findsOneWidget);

      // Verify no language dropdown in AppBar
      expect(find.byKey(const ValueKey('button_language_switch')), findsNothing);

      // Verify English empty state message
      expect(find.text('No Alarms Scheduled'), findsOneWidget);

      // Open drawer via menu button
      final menuButtonFinder = find.descendant(
        of: find.byType(Appbar),
        matching: find.byType(InkWell),
      );
      await tester.tap(menuButtonFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(NavDrawer), findsOneWidget);
    });

    testWidgets('Desktop renders 2-column with NavSide, Appbar, and EmptyAlarmsState', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(),
          size: const Size(1200, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavSide), findsOneWidget);
      expect(find.byType(Appbar), findsOneWidget);
      expect(find.byType(EmptyAlarmsState), findsOneWidget);
      expect(find.byType(ListAlarms), findsNothing);
      expect(find.byKey(const ValueKey('button_language_switch')), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets('Renders ListAlarms when alarmData is provided', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(alarmData: sampleAlarms),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyAlarmsState), findsNothing);
      expect(find.byType(ListAlarms), findsOneWidget);
      expect(find.byType(ListItemAlarms), findsNWidgets(4));

      expect(find.text('Amrit'), findsOneWidget);
      expect(find.text('Abhijit Muhurt'), findsOneWidget);
      expect(find.text('Brahma Muhurta'), findsOneWidget);
      expect(find.text('Dashmi'), findsOneWidget);
    });
  });

  group('AlarmsView Language Switching Tests', () {
    setUp(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    tearDown(() {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    testWidgets('Renders Hindi EmptyAlarmsState when initialLanguage is Hindi', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(
            initialLanguage: AppLanguage.hindi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Appbar title has 'अलार्म'
      expect(find.text('अलार्म'), findsOneWidget);
      expect(find.byType(EmptyAlarmsState), findsOneWidget);
      expect(find.text('कोई अलार्म सेट नहीं है'), findsOneWidget);
    });

    testWidgets('Renders Gujarati EmptyAlarmsState when initialLanguage is Gujarati', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(
            initialLanguage: AppLanguage.gujarati,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Appbar title has 'એલાર્મ'
      expect(find.text('એલાર્મ'), findsOneWidget);
      expect(find.byType(EmptyAlarmsState), findsOneWidget);
      expect(find.text('કોઈ એલાર્મ સેટ નથી'), findsOneWidget);
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
      expect(find.text('No Alarms Scheduled'), findsOneWidget);
      expect(find.text('Alarms'), findsNWidgets(2)); // Appbar + NavBottom

      // Switch to Hindi dynamically
      AppDatabase.instance.languageNotifier.value = AppLanguage.hindi;
      await tester.pumpAndSettle();

      expect(notifiedLanguage, AppLanguage.hindi);
      expect(find.text('कोई अलार्म सेट नहीं है'), findsOneWidget);
      expect(find.text('अलार्म'), findsNWidgets(2)); // Appbar + NavBottom

      // Switch to Gujarati dynamically
      AppDatabase.instance.languageNotifier.value = AppLanguage.gujarati;
      await tester.pumpAndSettle();

      expect(notifiedLanguage, AppLanguage.gujarati);
      expect(find.text('કોઈ એલાર્મ સેટ નથી'), findsOneWidget);
      expect(find.text('એલાર્મ'), findsNWidgets(2)); // Appbar + NavBottom

      // Switch back to English
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
      await tester.pumpAndSettle();

      expect(notifiedLanguage, AppLanguage.english);
      expect(find.text('No Alarms Scheduled'), findsOneWidget);
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
            alarmData: sampleAlarms,
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
            alarmData: sampleAlarms,
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
