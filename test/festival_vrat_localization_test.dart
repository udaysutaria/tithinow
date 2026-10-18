import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tithinow/constants/panchang_terms.dart';
import 'package:tithinow/models/festival_rule.dart';
import 'package:tithinow/widgets/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PanchangLabels Vrat and Festival Localization Tests', () {
    test('Resolves static known festivals in English, Hindi, and Gujarati', () {
      expect(
        PanchangLabels.resolveFestival('Maha Shivaratri', AppLanguage.gujarati),
        'મહાશિવરાત્રી',
      );
      expect(
        PanchangLabels.resolveFestival('Maha Shivaratri', AppLanguage.hindi),
        'महाशिवरात्रि',
      );
      expect(
        PanchangLabels.resolveFestival('Maha Shivaratri', AppLanguage.english),
        'Maha Shivaratri',
      );

      expect(
        PanchangLabels.resolveFestival('Krishna Janmashtami', AppLanguage.gujarati),
        'શ્રીકૃષ્ણ જન્માષ્ટમી',
      );
      expect(
        PanchangLabels.resolveFestival('Krishna Janmashtami', AppLanguage.hindi),
        'श्रीकृष्ण जन्माष्टमी',
      );

      expect(
        PanchangLabels.resolveFestival('Diwali', AppLanguage.gujarati),
        'દિવાળી',
      );
      expect(
        PanchangLabels.resolveFestival('Diwali', AppLanguage.hindi),
        'दीपावली',
      );

      expect(
        PanchangLabels.resolveFestival('Makar Sankranti', AppLanguage.gujarati),
        'મકર સંક્રાંતિ',
      );
    });

    test('Resolves static known Ekadashi vrats in English, Hindi, and Gujarati', () {
      expect(
        PanchangLabels.resolveVrat('Nirjala Ekadashi', AppLanguage.gujarati),
        'નિર્જલા એકાદશી',
      );
      expect(
        PanchangLabels.resolveVrat('Nirjala Ekadashi', AppLanguage.hindi),
        'निर्जला एकादशी',
      );
      expect(
        PanchangLabels.resolveVrat('Parama Ekadashi', AppLanguage.gujarati),
        'પરમા એકાદશી',
      );
      expect(
        PanchangLabels.resolveVrat('Parivartini Ekadashi', AppLanguage.gujarati),
        'પરિવર્તિની અગિયારસ',
      );
    });

    test('Resolves inactive states correctly across languages', () {
      expect(
        PanchangLabels.resolveVrat('No Vrat', AppLanguage.gujarati),
        'કોઈ વ્રત નથી',
      );
      expect(
        PanchangLabels.resolveVrat('No Vrat', AppLanguage.hindi),
        'कोई व्रत नहीं',
      );
      expect(
        PanchangLabels.resolveVrat('No Vrat', AppLanguage.english),
        'No Vrat',
      );

      expect(
        PanchangLabels.resolveFestival('No Festival', AppLanguage.gujarati),
        'કોઈ તહેવાર નથી',
      );
      expect(
        PanchangLabels.resolveFestival('No Festival', AppLanguage.hindi),
        'कोई त्योहार नहीं',
      );
      expect(
        PanchangLabels.resolveFestival('No Festival', AppLanguage.english),
        'No Festival',
      );
    });

    test('Registers dynamic ACF rules into PanchangLabels dynamically', () {
      const customRule = FestivalRule(
        id: 9999,
        festivalId: 'custom-utsav',
        nameEn: 'Custom Utsav',
        nameHi: 'कस्टम उत्सव',
        nameGu: 'કસ્ટમ ઉત્સવ',
        category: 'festival',
      );

      FestivalRule.registerRules([customRule]);

      expect(
        PanchangLabels.resolveFestival('Custom Utsav', AppLanguage.gujarati),
        'કસ્ટમ ઉત્સવ',
      );
      expect(
        PanchangLabels.resolveFestival('Custom Utsav', AppLanguage.hindi),
        'कस्टम उत्सव',
      );
      expect(
        PanchangLabels.resolveFestival('Custom Utsav', AppLanguage.english),
        'Custom Utsav',
      );
    });
  });

  group('FestivalRule Model Tests', () {
    test('Parses WordPress ACF json fields properly', () {
      final json = {
        'id': 101,
        'slug': 'parama-ekadashi',
        'acf': {
          'festival_name_en': 'Parama Ekadashi',
          'festival_name_hi': 'परमा एकादशी',
          'festival_name_gu': 'પરમા એકાદશી',
          'festival_category': 'vrat',
          'tithi': 11,
          'paksha': 'krishna',
          'amanta_month': 'adhika',
        },
      };

      final rule = FestivalRule.fromWordPressJson(json);
      expect(rule.nameEn, 'Parama Ekadashi');
      expect(rule.nameHi, 'परमा एकादशी');
      expect(rule.nameGu, 'પરમા એકાદશી');
      expect(rule.name(AppLanguage.gujarati), 'પરમા એકાદશી');
      expect(rule.name(AppLanguage.hindi), 'परमा एकादशी');
      expect(rule.name(AppLanguage.english), 'Parama Ekadashi');
    });
  });

  group('TithiData Model Tests', () {
    test('resolveVrat and resolveFestival leverage rule and language', () {
      const vratRule = FestivalRule(
        id: 201,
        festivalId: 'kamada-ekadashi',
        nameEn: 'Kamada Ekadashi',
        nameHi: 'कामदा एकादशी',
        nameGu: 'કામદા એકાદશી',
        category: 'vrat',
      );

      const festivalRule = FestivalRule(
        id: 202,
        festivalId: 'ram-navami',
        nameEn: 'Rama Navami',
        nameHi: 'राम नवमी',
        nameGu: 'રામ નવમી',
        category: 'festival',
      );

      final data = TithiData(
        tithi: 'Navami',
        paksha: 'Shukla',
        date: 'Sun, 29 Mar 2026',
        vrat: 'Kamada Ekadashi',
        festival: 'Rama Navami',
        vratRule: vratRule,
        festivalRule: festivalRule,
      );

      expect(data.resolveVrat(AppLanguage.gujarati), 'કામદા એકાદશી');
      expect(data.resolveVrat(AppLanguage.hindi), 'कामदा एकादशी');
      expect(data.resolveVrat(AppLanguage.english), 'Kamada Ekadashi');

      expect(data.resolveFestival(AppLanguage.gujarati), 'રામ નવમી');
      expect(data.resolveFestival(AppLanguage.hindi), 'राम नवमी');
      expect(data.resolveFestival(AppLanguage.english), 'Rama Navami');

      // Test copyWith preserves rules
      final copied = data.copyWith(isAlarmActive: true);
      expect(copied.vratRule, equals(vratRule));
      expect(copied.festivalRule, equals(festivalRule));
      expect(copied.resolveVrat(AppLanguage.gujarati), 'કામદા એકાદશી');
    });

    test('Multiple festivals and vrats on same day resolve comma-separated and preserve both in copyWith', () {
      const kaliChaudas = FestivalRule(
        id: 4016,
        festivalId: 'kali_chaudas',
        nameEn: 'Kali Chaudas',
        nameHi: 'काली चौदस',
        nameGu: 'કાળી ચૌદશ',
        category: 'festival',
      );

      const diwali = FestivalRule(
        id: 4017,
        festivalId: 'diwali',
        nameEn: 'Diwali',
        nameHi: 'दीपावली',
        nameGu: 'દિવાળી',
        category: 'festival',
      );

      final data = TithiData(
        tithi: 'Chaturdashi',
        paksha: 'Krishna',
        date: 'Sun, 08 Nov 2026',
        festivals: const [kaliChaudas, diwali],
      );

      expect(data.effectiveFestivals.length, 2);
      expect(data.effectiveFestivalRule, equals(kaliChaudas));
      expect(data.resolveFestival(AppLanguage.english), 'Kali Chaudas, Diwali');
      expect(data.resolveFestival(AppLanguage.gujarati), 'કાળી ચૌદશ, દિવાળી');
      expect(data.resolveFestival(AppLanguage.hindi), 'काली चौदस, दीपावली');

      final copied = data.copyWith(isAlarmActive: true);
      expect(copied.effectiveFestivals.length, 2);
      expect(copied.festivals, equals([kaliChaudas, diwali]));
      expect(copied.resolveFestival(AppLanguage.english), 'Kali Chaudas, Diwali');
    });
  });

  group('ListItemTithi UI Localization Tests', () {
    testWidgets('Renders Gujarati vrat and festival when vratRule and festivalRule are provided', (tester) async {
      const vratRule = FestivalRule(
        id: 301,
        festivalId: 'parivartini-ekadashi',
        nameEn: 'Parivartini Ekadashi',
        nameHi: 'परिवर्तिनी एकादशी',
        nameGu: 'પરિવર્તિની અગિયારસ',
        category: 'vrat',
      );

      const festivalRule = FestivalRule(
        id: 302,
        festivalId: 'anant-chaturdashi',
        nameEn: 'Anant Chaturdashi',
        nameHi: 'अनंत चतुर्दशी',
        nameGu: 'અનંત ચતુર્દશી',
        category: 'festival',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.future(
                date: 'Fri, 25 Sep 2026',
                tithi: 'Chaturdashi',
                paksha: 'Shukla',
                vrat: 'Parivartini Ekadashi',
                festival: 'Anant Chaturdashi',
                vratRule: vratRule,
                festivalRule: festivalRule,
                language: AppLanguage.gujarati,
                lunarDay: 14,
                showVratFestival: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('પરિવર્તિની અગિયારસ'), findsOneWidget);
      expect(find.text('અનંત ચતુર્દશી'), findsOneWidget);
    });

    testWidgets('Renders Hindi vrat and festival when language is Hindi', (tester) async {
      const vratRule = FestivalRule(
        id: 303,
        festivalId: 'parivartini-ekadashi',
        nameEn: 'Parivartini Ekadashi',
        nameHi: 'परिवर्तिनी एकादशी',
        nameGu: 'પરિવર્તિની અગિયારસ',
        category: 'vrat',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.future(
                date: 'Fri, 25 Sep 2026',
                tithi: 'Chaturdashi',
                paksha: 'Shukla',
                vrat: 'Parivartini Ekadashi',
                festival: 'No Festival',
                vratRule: vratRule,
                language: AppLanguage.hindi,
                lunarDay: 14,
                showVratFestival: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('परिवर्तिनी एकादशी'), findsOneWidget);
      expect(find.text('कोई त्योहार नहीं'), findsOneWidget);
    });

    testWidgets('Renders Gujarati localized inactive texts for No Vrat and No Festival', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ListItemTithi.past(
                date: 'Wed, 23 Sep 2026',
                tithi: 'Dwadashi',
                paksha: 'Shukla',
                vrat: 'No Vrat',
                festival: 'No Festival',
                language: AppLanguage.gujarati,
                lunarDay: 12,
                showVratFestival: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('કોઈ વ્રત નથી'), findsOneWidget);
      expect(find.text('કોઈ તહેવાર નથી'), findsOneWidget);
    });
  });

  group('CardPanchang UI Localization Tests', () {
    testWidgets('Renders Gujarati vrat and festival in CardPanchang', (tester) async {
      const vratRule = FestivalRule(
        id: 401,
        festivalId: 'maha-shivaratri',
        nameEn: 'Maha Shivaratri',
        nameHi: 'महाशिवरात्रि',
        nameGu: 'મહાશિવરાત્રી',
        category: 'festival',
      );

      const data = PanchangData(
        month: 'Phalguna',
        vrat: 'Maha Shivaratri',
        festival: 'No Festival',
        vratRule: vratRule,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardPanchang(
                data: data,
                language: AppLanguage.gujarati,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('મહાશિવરાત્રી'), findsOneWidget);
      expect(find.text('ટૂંક સમયમાં'), findsOneWidget);
    });

    testWidgets('Renders Hindi vrat and festival in CardPanchang', (tester) async {
      const festivalRule = FestivalRule(
        id: 402,
        festivalId: 'krishna-janmashtami',
        nameEn: 'Krishna Janmashtami',
        nameHi: 'श्रीकृष्ण जन्माष्टमी',
        nameGu: 'શ્રીકૃષ્ણ જન્માષ્ટમી',
        category: 'festival',
      );

      const data = PanchangData(
        month: 'Bhadrapada',
        vrat: 'No Vrat',
        festival: 'Krishna Janmashtami',
        festivalRule: festivalRule,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CardPanchang(
                data: data,
                language: AppLanguage.hindi,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('जल्द आ रहा है'), findsOneWidget);
      expect(find.text('श्रीकृष्ण जन्माष्टमी'), findsOneWidget);
    });
  });
}
