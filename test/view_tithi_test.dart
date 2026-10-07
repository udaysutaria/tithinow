import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sweph/sweph.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/models/alarm_record.dart';
import 'package:tithinow/services/alarm_service.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/views/view_tithi.dart';
import 'package:tithinow/views/view_tithi_detail.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Sweph.init();
    Sweph.swe_set_sid_mode(SiderealMode.SE_SIDM_LAHIRI);
  });

  Widget buildTestableWidget(Widget child, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('TithiView Detailed Tests', () {
    testWidgets('Spans 1 Jan 2026 to 31 Dec 2028 (1096 total items in data)', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      final listTithis = tester.widget<ListTithis>(find.byType(ListTithis));
      expect(listTithis.data, isNotNull);
      expect(listTithis.data!.length, 1096);

      // Verify start and end dates in dataset
      expect(listTithis.data!.first.date, 'Thu, 1 Jan 2026');
      expect(listTithis.data!.last.date, 'Sun, 31 Dec 2028');
    });

    testWidgets('CalendarMonthPagination is fixed at the top with no prev/next buttons', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalendarMonthPagination), findsOneWidget);
      expect(find.byKey(const ValueKey('button_prev')), findsNothing);
      expect(find.byKey(const ValueKey('button_next')), findsNothing);
      expect(find.byKey(const ValueKey('button_today')), findsOneWidget);
    });

    testWidgets('Current date (Today) is the initial visible item with current state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      final currentItemFinder = find.byWidgetPredicate(
        (w) => w is ListItemTithi && w.state == ItemTemporalState.current,
      );
      expect(currentItemFinder, findsOneWidget);

      final currentItem = tester.widget<ListItemTithi>(currentItemFinder);
      expect(currentItem.state, ItemTemporalState.current);
    });

    testWidgets('Scrolling backward reveals PastDates with dimmed opacity', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      // Scroll up (drag down) to scroll backward in time
      await tester.drag(find.byType(ListTithis), const Offset(0, 500));
      await tester.pumpAndSettle();

      // Past items should now be visible
      final pastItemFinder = find.byWidgetPredicate(
        (w) => w is ListItemTithi && w.state == ItemTemporalState.past,
      );
      expect(pastItemFinder, findsWidgets);

      final pastItem = tester.widget<ListItemTithi>(pastItemFinder.first);
      expect(pastItem.state, ItemTemporalState.past);
    });

    testWidgets('Scrolling forward reveals FutureDates with alarm toggle buttons', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      // Scroll down (drag up) to scroll forward in time
      await tester.drag(find.byType(ListTithis), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Future items should now be visible
      final futureItemFinder = find.byWidgetPredicate(
        (w) => w is ListItemTithi && w.state == ItemTemporalState.future,
      );
      expect(futureItemFinder, findsWidgets);

      final futureItem = tester.widget<ListItemTithi>(futureItemFinder.first);
      expect(futureItem.state, ItemTemporalState.future);

      // Future items have ButtonAlarm
      expect(find.byType(ButtonAlarm), findsWidgets);
    });

    testWidgets('Tapping Today button scrolls back to current date', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      // Scroll far forward
      await tester.drag(find.byType(ListTithis), const Offset(0, -1500));
      await tester.pumpAndSettle();

      // Tap Today button in header
      await tester.tap(find.byType(ButtonToday));
      await tester.pumpAndSettle();

      // Today's CurrentItem should be visible again
      final currentItemFinder = find.byWidgetPredicate(
        (w) => w is ListItemTithi && w.state == ItemTemporalState.current,
      );
      expect(currentItemFinder, findsOneWidget);
    });

    testWidgets('Today button styling inverts: dark surface when Today is in viewport, white when not visible', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      // Initially, Today is visible in viewport -> ButtonToday should have inverted styling (isSelected == false)
      ButtonToday todayButton = tester.widget<ButtonToday>(find.byType(ButtonToday));
      expect(todayButton.isSelected, isFalse);

      // Scroll far forward so Today is out of viewport
      await tester.drag(find.byType(ListTithis), const Offset(0, -1500));
      await tester.pumpAndSettle();

      // Today is NOT in viewport -> ButtonToday should have white background (isSelected == true)
      todayButton = tester.widget<ButtonToday>(find.byType(ButtonToday));
      expect(todayButton.isSelected, isTrue);

      // Tap Today button -> scrolls back to Today
      await tester.tap(find.byType(ButtonToday));
      await tester.pumpAndSettle();

      // Today is visible in viewport again -> ButtonToday returns to inverted styling (isSelected == false)
      todayButton = tester.widget<ButtonToday>(find.byType(ButtonToday));
      expect(todayButton.isSelected, isFalse);
    });

    testWidgets('Tapping a Tithi card navigates to TithiDetailView', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      final itemFinder = find.byType(ListItemTithi).hitTestable().first;
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      expect(find.byType(TithiDetailView), findsOneWidget);
    });

    testWidgets('Renders TithiView with Hindi language', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView(initialLanguage: AppLanguage.hindi)),
      );
      await tester.pumpAndSettle();

      // Appbar title in Hindi: तिथि
      expect(find.text('तिथि'), findsOneWidget);

      // Verify ListTithis received Hindi language
      final listTithis = tester.widget<ListTithis>(find.byType(ListTithis));
      expect(listTithis.language, AppLanguage.hindi);

      // Verify CalendarMonthPagination received Hindi language
      final pagination = tester.widget<CalendarMonthPagination>(find.byType(CalendarMonthPagination));
      expect(pagination.language, AppLanguage.hindi);
    });

    testWidgets('Renders TithiView with Gujarati language', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView(initialLanguage: AppLanguage.gujarati)),
      );
      await tester.pumpAndSettle();

      // Appbar title in Gujarati: તિથિ
      expect(find.text('તિથિ'), findsOneWidget);

      // Verify ListTithis received Gujarati language
      final listTithis = tester.widget<ListTithis>(find.byType(ListTithis));
      expect(listTithis.language, AppLanguage.gujarati);

      // Verify CalendarMonthPagination received Gujarati language
      final pagination = tester.widget<CalendarMonthPagination>(find.byType(CalendarMonthPagination));
      expect(pagination.language, AppLanguage.gujarati);
    });

    testWidgets('TithiView reacts dynamically when AppDatabase.languageNotifier changes', (tester) async {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;

      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      final appbarTitle = find.descendant(
        of: find.byType(Appbar),
        matching: find.text('Tithi'),
      );
      expect(appbarTitle, findsOneWidget);

      // Change language dynamically
      AppDatabase.instance.languageNotifier.value = AppLanguage.hindi;
      await tester.pumpAndSettle();

      final appbarHindiTitle = find.descendant(
        of: find.byType(Appbar),
        matching: find.text('तिथि'),
      );
      expect(appbarHindiTitle, findsOneWidget);

      // Reset to English
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    testWidgets('In TithiView on first launch, all items have alarm inactive by default', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      final listTithis = tester.widget<ListTithis>(find.byType(ListTithis));
      expect(listTithis.data, isNotNull);
      final data = listTithis.data!;

      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        expect(
          item.isAlarmActive,
          isFalse,
          reason: 'Item at index $i (day ${i + 1}, date ${item.date}) should have isAlarmActive == false by default',
        );
      }
    });

    testWidgets('Tapping alarm toggle in ListTithis updates alarm state in TithiView', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      // Scroll forward to reveal future items with ButtonAlarm
      await tester.drag(find.byType(ListTithis), const Offset(0, -300));
      await tester.pumpAndSettle();

      final hitTestableAlarms = find.byType(ButtonAlarm).hitTestable();
      expect(hitTestableAlarms, findsWidgets);

      final alarmToTap = hitTestableAlarms.first;
      final initialAlarmWidget = tester.widget<ButtonAlarm>(alarmToTap);
      final initialActive = initialAlarmWidget.isActive;

      await tester.tap(alarmToTap);
      await tester.pumpAndSettle();

      // Modal bottom sheet opens, tap 'Set Alarm' to confirm
      final setAlarmBtn = find.widgetWithText(ElevatedButton, 'Set Alarm');
      expect(setAlarmBtn, findsOneWidget);
      await tester.tap(setAlarmBtn);
      await tester.pumpAndSettle();

      final updatedAlarmWidget = tester.widget<ButtonAlarm>(alarmToTap);
      expect(updatedAlarmWidget.isActive, !initialActive);
    });

    testWidgets('Tapping active repeating alarm and clicking Cancel keeps alarm active in TithiView', (tester) async {
      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month, now.day + 2);
      final repeatingAlarm = AlarmRecord(
        externalId: 7771,
        type: AlarmType.tithi,
        title: 'Chaturthi',
        date: 'Test Date',
        timeDisplay: '07:00 am',
        triggerTime: DateTime(futureDate.year, futureDate.month, futureDate.day, 7, 0),
        isActive: true,
        isRepeating: true,
        parentRuleId: 'rule_chaturthi_repeat',
      );
      AlarmService.instance.alarmsNotifier.value = [repeatingAlarm];

      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      // Scroll forward to reveal future items
      await tester.drag(find.byType(ListTithis), const Offset(0, -200));
      await tester.pumpAndSettle();

      final hitTestableAlarms = find.byType(ButtonAlarm).hitTestable();
      final activeAlarmElements = hitTestableAlarms.evaluate().where((e) {
        final w = e.widget as ButtonAlarm;
        return w.isActive;
      });
      expect(activeAlarmElements.isNotEmpty, isTrue);

      final activeAlarmFinder = find.byWidget(activeAlarmElements.first.widget);
      await tester.tap(activeAlarmFinder);
      await tester.pumpAndSettle();

      expect(find.text('Delete Alarm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Click Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // The alarm button MUST remain active!
      final activeAlarmsAfterCancel = find.byType(ButtonAlarm).hitTestable().evaluate().where((e) {
        final w = e.widget as ButtonAlarm;
        return w.isActive;
      });
      expect(activeAlarmsAfterCancel.isNotEmpty, isTrue);
    });

    testWidgets('Scrolling near bottom dynamically loads dates beyond 31 Dec 2028 without limitation', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      final listTithisBefore = tester.widget<ListTithis>(find.byType(ListTithis));
      expect(listTithisBefore.data, isNotNull);
      final initialCount = listTithisBefore.data!.length;
      expect(initialCount, 1096);
      expect(listTithisBefore.data!.last.date, 'Sun, 31 Dec 2028');

      // Scroll towards the end to trigger dynamic future loading
      final scrollableFinder = find.byType(Scrollable).first;
      final state = tester.state<ScrollableState>(scrollableFinder);
      state.position.jumpTo(state.position.maxScrollExtent - 2000);
      await tester.pumpAndSettle();

      final listTithisAfter = tester.widget<ListTithis>(find.byType(ListTithis));
      expect(listTithisAfter.data!.length, greaterThan(initialCount));
      expect(listTithisAfter.data!.last.dateTime!.year, greaterThanOrEqualTo(2029));
    });

    testWidgets('Scrolling near top dynamically loads dates before 1 Jan 2026 without limitation', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      final listTithisBefore = tester.widget<ListTithis>(find.byType(ListTithis));
      expect(listTithisBefore.data, isNotNull);
      final initialCount = listTithisBefore.data!.length;
      expect(listTithisBefore.data!.first.date, 'Thu, 1 Jan 2026');

      // Scroll near the top to trigger dynamic past loading
      final scrollableFinder = find.byType(Scrollable).first;
      final state = tester.state<ScrollableState>(scrollableFinder);
      state.position.jumpTo(100);
      await tester.pumpAndSettle();

      final listTithisAfter = tester.widget<ListTithis>(find.byType(ListTithis));
      expect(listTithisAfter.data!.length, greaterThan(initialCount));
      expect(listTithisAfter.data!.first.dateTime!.year, lessThanOrEqualTo(2025));
    });
  });
}

