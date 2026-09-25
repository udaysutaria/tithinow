import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/views/view_settings.dart';
import 'package:tithinow/views/view_today.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  group('Settings View - Onboarding Mode', () {
    testWidgets('Renders "Lets Get Started" title and default selections (Mumbai, Purnimanta, English)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Settings(isOnboarding: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lets Get Started'), findsOneWidget);
      expect(
        find.text('Provide us the information below to get accurate panchang information.'),
        findsOneWidget,
      );
      expect(find.text('Lunar Calendar System'), findsOneWidget);
      expect(find.text('Purnimanta'), findsOneWidget);
      expect(find.text('Amanta'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('Mumbai'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.byType(ButtonGetStarted), findsOneWidget);
      expect(find.byType(ButtonUpdate), findsNothing);

      // ButtonGetStarted is active by default because Mumbai is default city
      final button = tester.widget<ButtonGetStarted>(find.byType(ButtonGetStarted));
      expect(button.isEnabled, isTrue);
    });

    testWidgets('Toggles between Purnimanta and Amanta lunar systems', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Settings(isOnboarding: true),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Amanta
      await tester.tap(find.text('Amanta'));
      await tester.pumpAndSettle();

      // Tap on Purnimanta
      await tester.tap(find.text('Purnimanta'));
      await tester.pumpAndSettle();
    });
  });

  group('Settings View - Settings Mode', () {
    testWidgets('Does not render "Lets Get Started" header in Settings mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Settings(isOnboarding: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lets Get Started'), findsNothing);
      expect(find.byType(ButtonUpdate), findsOneWidget);
      expect(find.byType(ButtonGetStarted), findsNothing);
    });

    testWidgets('ButtonUpdate is disabled initially when no settings are changed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Settings(
            isOnboarding: false,
            initialLunarSystem: 'purnimanta',
            initialLanguage: 'English',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final updateButton = tester.widget<ButtonUpdate>(find.byType(ButtonUpdate));
      expect(updateButton.isEnabled, isFalse);
    });

    testWidgets('Modifying Lunar System enables ButtonUpdate and toggling back disables it', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Settings(
            isOnboarding: false,
            initialLunarSystem: 'purnimanta',
            initialLanguage: 'English',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially disabled
      var updateButton = tester.widget<ButtonUpdate>(find.byType(ButtonUpdate));
      expect(updateButton.isEnabled, isFalse);

      // Tap Amanta to change lunar system
      await tester.tap(find.text('Amanta'));
      await tester.pumpAndSettle();

      // ButtonUpdate should now be enabled
      updateButton = tester.widget<ButtonUpdate>(find.byType(ButtonUpdate));
      expect(updateButton.isEnabled, isTrue);

      // Tap Purnimanta to revert back
      await tester.tap(find.text('Purnimanta'));
      await tester.pumpAndSettle();

      // ButtonUpdate should be disabled again since there are no changes
      updateButton = tester.widget<ButtonUpdate>(find.byType(ButtonUpdate));
      expect(updateButton.isEnabled, isFalse);
    });

    testWidgets('Tapping Language opens language picker without assertion error and allows selecting a language', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Settings(
            isOnboarding: false,
            initialLanguage: 'English',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the language row to open the bottom sheet
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // Check that bottom sheet is rendered
      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Hindi'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('Gujarati'), findsOneWidget);
      expect(find.text('ગુજરાતી'), findsOneWidget);

      // Select Hindi
      await tester.tap(find.text('Hindi'));
      await tester.pumpAndSettle();

      // Bottom sheet is closed and language is updated
      expect(find.text('Select Language'), findsNothing);
      expect(find.text('Hindi'), findsOneWidget);
      expect(find.text('भाषा'), findsOneWidget);
      expect(find.text('सेटिंग्स'), findsOneWidget);
    });

    testWidgets('Renders localized terms in Hindi when initialLanguage is Hindi', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Settings(
            isOnboarding: false,
            initialLanguage: 'Hindi',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('सेटिंग्स'), findsOneWidget);
      expect(find.text('चंद्र पंचांग प्रणाली'), findsOneWidget);
      expect(find.text('पूर्णिमांत'), findsOneWidget);
      expect(find.text('पूर्णिमा को समाप्त (उत्तर भारत)'), findsOneWidget);
      expect(find.text('अमांत'), findsOneWidget);
      expect(find.text('अमावस्या को समाप्त (गुजरात, दक्षिण भारत)'), findsOneWidget);
      expect(find.text('शहर'), findsOneWidget);
      expect(find.text('भाषा'), findsOneWidget);
    });

    testWidgets('Renders localized terms in Gujarati when initialLanguage is Gujarati', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Settings(
            isOnboarding: false,
            initialLanguage: 'Gujarati',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('સેટિંગ્સ'), findsOneWidget);
      expect(find.text('ચંદ્ર પંચાંગ પદ્ધતિ'), findsOneWidget);
      expect(find.text('પૂર્ણિમાંત'), findsOneWidget);
      expect(find.text('પૂર્ણિમાએ સમાપ્ત (ઉત્તર ભારત)'), findsOneWidget);
      expect(find.text('અમાંત'), findsOneWidget);
      expect(find.text('અમાસે સમાપ્ત (ગુજરાત, દક્ષિણ ભારત)'), findsOneWidget);
      expect(find.text('શહેર'), findsOneWidget);
      expect(find.text('ભાષા'), findsOneWidget);
    });
  });

  group('Today View Shell (WidgetPreviewView)', () {
    testWidgets('Renders Mobile layout with Today title, centered text, and NavBottom', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: TodayView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsNWidgets(2)); // AppBar title + NavBottom label
      expect(find.byType(NavBottom), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is ListItemPanchang || w is CardPanchangSkeleton), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CardTimings || w is CardTimingsSkeleton), findsOneWidget);
    });

    testWidgets('Renders Desktop layout with 2 columns, NavSide, and AppBar', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: TodayView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavSide), findsOneWidget);
      expect(find.text('Today'), findsOneWidget); // AppBar title
      expect(find.byWidgetPredicate((w) => w is ListItemPanchang || w is CardPanchangSkeleton), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is CardTimings || w is CardTimingsSkeleton), findsOneWidget);
    });
  });
}
