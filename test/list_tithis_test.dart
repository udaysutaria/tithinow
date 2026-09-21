import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListTithis Tests', () {
    testWidgets('Renders exactly 7 demo items using ListItemTithi by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 7 items are rendered
      final items = find.byType(ListItemTithi);
      expect(items, findsNWidgets(7));

      // Check dates of the 7 consecutive items
      expect(find.text('Sun, 20 Sep 2026'), findsOneWidget);
      expect(find.text('Mon, 21 Sep 2026'), findsOneWidget);
      expect(find.text('Tue, 22 Sep 2026'), findsOneWidget);
      expect(find.text('Wed, 23 Sep 2026'), findsOneWidget);
      expect(find.text('Thu, 24 Sep 2026'), findsOneWidget);
      expect(find.text('Fri, 25 Sep 2026'), findsOneWidget);
      expect(find.text('Sat, 26 Sep 2026'), findsOneWidget);

      // Check tithi names
      expect(find.text('Dashami'), findsOneWidget);
      expect(find.text('Ekadashi'), findsOneWidget);
      expect(find.text('Dwadashi'), findsOneWidget);
      expect(find.text('Trayodashi'), findsOneWidget);
      expect(find.text('Chaturdashi'), findsOneWidget);
      expect(find.text('Purnima'), findsOneWidget);
      expect(find.text('Pratipada'), findsOneWidget);
    });

    testWidgets('Demo items contain 3 PastItem, 1 CurrentItem, and 3 FutureItem states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listItems = tester.widgetList<ListItemTithi>(find.byType(ListItemTithi)).toList();
      expect(listItems.length, 7);

      // 3 PastItems
      expect(listItems[0].state, ItemTemporalState.past);
      expect(listItems[1].state, ItemTemporalState.past);
      expect(listItems[2].state, ItemTemporalState.past);

      // 1 CurrentItem
      expect(listItems[3].state, ItemTemporalState.current);

      // 3 FutureItems
      expect(listItems[4].state, ItemTemporalState.future);
      expect(listItems[5].state, ItemTemporalState.future);
      expect(listItems[6].state, ItemTemporalState.future);

      // Past items and Current item should NOT have ButtonAlarm, Future items should have ButtonAlarm (3 total)
      expect(find.byType(ButtonAlarm), findsNWidgets(3));
    });

    testWidgets('CurrentItem is styled with primary brand border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final currentFinder = find.byKey(const ValueKey('tithi_item_3'));
      expect(currentFinder, findsOneWidget);

      final containerFinder = find.descendant(
        of: currentFinder,
        matching: find.byType(Container),
      ).first;

      final Container container = tester.widget(containerFinder);
      final decoration = container.decoration as ShapeDecoration;
      final shape = decoration.shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.primary);
    });

    testWidgets('Conditional formatting: active Vrats & Festivals in tertiary vs inactive dimmed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Active festival: 'Anant Chaturdashi'
      final anantFinder = find.text('Anant Chaturdashi');
      expect(anantFinder, findsOneWidget);
      final Text anantText = tester.widget(anantFinder);
      expect(anantText.style?.color, AppColors.tertiary);

      // Active festival: 'Bhadrapada Purnima'
      final purnimaFestFinder = find.text('Bhadrapada Purnima');
      expect(purnimaFestFinder, findsOneWidget);
      final Text purnimaFestText = tester.widget(purnimaFestFinder);
      expect(purnimaFestText.style?.color, AppColors.tertiary);

      // Active vrat: 'Pradosh Vrat'
      final pradoshFinder = find.text('Pradosh Vrat');
      expect(pradoshFinder, findsOneWidget);
      final Text pradoshText = tester.widget(pradoshFinder);
      expect(pradoshText.style?.color, AppColors.tertiary);

      // Inactive Vrat: 'No Vrat' rendered with onSurface color
      final noVratFinder = find.text('No Vrat');
      expect(noVratFinder, findsWidgets);
      final Text noVratText = tester.widget(noVratFinder.first);
      expect(noVratText.style?.color, AppColors.onSurface);
    });

    testWidgets('Supports interactive alarm toggle on future items', (tester) async {
      int? tappedIndex;
      bool? tappedIsActive;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(
                onAlarmTap: (index, isActive) {
                  tappedIndex = index;
                  tappedIsActive = isActive;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 future items have ButtonAlarm (indices 4, 5, 6)
      final alarmButtons = find.byType(ButtonAlarm);
      expect(alarmButtons, findsNWidgets(3));

      // Scroll to make sure item 4 is visible
      await tester.ensureVisible(alarmButtons.at(0));
      await tester.pumpAndSettle();

      // Default active alarms has index 4 active (first ButtonAlarm)
      final ButtonAlarm firstAlarm = tester.widget(alarmButtons.at(0));
      expect(firstAlarm.isActive, isTrue);

      // Toggle index 4 from active to inactive
      await tester.tap(alarmButtons.at(0));
      await tester.pumpAndSettle();

      expect(tappedIndex, 4);
      expect(tappedIsActive, isFalse);

      final ButtonAlarm firstAlarmAfter = tester.widget(alarmButtons.at(0));
      expect(firstAlarmAfter.isActive, isFalse);

      // Scroll to make sure item 5 is visible
      await tester.ensureVisible(alarmButtons.at(1));
      await tester.pumpAndSettle();

      // Toggle index 5 from inactive to active
      await tester.tap(alarmButtons.at(1));
      await tester.pumpAndSettle();

      expect(tappedIndex, 5);
      expect(tappedIsActive, isTrue);

      final ButtonAlarm secondAlarmAfter = tester.widget(alarmButtons.at(1));
      expect(secondAlarmAfter.isActive, isTrue);
    });

    testWidgets('Tapping a Tithi card triggers onItemTap callback', (tester) async {
      int? tappedItemIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(
                onItemTap: (index) {
                  tappedItemIndex = index;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the current item (index 3, Trayodashi)
      await tester.ensureVisible(find.text('Trayodashi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trayodashi'));
      await tester.pumpAndSettle();

      expect(tappedItemIndex, 3);

      // Tap the first past item (index 0, Dashami)
      await tester.ensureVisible(find.text('Dashami'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dashami'));
      await tester.pumpAndSettle();

      expect(tappedItemIndex, 0);
    });

    testWidgets('Supports custom title rendering', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(
                title: 'Upcoming Tithis',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Tithis'), findsOneWidget);
    });

    testWidgets('Supports custom items injection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(
                items: [
                  PastItem.past(
                    date: 'Wed, 16 Sep 2026',
                    tithi: 'Shashthi',
                    paksha: 'Shukla',
                  ),
                  CurrentItem.current(
                    date: 'Thu, 17 Sep 2026',
                    tithi: 'Saptami',
                    paksha: 'Shukla',
                  ),
                  FutureItem.future(
                    date: 'Fri, 18 Sep 2026',
                    tithi: 'Ashtami',
                    paksha: 'Shukla',
                    isAlarmActive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListItemTithi), findsNWidgets(3));
      expect(find.text('Shashthi'), findsOneWidget);
      expect(find.text('Saptami'), findsOneWidget);
      expect(find.text('Ashtami'), findsOneWidget);
      expect(find.byType(ButtonAlarm), findsOneWidget);
    });

    testWidgets('Supports custom data injection via TithiData', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(
                data: [
                  TithiData(
                    date: 'Sun, 04 Oct 2026',
                    tithi: 'Navami',
                    paksha: 'Krishna',
                    state: ItemTemporalState.past,
                  ),
                  TithiData(
                    date: 'Mon, 05 Oct 2026',
                    tithi: 'Dashami',
                    paksha: 'Krishna',
                    state: ItemTemporalState.current,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListItemTithi), findsNWidgets(2));
      expect(find.text('Navami'), findsOneWidget);
      expect(find.text('Dashami'), findsOneWidget);
      expect(find.text('Krishna'), findsNWidgets(2));
    });

    test('ListTithis.createDemoItems static helper generates 7 items', () {
      final items = ListTithis.createDemoItems();
      expect(items.length, 7);
      expect(items[0].state, ItemTemporalState.past);
      expect(items[1].state, ItemTemporalState.past);
      expect(items[2].state, ItemTemporalState.past);
      expect(items[3].state, ItemTemporalState.current);
      expect(items[4].state, ItemTemporalState.future);
      expect(items[5].state, ItemTemporalState.future);
      expect(items[6].state, ItemTemporalState.future);
    });

    testWidgets('Renders demo items in Hindi when language is AppLanguage.hindi', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(
                language: AppLanguage.hindi,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Hindi Tithi names
      expect(find.text('दशमी'), findsOneWidget);
      expect(find.text('एकादशी'), findsOneWidget);
      expect(find.text('द्वादशी'), findsOneWidget);
      expect(find.text('त्रयोदशी'), findsOneWidget);
      expect(find.text('चतुर्दशी'), findsOneWidget);
      expect(find.text('पूर्णिमा'), findsOneWidget);
      expect(find.text('प्रतिपदा'), findsOneWidget);

      // Check Hindi Paksha names
      expect(find.text('शुक्ल'), findsNWidgets(6));
      expect(find.text('कृष्ण'), findsOneWidget);

      // Check Hindi Active Vrat / Festival
      expect(find.text('परिवर्तिनी एकादशी'), findsOneWidget);
      expect(find.text('अनंत चतुर्दशी'), findsOneWidget);

      // Check Hindi Date
      expect(find.text('रविवार, 20 सितंबर 2026'), findsOneWidget);
    });

    testWidgets('Renders demo items in Gujarati when language is AppLanguage.gujarati', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListTithis(
                language: AppLanguage.gujarati,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Gujarati Tithi names
      expect(find.text('દશમ'), findsOneWidget);
      expect(find.text('અગિયારસ'), findsOneWidget);
      expect(find.text('બારસ'), findsOneWidget);
      expect(find.text('તેરસ'), findsOneWidget);
      expect(find.text('ચૌદસ'), findsOneWidget);
      expect(find.text('પૂનમ'), findsOneWidget);
      expect(find.text('પડવો'), findsOneWidget);

      // Check Gujarati Paksha names
      expect(find.text('શુક્લ'), findsNWidgets(6));
      expect(find.text('કૃષ્ણ'), findsOneWidget);

      // Check Gujarati Active Vrat / Festival
      expect(find.text('પરિવર્તિની અગિયારસ'), findsOneWidget);
      expect(find.text('અનંત ચતુર્દશી'), findsOneWidget);

      // Check Gujarati Date
      expect(find.text('રવિવાર, 20 સપ્ટેમ્બર 2026'), findsOneWidget);
    });

    test('createDemoItems respects language parameter', () {
      final hindiItems = ListTithis.createDemoItems(language: AppLanguage.hindi);
      expect(hindiItems.length, 7);
      expect(hindiItems[0].language, AppLanguage.hindi);

      final gujaratiItems = ListTithis.createDemoItems(language: AppLanguage.gujarati);
      expect(gujaratiItems.length, 7);
      expect(gujaratiItems[0].language, AppLanguage.gujarati);
    });
  });
}
