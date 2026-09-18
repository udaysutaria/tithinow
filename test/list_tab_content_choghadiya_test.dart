import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/button_alarm.dart';
import 'package:tithinow/widgets/list_item_tab_content.dart';
import 'package:tithinow/widgets/list_tab_content_choghadiya.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListTabContentChoghadiya Tests', () {
    testWidgets('Renders Day and Night Choghadiya headers with #D9B686 and 16px', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentChoghadiya(
              date: DateTime(2026, 9, 6), // Sunday
              currentIntervalIndex: 3,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check "Day Choghadiya" header
      final dayHeaderFinder = find.text('Day Choghadiya');
      expect(dayHeaderFinder, findsOneWidget);
      final Text dayHeaderText = tester.widget(dayHeaderFinder);
      expect(dayHeaderText.style?.color, AppColors.tertiary);
      expect(dayHeaderText.style?.fontSize, 16.0);
      expect(dayHeaderText.style?.fontWeight, FontWeight.w600);

      // Check "Night Choghadiya" header
      final nightHeaderFinder = find.text('Night Choghadiya');
      expect(nightHeaderFinder, findsOneWidget);
      final Text nightHeaderText = tester.widget(nightHeaderFinder);
      expect(nightHeaderText.style?.color, AppColors.tertiary);
      expect(nightHeaderText.style?.fontSize, 16.0);
      expect(nightHeaderText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('Renders exactly 16 items (8 Day + 8 Night) with strictly 1 CurrentItem', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentChoghadiya(
              date: DateTime(2026, 9, 6), // Sunday
              currentIntervalIndex: 3, // 4th slot of Day is current
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly 16 items
      final itemFinders = find.byType(ListItemTabContent);
      expect(itemFinders, findsNWidgets(16));

      int pastCount = 0;
      int currentCount = 0;
      int futureCount = 0;

      for (int i = 0; i < 16; i++) {
        final ListItemTabContent item = tester.widget(itemFinders.at(i));
        if (item.state == ItemTemporalState.past) pastCount++;
        if (item.state == ItemTemporalState.current) currentCount++;
        if (item.state == ItemTemporalState.future) futureCount++;
      }

      // Exactly 1 current item across both lists
      expect(currentCount, 1);
      // Index 3 is current -> indices 0, 1, 2 are past (3 items)
      expect(pastCount, 3);
      // Indices 4..15 are future (12 items)
      expect(futureCount, 12);
    });

    testWidgets('Single CurrentItem in Night section correctly marks all Day items past', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentChoghadiya(
              date: DateTime(2026, 9, 6), // Sunday
              currentIntervalIndex: 10, // 3rd slot of Night is current
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final itemFinders = find.byType(ListItemTabContent);
      expect(itemFinders, findsNWidgets(16));

      int pastCount = 0;
      int currentCount = 0;
      int futureCount = 0;

      for (int i = 0; i < 16; i++) {
        final ListItemTabContent item = tester.widget(itemFinders.at(i));
        if (item.state == ItemTemporalState.past) pastCount++;
        if (item.state == ItemTemporalState.current) currentCount++;
        if (item.state == ItemTemporalState.future) futureCount++;
      }

      expect(currentCount, 1);
      // 10 items before index 10 are past
      expect(pastCount, 10);
      // 5 items after index 10 are future
      expect(futureCount, 5);
    });

    testWidgets('Allows interactive alarm toggle on future items', (tester) async {
      int? tappedIndex;
      bool? tappedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentChoghadiya(
              date: DateTime(2026, 9, 6),
              currentIntervalIndex: 3,
              onAlarmTap: (slotIndex, isActive) {
                tappedIndex = slotIndex;
                tappedState = isActive;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Future items have ButtonAlarm
      final alarmButtons = find.byType(ButtonAlarm);
      expect(alarmButtons, findsWidgets);

      // Tap first future item alarm button
      await tester.tap(alarmButtons.first);
      await tester.pumpAndSettle();

      expect(tappedIndex, 4); // First future index after current (index 3)
      expect(tappedState, isTrue);
    });

    testWidgets('When CurrentItem ends, it transitions to PastItem and next FutureItem becomes CurrentItem', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTabContentChoghadiya(
              date: DateTime(2026, 9, 6),
              currentIntervalIndex: 3,
            ),
          ),
        ),
      );
      await tester.pump();

      // Before transition: index 3 is CurrentItem, index 4 is FutureItem
      final itemsBefore = find.byType(ListItemTabContent);
      final ListItemTabContent item3Before = tester.widget(itemsBefore.at(3));
      final ListItemTabContent item4Before = tester.widget(itemsBefore.at(4));
      expect(item3Before.state, ItemTemporalState.current);
      expect(item4Before.state, ItemTemporalState.future);

      // Trigger countdown end callback on item 3
      item3Before.onCountdownEnded?.call();
      await tester.pumpAndSettle();

      // After transition: index 3 is now PastItem, index 4 is now CurrentItem!
      final itemsAfter = find.byType(ListItemTabContent);
      final ListItemTabContent item3After = tester.widget(itemsAfter.at(3));
      final ListItemTabContent item4After = tester.widget(itemsAfter.at(4));
      expect(item3After.state, ItemTemporalState.past);
      expect(item4After.state, ItemTemporalState.current);

      // "Ended" string is never present in the widget tree
      expect(find.text('Ended'), findsNothing);
    });
  });
}
