import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/button_alarm.dart';
import 'package:tithinow/widgets/list_item_tithi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListItemTithi Tests', () {
    testWidgets('PastItem renders with dimmed opacity and outline border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.past(
                date: 'Sat, 23 Sep 2026',
                tithi: 'Dwadashi',
                paksha: 'Shukla',
                vrat: 'No Vrat',
                festival: 'No Festival',
                lunarDay: 13,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sat, 23 Sep 2026'), findsOneWidget);
      expect(find.text('Dwadashi'), findsOneWidget);
      expect(find.text('Shukla'), findsOneWidget);
      expect(find.text('No Vrat'), findsOneWidget);
      expect(find.text('No Festival'), findsOneWidget);

      // No ButtonAlarm in PastItem
      expect(find.byType(ButtonAlarm), findsNothing);

      // Verify Opacity widgets are used for dimming
      expect(find.byType(Opacity), findsWidgets);
    });

    testWidgets('CurrentItem renders with primary brand border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.current(
                date: 'Thu, 24 Sep 2026',
                tithi: 'Trayodashi',
                paksha: 'Shukla',
                lunarDay: 14,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thu, 24 Sep 2026'), findsOneWidget);
      expect(find.text('Trayodashi'), findsOneWidget);
      expect(find.text('Shukla'), findsOneWidget);

      // No ButtonAlarm in CurrentItem
      expect(find.byType(ButtonAlarm), findsNothing);

      // Find Container and check primary border
      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      final decoration = container.decoration as ShapeDecoration;
      final shape = decoration.shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.primary);
    });

    testWidgets('FutureItem renders ButtonAlarm and active tertiary festival', (tester) async {
      bool alarmToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.future(
                date: 'Fri, 25 Sep 2026',
                tithi: 'Chaturdashi',
                paksha: 'Shukla',
                vrat: 'No Vrat',
                festival: 'Anant Chaturdashi',
                lunarDay: 15,
                isAlarmActive: false,
                onAlarmTap: () {
                  alarmToggled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fri, 25 Sep 2026'), findsOneWidget);
      expect(find.text('Chaturdashi'), findsOneWidget);
      expect(find.text('Shukla'), findsOneWidget);
      expect(find.text('No Vrat'), findsOneWidget);
      expect(find.text('Anant Chaturdashi'), findsOneWidget);

      // Check active festival color is tertiary
      final festivalFinder = find.text('Anant Chaturdashi');
      final Text festivalText = tester.widget(festivalFinder);
      expect(festivalText.style?.color, AppColors.tertiary);

      // ButtonAlarm is present
      expect(find.byType(ButtonAlarm), findsOneWidget);

      // Tap ButtonAlarm
      await tester.tap(find.byType(ButtonAlarm));
      expect(alarmToggled, isTrue);
    });
  });
}
