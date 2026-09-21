import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListItemTithi Tests', () {
    testWidgets('PastItem renders with dimmed opacity and outline border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.past(
                date: 'Sat, 23 Sep 2026',
                tithi: 'Dwadashi',
                paksha: 'Shukla',
                vrat: 'No Vrat',
                festival: 'No Festival',
                lunarDay: 13,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sat, 23 Sep 2026'), findsOneWidget);
      expect(find.text('Dwadashi'), findsOneWidget);
      expect(find.text('Shukla'), findsOneWidget);
      expect(find.text('No Vrat'), findsOneWidget);
      expect(find.text('No Festival'), findsOneWidget);

      // No ButtonAlarm in PastItem
      expect(find.byType(ButtonAlarm), findsNothing);

      // Verify Opacity widgets are used for dimming
      expect(find.byType(Opacity), findsWidgets);
    });

    testWidgets('CurrentItem renders with primary brand border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.current(
                date: 'Thu, 24 Sep 2026',
                tithi: 'Trayodashi',
                paksha: 'Shukla',
                lunarDay: 14,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thu, 24 Sep 2026'), findsOneWidget);
      expect(find.text('Trayodashi'), findsOneWidget);
      expect(find.text('Shukla'), findsOneWidget);

      // No ButtonAlarm in CurrentItem
      expect(find.byType(ButtonAlarm), findsNothing);

      // Find Container and check primary border
      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      final decoration = container.decoration as ShapeDecoration;
      final shape = decoration.shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.primary);
    });

    testWidgets('FutureItem renders ButtonAlarm and active tertiary festival', (tester) async {
      bool alarmToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.future(
                date: 'Fri, 25 Sep 2026',
                tithi: 'Chaturdashi',
                paksha: 'Shukla',
                vrat: 'No Vrat',
                festival: 'Anant Chaturdashi',
                lunarDay: 15,
                isAlarmActive: false,
                onAlarmTap: () {
                  alarmToggled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fri, 25 Sep 2026'), findsOneWidget);
      expect(find.text('Chaturdashi'), findsOneWidget);
      expect(find.text('Shukla'), findsOneWidget);
      expect(find.text('No Vrat'), findsOneWidget);
      expect(find.text('Anant Chaturdashi'), findsOneWidget);

      // Check active festival color is tertiary
      final festivalFinder = find.text('Anant Chaturdashi');
      final Text festivalText = tester.widget(festivalFinder);
      expect(festivalText.style?.color, AppColors.tertiary);

      // ButtonAlarm is present
      expect(find.byType(ButtonAlarm), findsOneWidget);

      // Tap ButtonAlarm
      await tester.tap(find.byType(ButtonAlarm));
      expect(alarmToggled, isTrue);
    });

    testWidgets('Renders properly in Hindi (date, tithi, paksha, inactive and active badges)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.current(
                date: 'Thu, 24 Sep 2026',
                tithi: 'Trayodashi',
                paksha: 'Shukla',
                vrat: 'Pradosh Vrat',
                festival: 'No Festival',
                language: AppLanguage.hindi,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Date in Hindi: गुरुवार, 24 सितंबर 2026
      expect(find.text('गुरुवार, 24 सितंबर 2026'), findsOneWidget);
      // Tithi in Hindi: त्रयोदशी
      expect(find.text('त्रयोदशी'), findsOneWidget);
      // Paksha in Hindi: शुक्ल
      expect(find.text('शुक्ल'), findsOneWidget);
      // Active Vrat in Hindi: प्रदोष व्रत
      expect(find.text('प्रदोष व्रत'), findsOneWidget);
      // Inactive Festival in Hindi: कोई त्योहार नहीं
      expect(find.text('कोई त्योहार नहीं'), findsOneWidget);
    });

    testWidgets('Renders properly in Gujarati (date, tithi, paksha, inactive and active badges)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.future(
                date: 'Fri, 25 Sep 2026',
                tithi: 'Chaturdashi',
                paksha: 'Shukla',
                vrat: 'No Vrat',
                festival: 'Anant Chaturdashi',
                language: AppLanguage.gujarati,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Date in Gujarati: શુક્રવાર, 25 સપ્ટેમ્બર 2026
      expect(find.text('શુક્રવાર, 25 સપ્ટેમ્બર 2026'), findsOneWidget);
      // Tithi in Gujarati: ચૌદસ
      expect(find.text('ચૌદસ'), findsOneWidget);
      // Paksha in Gujarati: શુક્લ
      expect(find.text('શુક્લ'), findsOneWidget);
      // Inactive Vrat in Gujarati: કોઈ વ્રત નથી
      expect(find.text('કોઈ વ્રત નથી'), findsOneWidget);
      // Active Festival in Gujarati: અનંત ચતુર્દશી
      expect(find.text('અનંત ચતુર્દશી'), findsOneWidget);
    });

    testWidgets('Formats date from explicit dateTime parameter when supplied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.current(
                date: '',
                dateTime: DateTime(2026, 9, 21),
                tithi: 'Ekadashi',
                paksha: 'Shukla',
                language: AppLanguage.gujarati,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Monday, 21 September 2026 in Gujarati: સોમવાર, 21 સપ્ટેમ્બર 2026
      expect(find.text('સોમવાર, 21 સપ્ટેમ્બર 2026'), findsOneWidget);
      // Ekadashi in Gujarati: અગિયારસ
      expect(find.text('અગિયારસ'), findsOneWidget);
    });
  });
}
