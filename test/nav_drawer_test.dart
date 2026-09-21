import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/views/view_settings.dart';
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

  group('Menulist Widget Tests', () {
    testWidgets('renders all 5 default destinations', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: Menulist(selectedIndex: 0),
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tithi'), findsOneWidget);
      expect(find.text('Alarms'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('invokes onDestinationSelected when item is tapped', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: Menulist(
              selectedIndex: 0,
              onDestinationSelected: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(3));

      await tester.tap(find.text('Alarms'));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(2));
    });

    testWidgets('highlights selectedIndex with AppColors.primary', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: Menulist(selectedIndex: 1),
          ),
        ),
      );

      final todayText = tester.widget<Text>(find.text('Today'));
      final tithiText = tester.widget<Text>(find.text('Tithi'));

      expect(tithiText.style?.color, equals(AppColors.primary));
      expect(todayText.style?.color, equals(AppColors.onSurfaceVariant));
    });
  });

  group('NavDrawer Widget Tests', () {
    testWidgets('renders drawer header and closes via close button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            drawer: const NavDrawer(selectedIndex: 0),
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Text('Open Drawer'),
              ),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.text('Open Drawer'));
      await tester.pumpAndSettle();

      expect(find.byType(NavDrawer), findsOneWidget);
      expect(find.byType(Menulist), findsOneWidget);
      expect(find.byTooltip('Close Menu'), findsOneWidget);

      // Close drawer
      await tester.tap(find.byTooltip('Close Menu'));
      await tester.pumpAndSettle();

      expect(find.byType(NavDrawer), findsNothing);
    });
  });

  group('TodayView Drawer Integration Tests', () {
    testWidgets('mobile Appbar menu button opens NavDrawer', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const TodayView(),
          size: const Size(390, 844),
        ),
      );

      // Ensure drawer is not initially visible
      expect(find.byType(NavDrawer), findsNothing);

      // Tap menu button on mobile Appbar
      final menuButtonFinder = find.descendant(
        of: find.byType(Appbar),
        matching: find.byType(InkWell),
      );
      expect(menuButtonFinder, findsWidgets);
      await tester.tap(menuButtonFinder.first);
      await tester.pumpAndSettle();

      // Drawer should now be visible
      expect(find.byType(NavDrawer), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('Settings View Drawer Integration Tests', () {
    testWidgets('mobile Appbar menu button in Settings opens NavDrawer with Settings highlighted', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Settings(isOnboarding: false),
          size: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure drawer is not initially visible
      expect(find.byType(NavDrawer), findsNothing);

      // Tap menu button on mobile Appbar
      final menuButtonFinder = find.descendant(
        of: find.byType(Appbar),
        matching: find.byType(InkWell),
      );
      expect(menuButtonFinder, findsWidgets);
      await tester.tap(menuButtonFinder.first);
      await tester.pumpAndSettle();

      // Drawer should now be visible
      expect(find.byType(NavDrawer), findsOneWidget);

      // Verify that Settings item is selected/highlighted in primary color
      final settingsTexts = tester.widgetList<Text>(find.text('Settings'));
      // Find the text widget that belongs to Menulist
      final drawerSettingsText = settingsTexts.firstWhere(
        (t) => t.style?.fontSize == 16,
      );
      expect(drawerSettingsText.style?.color, equals(AppColors.primary));
    });
  });
}
