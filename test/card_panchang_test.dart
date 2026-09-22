import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CardPanchang Tests', () {
    testWidgets('Renders Mobile Slider with 2x2 grid and English defaults', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: CardPanchang(
                  mode: PanchangLayoutMode.mobileSlider,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1 should display its English items
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

    testWidgets('Renders Hindi terms and values when language is set to Hindi', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardPanchang(
              mode: PanchangLayoutMode.desktopGrid4x2,
              language: AppLanguage.hindi,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1 labels in Hindi
      expect(find.text('नक्षत्र'), findsOneWidget);
      expect(find.text('धनिष्ठा'), findsOneWidget);
      expect(find.text('मास'), findsOneWidget);
      expect(find.text('भाद्रपद'), findsOneWidget);
      expect(find.text('व्रत'), findsOneWidget);
      expect(find.text('कोई व्रत नहीं'), findsOneWidget);
      expect(find.text('त्योहार'), findsOneWidget);
      expect(find.text('कोई त्योहार नहीं'), findsOneWidget);

      // Slide 2 labels in Hindi
      expect(find.text('सूर्योदय'), findsOneWidget);
      expect(find.text('सूर्यास्त'), findsOneWidget);
      expect(find.text('चन्द्रोदय'), findsOneWidget);
      expect(find.text('चन्द्रास्त'), findsOneWidget);
      expect(find.text('06:27 AM'), findsOneWidget);
      expect(find.text('06:33 PM'), findsOneWidget);
      expect(find.text('05:08 PM'), findsOneWidget);
      expect(find.text('04:56 AM'), findsOneWidget);
    });

    testWidgets('Renders Gujarati terms and values when language is set to Gujarati', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardPanchang(
              mode: PanchangLayoutMode.desktopGrid4x2,
              language: AppLanguage.gujarati,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1 labels in Gujarati
      expect(find.text('નક્ષત્ર'), findsOneWidget);
      expect(find.text('ધનિષ્ઠા'), findsOneWidget);
      expect(find.text('માસ'), findsOneWidget);
      expect(find.text('ભાદરવો'), findsOneWidget);
      expect(find.text('વ્રત'), findsOneWidget);
      expect(find.text('કોઈ વ્રત નથી'), findsOneWidget);
      expect(find.text('તહેવાર'), findsOneWidget);
      expect(find.text('કોઈ તહેવાર નથી'), findsOneWidget);

      // Slide 2 labels in Gujarati
      expect(find.text('સૂર્યોદય'), findsOneWidget);
      expect(find.text('સૂર્યાસ્ત'), findsOneWidget);
      expect(find.text('ચંદ્રોદય'), findsOneWidget);
      expect(find.text('ચંદ્રાસ્ત'), findsOneWidget);
    });

    testWidgets('Localizes active Vrat and Festival in Hindi and Gujarati', (tester) async {
      // Hindi test
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardPanchang(
              mode: PanchangLayoutMode.desktopGrid4x2,
              language: AppLanguage.hindi,
              vrat: 'Parivartini Ekadashi',
              festival: 'Diwali',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('परिवर्तिनी एकादशी'), findsOneWidget);
      expect(find.text('दीपावली'), findsOneWidget);

      // Active text should have onSurfaceVariant color (White)
      final Text diwaliText = tester.widget(find.text('दीपावली'));
      expect(diwaliText.style?.color, AppColors.onSurfaceVariant);

      // Gujarati test
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardPanchang(
              mode: PanchangLayoutMode.desktopGrid4x2,
              language: AppLanguage.gujarati,
              vrat: 'Parivartini Ekadashi',
              festival: 'Diwali',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('પરિવર્તિની અગિયારસ'), findsOneWidget);
      expect(find.text('દિવાળી'), findsOneWidget);
    });

    testWidgets('Conditional Formatting: inactive items use onSurface color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardPanchang(
              mode: PanchangLayoutMode.desktopGrid4x2,
              language: AppLanguage.hindi,
              vrat: 'No Vrat',
              festival: 'Diwali',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Inactive "कोई व्रत नहीं" has onSurface color (#BAC9CB)
      final Text noVratText = tester.widget(find.text('कोई व्रत नहीं'));
      expect(noVratText.style?.color, AppColors.onSurface);

      // Active "दीपावली" has onSurfaceVariant color (White)
      final Text diwaliText = tester.widget(find.text('दीपावली'));
      expect(diwaliText.style?.color, AppColors.onSurfaceVariant);
    });

    testWidgets('Reacts dynamically when AppDatabase.languageNotifier changes', (tester) async {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardPanchang(
              mode: PanchangLayoutMode.desktopGrid4x2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial English state
      expect(find.text('Nakshatras'), findsOneWidget);
      expect(find.text('Dhanishtha'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Bhadrapada'), findsOneWidget);
      expect(find.text('Sunrise'), findsOneWidget);

      // Switch to Hindi
      AppDatabase.instance.languageNotifier.value = AppLanguage.hindi;
      await tester.pumpAndSettle();

      expect(find.text('नक्षत्र'), findsOneWidget);
      expect(find.text('धनिष्ठा'), findsOneWidget);
      expect(find.text('मास'), findsOneWidget);
      expect(find.text('भाद्रपद'), findsOneWidget);
      expect(find.text('सूर्योदय'), findsOneWidget);

      // Switch to Gujarati
      AppDatabase.instance.languageNotifier.value = AppLanguage.gujarati;
      await tester.pumpAndSettle();

      expect(find.text('નક્ષત્ર'), findsOneWidget);
      expect(find.text('ધનિષ્ઠા'), findsOneWidget);
      expect(find.text('માસ'), findsOneWidget);
      expect(find.text('ભાદરવો'), findsOneWidget);
      expect(find.text('સૂર્યોદય'), findsOneWidget);

      // Reset to English
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
      await tester.pumpAndSettle();

      expect(find.text('Nakshatras'), findsOneWidget);
      expect(find.text('Dhanishtha'), findsOneWidget);
    });

    testWidgets('CardPanchang.values constructor supports individual parameter overrides and localization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardPanchang.values(
              mode: PanchangLayoutMode.desktopGrid4x2,
              language: AppLanguage.hindi,
              nakshatra: 'Revati',
              month: 'Chaitra',
              vrat: 'Pradosh Vrat',
              festival: 'Ganesh Visarjan',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('रेवती'), findsOneWidget);
      expect(find.text('चैत्र'), findsOneWidget);
      expect(find.text('प्रदोष व्रत'), findsOneWidget);
      expect(find.text('गणेश विसर्जन'), findsOneWidget);
    });

    testWidgets('Swiping to Slide 3 renders Yoga, Karana, Rashi and Sun Sign', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 380,
                child: CardPanchang(
                  mode: PanchangLayoutMode.mobileSlider,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe to Slide 2
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Swipe to Slide 3
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      // Verify Slide 3 items
      expect(find.text('Yoga'), findsOneWidget);
      expect(find.text('Vishkambha'), findsOneWidget);
      expect(find.text('Karana'), findsOneWidget);
      expect(find.text('Bava'), findsOneWidget);
      expect(find.text('Rashi'), findsOneWidget);
      expect(find.text('Sun Sign'), findsOneWidget);
    });

    testWidgets('Renders Slide 3 items in Hindi and Gujarati', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CardPanchang(
              mode: PanchangLayoutMode.desktopGrid4x2,
              language: AppLanguage.hindi,
              yogaEnum: Yoga.ayushman,
              karanaEnum: Karana.vishti,
              rashiEnum: Rashi.makara,
              suryaRashiEnum: Rashi.kanya,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('योग'), findsOneWidget);
      expect(find.text('आयुष्मान्'), findsOneWidget);
      expect(find.text('करण'), findsOneWidget);
      expect(find.text('विष्टि (भद्रा)'), findsOneWidget);
      expect(find.text('राशि'), findsOneWidget);
      expect(find.text('मकर'), findsOneWidget);
      expect(find.text('सूर्य राशि'), findsOneWidget);
      expect(find.text('कन्या'), findsOneWidget);
    });
  });
}
