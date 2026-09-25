import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('ListAlarms Tests', () {
    testWidgets('Renders EmptyAlarmsState when no data or items provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListAlarms(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyAlarmsState), findsOneWidget);
      expect(find.byType(ListItemAlarms), findsNothing);
      expect(find.text('No Alarms Scheduled'), findsOneWidget);
    });

    testWidgets('Renders exactly 4 items using ListItemAlarms when data is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListAlarms(
              data: sampleAlarms,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 4 ListItemAlarms widgets
      final itemFinders = find.byType(ListItemAlarms);
      expect(itemFinders, findsNWidgets(4));

      // Item 1: Choghadiya ('Amrit')
      expect(find.text('Amrit'), findsOneWidget);
      expect(find.text('Choghadiya'), findsOneWidget);
      expect(find.text('02:00 pm - 03:31 pm'), findsOneWidget);

      // Item 2: Muhurta ('Abhijit Muhurt')
      expect(find.text('Abhijit Muhurt'), findsOneWidget);
      expect(find.text('11:50 am - 12:42 pm'), findsOneWidget);

      // Item 3: Muhurta ('Brahma Muhurta')
      expect(find.text('Brahma Muhurta'), findsOneWidget);
      expect(find.text('04:51 am - 05:39 am'), findsOneWidget);

      // Verify 'Muhurta' tag appears for both Muhurta items
      expect(find.text('Muhurta'), findsNWidgets(2));

      // Item 4: Tithi ('Dashmi')
      expect(find.text('Dashmi'), findsOneWidget);
      expect(find.text('Tithi'), findsOneWidget);
      expect(find.text('02:18 am'), findsOneWidget);
    });

    testWidgets('Renders ButtonAlarm on all 4 items and ButtonEdit only on Tithi item', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListAlarms(
              data: sampleAlarms,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 4 ButtonAlarm widgets (one per item)
      expect(find.byType(ButtonAlarm), findsNWidgets(4));

      // Exactly 1 ButtonEdit widget (only on Tithi item)
      expect(find.byType(ButtonEdit), findsOneWidget);
    });

    testWidgets('Supports interactive alarm toggle on items', (tester) async {
      int? toggledIndex;
      bool? toggledState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListAlarms(
              data: sampleAlarms,
              onAlarmTap: (index, isActive) {
                toggledIndex = index;
                toggledState = isActive;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final alarmButtons = find.byType(ButtonAlarm);
      expect(alarmButtons, findsNWidgets(4));

      // Tap first alarm button (initially active -> toggles off)
      await tester.tap(alarmButtons.at(0));
      await tester.pumpAndSettle();

      expect(toggledIndex, 0);
      expect(toggledState, isFalse);

      // Tap again (toggles back on)
      await tester.tap(alarmButtons.at(0));
      await tester.pumpAndSettle();

      expect(toggledIndex, 0);
      expect(toggledState, isTrue);

      // Tap second alarm button
      await tester.tap(alarmButtons.at(1));
      await tester.pumpAndSettle();

      expect(toggledIndex, 1);
      expect(toggledState, isFalse);
    });

    testWidgets('Tapping edit button on Tithi item triggers onEditTap callback', (tester) async {
      int? editedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListAlarms(
              data: sampleAlarms,
              onEditTap: (index) {
                editedIndex = index;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editButtonFinder = find.byType(ButtonEdit);
      expect(editButtonFinder, findsOneWidget);

      await tester.tap(editButtonFinder);
      await tester.pumpAndSettle();

      expect(editedIndex, 3); // 4th item (index 3) is Tithi
    });

    testWidgets('Renders optional header title with tertiary styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListAlarms(
              title: 'Scheduled Alarms',
              data: sampleAlarms,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('Scheduled Alarms');
      expect(titleFinder, findsOneWidget);

      final Text titleText = tester.widget(titleFinder);
      expect(titleText.style?.color, AppColors.tertiary);
      expect(titleText.style?.fontSize, 16.0);
      expect(titleText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('Supports custom items injection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListAlarms(
              items: [
                ListItemAlarms.choghadiya(
                  title: 'Shubh',
                  date: 'Tue, 08 Sep 2026',
                  timeRange: '09:00 am - 10:30 am',
                ),
                ListItemAlarms.muhurta(
                  title: 'Vijaya Muhurta',
                  date: 'Tue, 08 Sep 2026',
                  timeRange: '02:15 pm - 03:05 pm',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only 2 custom items rendered
      expect(find.byType(ListItemAlarms), findsNWidgets(2));
      expect(find.text('Shubh'), findsOneWidget);
      expect(find.text('Vijaya Muhurta'), findsOneWidget);
      expect(find.text('Amrit'), findsNothing);
    });

    testWidgets('Supports custom data injection via AlarmData', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListAlarms(
              data: [
                AlarmData(
                  title: 'Custom Tithi',
                  date: 'Wed, 09 Sep 2026',
                  time: '04:00 am',
                  type: AlarmType.tithi,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListItemAlarms), findsOneWidget);
      expect(find.text('Custom Tithi'), findsOneWidget);
      expect(find.byType(ButtonEdit), findsOneWidget);
    });

    testWidgets('Renders items in Hindi when language is AppLanguage.hindi', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListAlarms(
              language: AppLanguage.hindi,
              data: [
                AlarmData(
                  title: 'अमृत',
                  date: 'रवि, 06 सितंबर 2026',
                  time: '02:00 pm - 03:31 pm',
                  type: AlarmType.choghadiya,
                  tag: 'चौघड़िया',
                ),
                AlarmData(
                  title: 'अभिजीत मुहूर्त',
                  date: 'रवि, 06 सितंबर 2026',
                  time: '11:50 am - 12:42 pm',
                  type: AlarmType.muhurta,
                  tag: 'मुहूर्त',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListItemAlarms), findsNWidgets(2));
      expect(find.text('अमृत'), findsOneWidget);
      expect(find.text('चौघड़िया'), findsOneWidget);
      expect(find.text('अभिजीत मुहूर्त'), findsOneWidget);
      expect(find.text('मुहूर्त'), findsOneWidget);
    });

    testWidgets('Renders items in Gujarati when language is AppLanguage.gujarati', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListAlarms(
              language: AppLanguage.gujarati,
              data: [
                AlarmData(
                  title: 'અમૃત',
                  date: 'રવિ, 06 સપ્ટેમ્બર 2026',
                  time: '02:00 pm - 03:31 pm',
                  type: AlarmType.choghadiya,
                  tag: 'ચોઘડિયા',
                ),
                AlarmData(
                  title: 'અભિજિત મુહૂર્ત',
                  date: 'રવિ, 06 સપ્ટેમ્બર 2026',
                  time: '11:50 am - 12:42 pm',
                  type: AlarmType.muhurta,
                  tag: 'મુહૂર્ત',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListItemAlarms), findsNWidgets(2));
      expect(find.text('અમૃત'), findsOneWidget);
      expect(find.text('ચોઘડિયા'), findsOneWidget);
      expect(find.text('અભિજિત મુહૂર્ત'), findsOneWidget);
      expect(find.text('મુહૂર્ત'), findsOneWidget);
    });

    testWidgets('Reacts dynamically when AppDatabase.languageNotifier changes on EmptyAlarmsState', (tester) async {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListAlarms(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Alarms Scheduled'), findsOneWidget);

      // Switch to Hindi
      AppDatabase.instance.languageNotifier.value = AppLanguage.hindi;
      await tester.pumpAndSettle();

      expect(find.text('कोई अलार्म सेट नहीं है'), findsOneWidget);

      // Switch to Gujarati
      AppDatabase.instance.languageNotifier.value = AppLanguage.gujarati;
      await tester.pumpAndSettle();

      expect(find.text('કોઈ એલાર્મ સેટ નથી'), findsOneWidget);

      // Reset
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });
  });
}
