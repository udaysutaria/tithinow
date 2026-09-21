import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListItemPanchang Tests', () {
    testWidgets('Renders Mobile Slider with 2x2 grid and dot indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: ListItemPanchang(
                  mode: PanchangLayoutMode.mobileSlider,
                  data: PanchangData(
                    nakshatra: 'Dhanishtha',
                    month: 'Bhadrapada',
                    vrat: 'No Vrat',
                    festival: 'No Festival',
                    sunrise: '06:27 AM',
                    sunset: '06:33 PM',
                    moonrise: '05:08 PM',
                    moonset: '04:56 AM',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1 should display its items
      expect(find.text('Nakshatras'), findsOneWidget);
      expect(find.text('Dhanishtha'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Bhadrapada'), findsOneWidget);
      expect(find.text('Vrat'), findsOneWidget);
      expect(find.text('No Vrat'), findsOneWidget);
      expect(find.text('Festival'), findsOneWidget);
      expect(find.text('No Festival'), findsOneWidget);

      // Verify PageView is present
      expect(find.byType(PageView), findsOneWidget);

      // Swipe to Slide 2
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Slide 2 items
      expect(find.text('Sunrise'), findsOneWidget);
      expect(find.text('06:27 AM'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
      expect(find.text('06:33 PM'), findsOneWidget);
      expect(find.text('Moonrise'), findsOneWidget);
      expect(find.text('05:08 PM'), findsOneWidget);
      expect(find.text('Moonset'), findsOneWidget);
      expect(find.text('04:56 AM'), findsOneWidget);
    });

    testWidgets('Conditional Formatting: inactive vs active values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListItemPanchang(
              mode: PanchangLayoutMode.desktopGrid4x2,
              data: PanchangData(
                nakshatra: 'Dhanishtha',
                month: 'Bhadrapada',
                vrat: 'No Vrat',
                festival: 'Diwali',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find "No Vrat" text widget
      final noVratFinder = find.text('No Vrat');
      expect(noVratFinder, findsOneWidget);
      final Text noVratText = tester.widget(noVratFinder);
      expect(noVratText.style?.color, AppColors.onSurface);

      // Find active festival "Diwali" text widget
      final diwaliFinder = find.text('Diwali');
      expect(diwaliFinder, findsOneWidget);
      final Text diwaliText = tester.widget(diwaliFinder);
      expect(diwaliText.style?.color, AppColors.onSurfaceVariant);

      // Non-conditional item "Dhanishtha"
      final dhanishthaFinder = find.text('Dhanishtha');
      expect(dhanishthaFinder, findsOneWidget);
      final Text dhanishthaText = tester.widget(dhanishthaFinder);
      expect(dhanishthaText.style?.color, AppColors.onSurfaceVariant);
    });

    testWidgets('Desktop Grid 4x2 renders all 8 items simultaneously', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListItemPanchang(
              mode: PanchangLayoutMode.desktopGrid4x2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 8 items should be present on screen without pagination
      expect(find.text('Nakshatras'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Vrat'), findsOneWidget);
      expect(find.text('Festival'), findsOneWidget);
      expect(find.text('Sunrise'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
      expect(find.text('Moonrise'), findsOneWidget);
      expect(find.text('Moonset'), findsOneWidget);
    });

    testWidgets('Desktop Grid 2x4 renders all 8 items simultaneously', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListItemPanchang(
              mode: PanchangLayoutMode.desktopGrid2x4,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nakshatras'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Vrat'), findsOneWidget);
      expect(find.text('Festival'), findsOneWidget);
      expect(find.text('Sunrise'), findsOneWidget);
      expect(find.text('Sunset'), findsOneWidget);
      expect(find.text('Moonrise'), findsOneWidget);
      expect(find.text('Moonset'), findsOneWidget);
    });
  });
}
