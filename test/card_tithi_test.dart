import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/theme/design_system.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child, {Size size = const Size(390, 844)}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }

  group('CardTithi.today Tests', () {
    testWidgets('renders 96px moon image and no alarm button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          CardTithi.today(
            date: 'Thu, 24 Sep 2026',
            tithi: 'Trayodashi',
            paksha: 'Shukla Paksha',
            lunarDay: 13,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thu, 24 Sep 2026'), findsOneWidget);
      expect(find.text('Trayodashi'), findsOneWidget);
      expect(find.text('Shukla Paksha'), findsOneWidget);

      // Verify moon image size is 96x96
      final moonImageFinder = find.byType(Image);
      expect(moonImageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(moonImageFinder);
      expect(imageWidget.width, equals(96.0));
      expect(imageWidget.height, equals(96.0));

      // Verify no ButtonAlarm is rendered
      expect(find.byType(ButtonAlarm), findsNothing);
    });
  });

  group('CardTithi.detail Tests', () {
    testWidgets('renders 72px moon image and interactive ButtonAlarm', (tester) async {
      bool alarmTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          CardTithi.detail(
            date: 'Thu, 24 Sep 2026',
            tithi: 'Trayodashi',
            paksha: 'Shukla Paksha',
            lunarDay: 13,
            isAlarmActive: false,
            onAlarmTap: () {
              alarmTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thu, 24 Sep 2026'), findsOneWidget);
      expect(find.text('Trayodashi'), findsOneWidget);
      expect(find.text('Shukla Paksha'), findsOneWidget);

      // Verify moon image size is 72x72
      final moonImageFinder = find.byType(Image);
      expect(moonImageFinder, findsOneWidget);
      final imageWidget = tester.widget<Image>(moonImageFinder);
      expect(imageWidget.width, equals(72.0));
      expect(imageWidget.height, equals(72.0));

      // Verify ButtonAlarm is rendered and can be tapped
      expect(find.byType(ButtonAlarm), findsOneWidget);
      await tester.tap(find.byType(ButtonAlarm));
      await tester.pumpAndSettle();

      expect(alarmTapped, isTrue);
    });
  });

  group('Cardtithidetail Compatibility Alias Tests', () {
    testWidgets('works with Cardtithidetail typedef name', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Cardtithidetail(
            date: 'Fri, 25 Sep 2026',
            tithi: 'Purnima',
            paksha: 'Shukla Paksha',
            showAlarmButton: true,
            moonSize: 72.0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Purnima'), findsOneWidget);
      expect(find.byType(ButtonAlarm), findsOneWidget);
    });
  });

  group('CardTithi Language Switching Tests', () {
    testWidgets('renders Hindi date, tithi, and paksha when language is Hindi', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CardTithi(
            date: 'Thu, 24 Sep 2026',
            tithi: 'Trayodashi',
            paksha: 'Shukla Paksha',
            language: AppLanguage.hindi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('गुरुवार, 24 सितंबर 2026'), findsOneWidget);
      expect(find.text('त्रयोदशी'), findsOneWidget);
      expect(find.text('शुक्ल पक्ष'), findsOneWidget);
    });

    testWidgets('renders Gujarati date, tithi, and paksha when language is Gujarati', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CardTithi(
            date: 'Thu, 24 Sep 2026',
            tithi: 'Trayodashi',
            paksha: 'Shukla Paksha',
            language: AppLanguage.gujarati,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ગુરુવાર, 24 સપ્ટેમ્બર 2026'), findsOneWidget);
      expect(find.text('તેરસ'), findsOneWidget);
      expect(find.text('શુક્લ પક્ષ'), findsOneWidget);
    });

    testWidgets('CardTithi.today works with language parameter', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CardTithi.today(
            date: 'Thu, 24 Sep 2026',
            tithi: 'Trayodashi',
            paksha: 'Shukla Paksha',
            language: AppLanguage.hindi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('गुरुवार, 24 सितंबर 2026'), findsOneWidget);
      expect(find.text('त्रयोदशी'), findsOneWidget);
      expect(find.text('शुक्ल पक्ष'), findsOneWidget);
    });

    testWidgets('CardTithi.detail works with language parameter', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const CardTithi.detail(
            date: 'Thu, 24 Sep 2026',
            tithi: 'Trayodashi',
            paksha: 'Shukla Paksha',
            language: AppLanguage.gujarati,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ગુરુવાર, 24 સપ્ટેમ્બર 2026'), findsOneWidget);
      expect(find.text('તેરસ'), findsOneWidget);
      expect(find.text('શુક્લ પક્ષ'), findsOneWidget);
      expect(find.byType(ButtonAlarm), findsOneWidget);
    });

    testWidgets('supports dateTime, tithiEnum, and pakshaEnum overrides', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          CardTithi(
            dateTime: DateTime(2026, 9, 24),
            tithiEnum: Tithi.trayodashi,
            pakshaEnum: Paksha.shukla,
            language: AppLanguage.hindi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('गुरुवार, 24 सितंबर 2026'), findsOneWidget);
      expect(find.text('त्रयोदशी'), findsOneWidget);
      expect(find.text('शुक्ल पक्ष'), findsOneWidget);
    });

    testWidgets('reacts dynamically to AppDatabase.languageNotifier changes', (tester) async {
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;

      await tester.pumpWidget(
        buildTestableWidget(
          const CardTithi(
            date: 'Thu, 24 Sep 2026',
            tithi: 'Trayodashi',
            paksha: 'Shukla Paksha',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial English
      expect(find.text('Thu, 24 Sep 2026'), findsOneWidget);
      expect(find.text('Trayodashi'), findsOneWidget);
      expect(find.text('Shukla Paksha'), findsOneWidget);

      // Change to Hindi
      AppDatabase.instance.languageNotifier.value = AppLanguage.hindi;
      await tester.pumpAndSettle();

      expect(find.text('गुरुवार, 24 सितंबर 2026'), findsOneWidget);
      expect(find.text('त्रयोदशी'), findsOneWidget);
      expect(find.text('शुक्ल पक्ष'), findsOneWidget);

      // Change to Gujarati
      AppDatabase.instance.languageNotifier.value = AppLanguage.gujarati;
      await tester.pumpAndSettle();

      expect(find.text('ગુરુવાર, 24 સપ્ટેમ્બર 2026'), findsOneWidget);
      expect(find.text('તેરસ'), findsOneWidget);
      expect(find.text('શુક્લ પક્ષ'), findsOneWidget);

      // Reset to English
      AppDatabase.instance.languageNotifier.value = AppLanguage.english;
      await tester.pumpAndSettle();

      expect(find.text('Thu, 24 Sep 2026'), findsOneWidget);
      expect(find.text('Trayodashi'), findsOneWidget);
      expect(find.text('Shukla Paksha'), findsOneWidget);
    });
  });
}
