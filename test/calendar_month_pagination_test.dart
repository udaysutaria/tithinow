import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarMonthPagination / Monthpagination Tests', () {
    testWidgets('Renders month title "September" with 22px Sora and #BAC9CB', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              month: 'September',
              isDesktop: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFinder = find.text('September');
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget(textFinder);
      expect(textWidget.style?.fontSize, 22);
      expect(textWidget.style?.color, AppColors.onSurface);
      expect(textWidget.style?.fontWeight, FontWeight.w600);
      expect(textWidget.style?.fontFamily, contains('Sora'));
    });

    testWidgets('Embeds ButtonToday component', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              isDesktop: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ButtonToday), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('ButtonPrev and ButtonNext are visible ONLY on desktop', (tester) async {
      // Desktop View
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              isDesktop: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('button_prev')), findsOneWidget);
      expect(find.byKey(const ValueKey('button_next')), findsOneWidget);
      expect(find.byType(ButtonToday), findsOneWidget);

      // Mobile View
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              isDesktop: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('button_prev')), findsNothing);
      expect(find.byKey(const ValueKey('button_next')), findsNothing);
      expect(find.byType(ButtonToday), findsOneWidget);
    });

    testWidgets('ButtonPrev updates the month previous (September -> August)', (tester) async {
      DateTime? changedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              date: DateTime(2026, 9),
              isDesktop: true,
              onMonthChanged: (date) => changedDate = date,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('September'), findsOneWidget);
      expect(find.text('August'), findsNothing);

      // Tap ButtonPrev
      await tester.tap(find.byKey(const ValueKey('button_prev')));
      await tester.pumpAndSettle();

      // Month is now August!
      expect(find.text('August'), findsOneWidget);
      expect(find.text('September'), findsNothing);
      expect(changedDate, DateTime(2026, 8));

      // Tap ButtonPrev again -> July
      await tester.tap(find.byKey(const ValueKey('button_prev')));
      await tester.pumpAndSettle();

      expect(find.text('July'), findsOneWidget);
      expect(find.text('August'), findsNothing);
      expect(changedDate, DateTime(2026, 7));
    });

    testWidgets('ButtonNext updates the month forward (September -> October)', (tester) async {
      DateTime? changedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              date: DateTime(2026, 9),
              isDesktop: true,
              onMonthChanged: (date) => changedDate = date,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('September'), findsOneWidget);
      expect(find.text('October'), findsNothing);

      // Tap ButtonNext
      await tester.tap(find.byKey(const ValueKey('button_next')));
      await tester.pumpAndSettle();

      // Month is now October!
      expect(find.text('October'), findsOneWidget);
      expect(find.text('September'), findsNothing);
      expect(changedDate, DateTime(2026, 10));

      // Tap ButtonNext again -> November
      await tester.tap(find.byKey(const ValueKey('button_next')));
      await tester.pumpAndSettle();

      expect(find.text('November'), findsOneWidget);
      expect(find.text('October'), findsNothing);
      expect(changedDate, DateTime(2026, 11));
    });

    testWidgets('ButtonPrev updates month and year across year boundary (Jan 2026 -> Dec 2025)', (tester) async {
      DateTime? changedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              date: DateTime(2026, 1),
              isDesktop: true,
              onMonthChanged: (date) => changedDate = date,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('January'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);

      // Tap ButtonPrev to go back to December of previous year
      await tester.tap(find.byKey(const ValueKey('button_prev')));
      await tester.pumpAndSettle();

      expect(find.text('December'), findsOneWidget);
      expect(find.text('2025'), findsOneWidget);
      expect(changedDate, DateTime(2025, 12));
    });

    testWidgets('ButtonNext updates month and year across year boundary (Dec 2026 -> Jan 2027)', (tester) async {
      DateTime? changedDate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              date: DateTime(2026, 12),
              isDesktop: true,
              onMonthChanged: (date) => changedDate = date,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('December'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);

      // Tap ButtonNext to move to January of next year
      await tester.tap(find.byKey(const ValueKey('button_next')));
      await tester.pumpAndSettle();

      expect(find.text('January'), findsOneWidget);
      expect(find.text('2027'), findsOneWidget);
      expect(changedDate, DateTime(2027, 1));
    });

    testWidgets('Automatically resolves desktop visibility via MediaQuery width', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Monthpagination(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('button_prev')), findsOneWidget);
      expect(find.byKey(const ValueKey('button_next')), findsOneWidget);

      // Screen width < 720px (Mobile)
      tester.view.physicalSize = const Size(412, 800);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Monthpagination(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('button_prev')), findsNothing);
      expect(find.byKey(const ValueKey('button_next')), findsNothing);
      expect(find.byType(ButtonToday), findsOneWidget);
    });

    testWidgets('Triggers onPrevTap, onNextTap, and onTodayTap callbacks alongside month updates', (tester) async {
      bool prevTapped = false;
      bool nextTapped = false;
      bool todayTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              isDesktop: true,
              onPrevTap: () => prevTapped = true,
              onNextTap: () => nextTapped = true,
              onTodayTap: () => todayTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('button_prev')));
      await tester.pumpAndSettle();
      expect(prevTapped, isTrue);

      await tester.tap(find.byKey(const ValueKey('button_next')));
      await tester.pumpAndSettle();
      expect(nextTapped, isTrue);

      await tester.tap(find.byKey(const ValueKey('button_today')));
      await tester.pumpAndSettle();
      expect(todayTapped, isTrue);
    });

    testWidgets('Supports Hindi localization when navigating previous and forward', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Monthpagination(
              date: DateTime(2026, 9),
              language: AppLanguage.hindi,
              isDesktop: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('सितंबर'), findsOneWidget);

      // Tap Prev -> August ('अगस्त')
      await tester.tap(find.byKey(const ValueKey('button_prev')));
      await tester.pumpAndSettle();
      expect(find.text('अगस्त'), findsOneWidget);

      // Tap Next twice -> September ('सितंबर') -> October ('अक्टूबर')
      await tester.tap(find.byKey(const ValueKey('button_next')));
      await tester.pumpAndSettle();
      expect(find.text('सितंबर'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('button_next')));
      await tester.pumpAndSettle();
      expect(find.text('अक्टूबर'), findsOneWidget);
    });
  });
}
