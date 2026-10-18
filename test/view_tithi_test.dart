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
    AppDatabase.initializeFfiIfNeeded();
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

  group('TithiView Search Tests', () {
    testWidgets('Search button exists on AppBar and activates search mode when tapped', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      final searchButton = find.byKey(const ValueKey('button_tithi_search'));
      expect(searchButton, findsOneWidget);

      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      // Search input should now be visible
      expect(find.byKey(const ValueKey('input_tithi_search')), findsOneWidget);

      // Filter chips should be hidden by default
      expect(find.byKey(const ValueKey('chip_filter_all')), findsNothing);
      expect(find.byKey(const ValueKey('chip_filter_festivals')), findsNothing);
      expect(find.byKey(const ValueKey('chip_filter_vrats')), findsNothing);
      expect(find.byKey(const ValueKey('chip_filter_tithis')), findsNothing);

      // Suggestions view is hidden by default
      expect(find.byKey(const ValueKey('chip_suggestion_ekadashi')), findsNothing);
      expect(find.byKey(const ValueKey('chip_suggestion_poonam')), findsNothing);
    });

    testWidgets('Tapping Ekadashi suggestion chip displays upcoming Ekadashi cards with alarms', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView(showPopularSearches: true)),
      );
      await tester.pumpAndSettle();

      // Tap search icon
      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      // Tap Ekadashi suggestion chip
      await tester.tap(find.byKey(const ValueKey('chip_suggestion_ekadashi')));
      await tester.pumpAndSettle();

      // Results should be displayed using ListItemTithi cards
      final resultCards = find.byType(ListItemTithi);
      expect(resultCards, findsWidgets);

      // Verify matching card tithi is Ekadashi
      final firstCard = tester.widget<ListItemTithi>(resultCards.first);
      expect(firstCard.tithi.toLowerCase(), contains('ekadashi'));

      // Alarm buttons exist on future cards
      expect(find.byType(ButtonAlarm), findsWidgets);
    });

    testWidgets('Transliteration search: typing "agiyaras" matches Ekadashi tithis', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      // Enter transliterated Gujarati term "agiyaras"
      await tester.enterText(find.byKey(const ValueKey('input_tithi_search')), 'agiyaras');
      await tester.pumpAndSettle();

      final resultCards = find.byType(ListItemTithi);
      expect(resultCards, findsWidgets);

      final firstCard = tester.widget<ListItemTithi>(resultCards.first);
      expect(firstCard.tithi, 'Ekadashi');
    });

    testWidgets('Transliteration search: typing "poonam" matches Purnima tithis', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      // Enter transliterated term "poonam"
      await tester.enterText(find.byKey(const ValueKey('input_tithi_search')), 'poonam');
      await tester.pumpAndSettle();

      final resultCards = find.byType(ListItemTithi);
      expect(resultCards, findsWidgets);

      final firstCard = tester.widget<ListItemTithi>(resultCards.first);
      expect(firstCard.tithi, 'Purnima');
    });

    testWidgets('Transliteration search: typing "amas" matches Amavasya tithis', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      // Enter transliterated term "amas"
      await tester.enterText(find.byKey(const ValueKey('input_tithi_search')), 'amas');
      await tester.pumpAndSettle();

      final resultCards = find.byType(ListItemTithi);
      expect(resultCards, findsWidgets);

      final firstCard = tester.widget<ListItemTithi>(resultCards.first);
      expect(firstCard.tithi, 'Amavasya');
    });

    testWidgets('Clear button clears search query and restores suggestions', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView(showPopularSearches: true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('input_tithi_search')), 'ekadashi');
      await tester.pumpAndSettle();

      final clearButton = find.byKey(const ValueKey('button_clear_search'));
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Suggestions view should be restored
      expect(find.byKey(const ValueKey('chip_suggestion_ekadashi')), findsOneWidget);
    });

    testWidgets('Closing search restores normal calendar and pagination view', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      // Back button in search mode
      final closeButton = find.byKey(const ValueKey('button_close_search'));
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Main calendar list and month pagination should be restored
      expect(find.byType(CalendarMonthPagination), findsOneWidget);
      expect(find.byType(ListTithis), findsOneWidget);
      expect(find.byKey(const ValueKey('button_tithi_search')), findsOneWidget);
    });

    testWidgets('Search filter tabs have equal width, fill full screen, and display correct tab styling', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TithiView(showSearchFilterTabs: true),
          size: const Size(400, 800),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      final allTab = find.byKey(const ValueKey('chip_filter_all'));
      final festivalsTab = find.byKey(const ValueKey('chip_filter_festivals'));
      final vratsTab = find.byKey(const ValueKey('chip_filter_vrats'));
      final tithisTab = find.byKey(const ValueKey('chip_filter_tithis'));

      expect(allTab, findsOneWidget);
      expect(festivalsTab, findsOneWidget);
      expect(vratsTab, findsOneWidget);
      expect(tithisTab, findsOneWidget);

      final allSize = tester.getSize(allTab);
      final festivalsSize = tester.getSize(festivalsTab);
      final vratsSize = tester.getSize(vratsTab);
      final tithisSize = tester.getSize(tithisTab);

      // All 4 tabs have equal width
      expect(allSize.width, festivalsSize.width);
      expect(allSize.width, vratsSize.width);
      expect(allSize.width, tithisSize.width);

      // Total width fills the entire width of the screen (800 in test environment)
      final totalWidth = allSize.width + festivalsSize.width + vratsSize.width + tithisSize.width;
      expect(totalWidth, 800.0);
    });

    testWidgets('Popular search chips show only 1 language according to settings', (tester) async {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
      await tester.pumpWidget(
        buildTestableWidget(const TithiView(showPopularSearches: true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      // In English, chip should only have 'Ekadashi', not 'Ekadashi (અગિયારસ)'
      expect(find.text('Ekadashi'), findsOneWidget);
      expect(find.text('Ekadashi (અગિયારસ)'), findsNothing);

      // Switch language to Gujarati
      AppDatabase.instance.languageNotifier.value = AppLanguage.gujarati;
      await tester.pumpAndSettle();

      // In Gujarati, chip should only have 'અગિયારસ', not 'અગિયારસ (Ekadashi)'
      expect(find.text('અગિયારસ'), findsOneWidget);
      expect(find.text('અગિયારસ (Ekadashi)'), findsNothing);

      // Restore language
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
    });

    testWidgets('Popular search chips use AppColors.surface, AppColors.outline and AppColors.onSurfaceVariant', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView(showPopularSearches: true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      final actionChip = tester.widget<ActionChip>(find.byKey(const ValueKey('chip_suggestion_ekadashi')));
      expect(actionChip.backgroundColor, AppColors.surface);
      expect(actionChip.side?.color, AppColors.outline);
      expect(actionChip.labelStyle?.color, AppColors.onSurfaceVariant);
    });

    testWidgets('Search finds festival even when multiple festivals are assigned to a day', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TithiView(showSearchFilterTabs: true)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_tithi_search')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('input_tithi_search')), 'kali chaudas');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('chip_filter_festivals')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('input_tithi_search')), findsOneWidget);
    });
  });
}

