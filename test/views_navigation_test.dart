import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/views/app_navigator.dart';
import 'package:tithinow/views/view_about.dart';
import 'package:tithinow/views/view_alarms.dart';
import 'package:tithinow/views/view_tithi.dart';
import 'package:tithinow/views/view_tithi_detail.dart';
import 'package:tithinow/views/view_today.dart';
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

  group('TodayView Updates', () {
    testWidgets('Desktop layout does NOT render settings icon in Appbar', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TodayView(),
          size: const Size(1200, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavSide), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets('Mobile layout navigates to TithiView on NavBottom index 1 tap', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TodayView(),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tithi'));
      await tester.pumpAndSettle();

      expect(find.byType(TithiView), findsOneWidget);
    });

    testWidgets('Appbar displays localized titles: English Today, Hindi आज के दिन, Gujarati આજના દિવસે', (tester) async {
      // English
      await tester.pumpWidget(
        buildTestableWidget(
          const TodayView(initialLanguage: AppLanguage.english),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(Appbar), matching: find.text('Today')), findsOneWidget);

      // Hindi
      await tester.pumpWidget(
        buildTestableWidget(
          const TodayView(initialLanguage: AppLanguage.hindi),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(Appbar), matching: find.text('आज के दिन')), findsOneWidget);

      // Gujarati
      await tester.pumpWidget(
        buildTestableWidget(
          const TodayView(initialLanguage: AppLanguage.gujarati),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(Appbar), matching: find.text('આજના દિવસે')), findsOneWidget);
    });
  });

  group('TithiView Tests', () {
    testWidgets('Mobile renders CalendarMonthPagination, ListTithis, Appbar, NavBottom and drawer', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TithiView(),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalendarMonthPagination), findsOneWidget);
      expect(find.byType(ListTithis), findsOneWidget);
      expect(find.byType(NavBottom), findsOneWidget);

      // Verify no prev/next buttons on CalendarMonthPagination
      expect(find.byKey(const ValueKey('button_prev')), findsNothing);
      expect(find.byKey(const ValueKey('button_next')), findsNothing);
      expect(find.byKey(const ValueKey('button_today')), findsOneWidget);

      // Open drawer
      final menuButtonFinder = find.descendant(
        of: find.byType(Appbar),
        matching: find.byType(InkWell),
      );
      await tester.tap(menuButtonFinder.first);
      await tester.pumpAndSettle();

      expect(find.byType(NavDrawer), findsOneWidget);
    });

    testWidgets('Desktop renders 2-column with NavSide, CalendarMonthPagination and ListTithis', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TithiView(),
          size: const Size(1200, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavSide), findsOneWidget);
      expect(find.byType(CalendarMonthPagination), findsOneWidget);
      expect(find.byType(ListTithis), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);

      // Verify no prev/next buttons on desktop either
      expect(find.byKey(const ValueKey('button_prev')), findsNothing);
      expect(find.byKey(const ValueKey('button_next')), findsNothing);
      expect(find.byKey(const ValueKey('button_today')), findsOneWidget);
    });

    testWidgets('Tapping Tithi item card navigates to TithiDetailView', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TithiView(),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the first visible, hit-testable Tithi card
      final itemFinder = find.byType(ListItemTithi).hitTestable().first;
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      expect(find.byType(TithiDetailView), findsOneWidget);
    });
  });

  group('TithiDetailView Tests', () {
    testWidgets('Mobile renders back button, CardTithi, ListItemPanchang, and CardTimings', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TithiDetailView(),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tithi Detail'), findsOneWidget); // Appbar title
      expect(find.byType(CardTithi), findsOneWidget);
      expect(find.byType(ListItemPanchang), findsOneWidget);
      expect(find.byType(CardTimings), findsOneWidget);
      expect(find.byType(NavBottom), findsNothing);
    });

    testWidgets('Desktop renders 2-column with NavSide, CardTithi, ListItemPanchang, and CardTimings', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TithiDetailView(),
          size: const Size(1200, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavSide), findsOneWidget);
      expect(find.text('Tithi Detail'), findsOneWidget); // Appbar title
      expect(find.byType(CardTithi), findsOneWidget);
      expect(find.byType(ListItemPanchang), findsOneWidget);
      expect(find.byType(CardTimings), findsOneWidget);
    });

    testWidgets('Toggles alarm on CardTithi', (tester) async {
      bool? lastAlarmState;
      await tester.pumpWidget(
        buildTestableWidget(
          TithiDetailView(
            onAlarmChanged: (active) => lastAlarmState = active,
          ),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final cardTithiFinder = find.byType(CardTithi);
      final alarmButtonFinder = find.descendant(
        of: cardTithiFinder,
        matching: find.byType(ButtonAlarm),
      );
      expect(alarmButtonFinder, findsOneWidget);

      // Initially inactive
      ButtonAlarm button = tester.widget(alarmButtonFinder);
      expect(button.isActive, false);

      // Tap to toggle
      await tester.tap(alarmButtonFinder);
      await tester.pumpAndSettle();

      button = tester.widget(alarmButtonFinder);
      expect(button.isActive, true);
      expect(lastAlarmState, true);

      // Tap again to toggle off
      await tester.tap(alarmButtonFinder);
      await tester.pumpAndSettle();

      button = tester.widget(alarmButtonFinder);
      expect(button.isActive, false);
      expect(lastAlarmState, false);
    });

    testWidgets('Past date hides Now tab and Choghadiya/Muhurta items do not have alarm buttons', (tester) async {
      final pastDate = DateTime.now().subtract(const Duration(days: 3));
      await tester.pumpWidget(
        buildTestableWidget(
          TithiDetailView(dateTime: pastDate),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final timingTabs = find.byType(Timingtabs);
      expect(find.descendant(of: timingTabs, matching: find.text('Now')), findsNothing);
      expect(find.descendant(of: timingTabs, matching: find.text('Choghadiya')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('Muhurta')), findsOneWidget);

      // Choghadiya tab is selected by default (index 0).
      // Since it's a past date, no items in Choghadiya should have ButtonAlarm!
      final choghadiyaList = find.byType(ListTabContentChoghadiya);
      expect(choghadiyaList, findsOneWidget);
      final choghadiyaAlarms = find.descendant(
        of: choghadiyaList,
        matching: find.byType(ButtonAlarm),
      );
      expect(choghadiyaAlarms, findsNothing);
    });

    testWidgets('Future date hides Now tab and Choghadiya items have alarm buttons', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 3));
      await tester.pumpWidget(
        buildTestableWidget(
          TithiDetailView(dateTime: futureDate),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final timingTabs = find.byType(Timingtabs);
      expect(find.descendant(of: timingTabs, matching: find.text('Now')), findsNothing);
      expect(find.descendant(of: timingTabs, matching: find.text('Choghadiya')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('Muhurta')), findsOneWidget);

      // Choghadiya tab is selected by default.
      // Since it's a future date, future items should have ButtonAlarm!
      final choghadiyaList = find.byType(ListTabContentChoghadiya);
      expect(choghadiyaList, findsOneWidget);
      final choghadiyaAlarms = find.descendant(
        of: choghadiyaList,
        matching: find.byType(ButtonAlarm),
      );
      expect(choghadiyaAlarms, findsWidgets);
    });

    testWidgets('Current date (Today) shows Now tab and acts same as today view', (tester) async {
      final todayDate = DateTime.now();
      await tester.pumpWidget(
        buildTestableWidget(
          TithiDetailView(dateTime: todayDate),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      final timingTabs = find.byType(Timingtabs);
      expect(find.descendant(of: timingTabs, matching: find.text('Now')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('Choghadiya')), findsOneWidget);
      expect(find.descendant(of: timingTabs, matching: find.text('Muhurta')), findsOneWidget);

      // Now tab is active by default
      expect(find.byType(ListTabContentNow), findsOneWidget);
    });
  });

  group('AlarmsView Tests', () {
    testWidgets('Mobile renders Alarms label, Appbar, NavBottom and drawer', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alarms'), findsNWidgets(2)); // Appbar title, bottom nav label
      expect(find.byType(NavBottom), findsOneWidget);
    });

    testWidgets('Desktop renders 2-column with NavSide and Alarms label', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AlarmsView(),
          size: const Size(1200, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavSide), findsOneWidget);
      expect(find.text('Alarms'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });
  });

  group('AboutView Tests', () {
    testWidgets('Mobile renders About Appbar, Content and drawer', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AboutView(),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget); // Appbar title
      expect(find.byType(Content), findsOneWidget);
      expect(find.text('Official Website'), findsOneWidget);
      expect(find.text('Source Code'), findsOneWidget);
      expect(find.text('Libraries'), findsOneWidget);
      expect(find.text('Author'), findsOneWidget);

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect((image.image as AssetImage).assetName, 'assets/images/AboutBrandIcon.png');
      expect(image.fit, BoxFit.contain);
    });

    testWidgets('Desktop renders 2-column with NavSide and About Content', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AboutView(),
          size: const Size(1200, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavSide), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.byType(Content), findsOneWidget);
      expect(find.text('Official Website'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets('Localizes About Appbar title and description across languages', (tester) async {
      // English
      await tester.pumpWidget(
        buildTestableWidget(
          const AboutView(initialLanguage: AppLanguage.english),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(Appbar), matching: find.text('About')), findsOneWidget);

      // Hindi
      await tester.pumpWidget(
        buildTestableWidget(
          const AboutView(initialLanguage: AppLanguage.hindi),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(Appbar), matching: find.text('परिचय')), findsOneWidget);

      // Gujarati
      await tester.pumpWidget(
        buildTestableWidget(
          const AboutView(initialLanguage: AppLanguage.gujarati),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(Appbar), matching: find.text('પરિચય')), findsOneWidget);
    });
  });

  group('NavBottom and NavSide Localization Tests', () {
    testWidgets('NavBottom localizes labels across English, Hindi, and Gujarati', (tester) async {
      // English
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            bottomNavigationBar: NavBottom(
              language: AppLanguage.english,
              ignoreDesktopCheck: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tithi'), findsOneWidget);
      expect(find.text('Alarms'), findsOneWidget);

      // Hindi
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            bottomNavigationBar: NavBottom(
              language: AppLanguage.hindi,
              ignoreDesktopCheck: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('आज'), findsOneWidget);
      expect(find.text('तिथि'), findsOneWidget);
      expect(find.text('अलार्म'), findsOneWidget);

      // Gujarati
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            bottomNavigationBar: NavBottom(
              language: AppLanguage.gujarati,
              ignoreDesktopCheck: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('આજ'), findsOneWidget);
      expect(find.text('તિથિ'), findsOneWidget);
      expect(find.text('એલાર્મ'), findsOneWidget);
    });

    testWidgets('NavSide localizes tooltips/labels across English, Hindi, and Gujarati', (tester) async {
      // English
      final enItems = NavSide.getItems(AppLanguage.english);
      expect(enItems[0].label, 'Today');
      expect(enItems[1].label, 'Tithi');
      expect(enItems[2].label, 'Alarms');
      expect(enItems[3].label, 'Settings');
      expect(enItems[4].label, 'About');

      // Hindi
      final hiItems = NavSide.getItems(AppLanguage.hindi);
      expect(hiItems[0].label, 'आज');
      expect(hiItems[1].label, 'तिथि');
      expect(hiItems[2].label, 'अलार्म');
      expect(hiItems[3].label, 'सेटिंग्स');
      expect(hiItems[4].label, 'परिचय');

      // Gujarati
      final guItems = NavSide.getItems(AppLanguage.gujarati);
      expect(guItems[0].label, 'આજ');
      expect(guItems[1].label, 'તિથિ');
      expect(guItems[2].label, 'એલાર્મ');
      expect(guItems[3].label, 'સેટિંગ્સ');
      expect(guItems[4].label, 'પરિચય');
    });
  });

  group('AppShell Tests', () {
    testWidgets('Renders TodayView initially and switches tabs preserving views in IndexedStack', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppShell(initialIndex: 0),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // TodayView is visible onstage; other tabs are preserved in memory (offstage)
      expect(find.byType(TodayView), findsOneWidget);
      expect(find.byType(TithiView, skipOffstage: false), findsOneWidget);
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);
      var indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, 0);

      // Tap on Tithi in NavBottom
      await tester.tap(find.text('Tithi').first);
      await tester.pumpAndSettle();

      // TithiView is now onstage; TodayView is preserved offstage in memory
      expect(find.byType(TithiView), findsOneWidget);
      expect(find.byType(TodayView, skipOffstage: false), findsOneWidget);
      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, 1);

      // Tap on Alarms in NavBottom
      await tester.tap(find.text('Alarms').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlarmsView), findsOneWidget);
      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, 2);

      // Tap back on Today in NavBottom
      await tester.tap(find.text('Today').first);
      await tester.pumpAndSettle();

      expect(find.byType(TodayView), findsOneWidget);
      indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, 0);
    });
  });
}

