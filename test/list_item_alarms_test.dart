import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/widgets/button_alarm.dart';
import 'package:tithinow/widgets/button_edit.dart';
import 'package:tithinow/widgets/list_item_alarms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListItemAlarms Tests', () {
    testWidgets('Renders Choghadiya alarm item with ButtonAlarm only', (tester) async {
      bool alarmToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemAlarms.choghadiya(
                title: 'Amrit',
                date: 'Sun, 06 Sep 2026',
                timeRange: '02:18 am - 02:18 am',
                onAlarmTap: () {
                  alarmToggled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Amrit'), findsOneWidget);
      expect(find.text('Choghadiya'), findsOneWidget);
      expect(find.text('Sun, 06 Sep 2026'), findsOneWidget);
      expect(find.text('02:18 am - 02:18 am'), findsOneWidget);

      // Single alarm button, no edit button
      expect(find.byType(ButtonAlarm), findsOneWidget);
      expect(find.byType(ButtonEdit), findsNothing);

      // Tap alarm button
      await tester.tap(find.byType(ButtonAlarm));
      expect(alarmToggled, isTrue);
    });

    testWidgets('Renders Muhurta alarm item with ButtonAlarm only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemAlarms.muhurta(
                title: 'Abhijit Muhurt',
                date: 'Sun, 06 Sep 2026',
                timeRange: '02:18 am - 02:18 am',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Abhijit Muhurt'), findsOneWidget);
      expect(find.text('Muhurta'), findsOneWidget);
      expect(find.text('Sun, 06 Sep 2026'), findsOneWidget);
      expect(find.text('02:18 am - 02:18 am'), findsOneWidget);

      expect(find.byType(ButtonAlarm), findsOneWidget);
      expect(find.byType(ButtonEdit), findsNothing);
    });

    testWidgets('Renders Tithi alarm item with both ButtonEdit and ButtonAlarm', (tester) async {
      bool editTapped = false;
      bool alarmTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemAlarms.tithi(
                title: 'Dashmi',
                date: 'Sun, 06 Sep 2026',
                time: '02:18 am',
                onEditTap: () {
                  editTapped = true;
                },
                onAlarmTap: () {
                  alarmTapped = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashmi'), findsOneWidget);
      expect(find.text('Tithi'), findsOneWidget);
      expect(find.text('Sun, 06 Sep 2026'), findsOneWidget);
      expect(find.text('02:18 am'), findsOneWidget);

      // Both buttons must be present
      expect(find.byType(ButtonEdit), findsOneWidget);
      expect(find.byType(ButtonAlarm), findsOneWidget);

      // Tap edit button
      await tester.tap(find.byType(ButtonEdit));
      expect(editTapped, isTrue);

      // Tap alarm button
      await tester.tap(find.byType(ButtonAlarm));
      expect(alarmTapped, isTrue);
    });
  });
}
