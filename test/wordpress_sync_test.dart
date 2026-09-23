import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tithinow/constants/panchang_terms.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/models/city.dart';
import 'package:tithinow/models/festival_rule.dart';
import 'package:tithinow/services/sweph_service.dart';
import 'package:tithinow/services/wordpress_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String sampleJson = '''
[
  {
    "id": 33,
    "slug": "maha-shivaratri",
    "modified": "2026-09-21T16:46:14",
    "acf": {
      "festival_id": "maha_shivaratri",
      "category": "festival",
      "importance_level": "major",
      "is_fasting": true,
      "festival_name_en": "Maha Shivaratri",
      "festival_name_hi": "महाशिवरात्रि",
      "festival_name_gu": "મહાશિવરાત્રી",
      "description_en": "Great night of Shiva",
      "description_hi": "भगवान शिव की महान रात्रि",
      "description_gu": "ભગવાન શિવની મહાન રાત્રિ",
      "event_type": "lunar_tithi",
      "day_selection_rule": "nishita",
      "lunar_month": "magha",
      "paksha": "krishna",
      "tithi_number": 14,
      "solar_month": "makara",
      "nakshatra_constraint": "none",
      "region_variant": "national",
      "rule_version": 1
    }
  },
  {
    "id": 36,
    "slug": "makar-sankranti",
    "modified": "2026-09-21T16:51:30",
    "acf": {
      "festival_id": "makar_sankranti",
      "category": "festival",
      "importance_level": "major",
      "is_fasting": false,
      "festival_name_en": "Makar Sankranti",
      "festival_name_hi": "मकर संक्रांति",
      "festival_name_gu": "મકર સંક્રાંતિ",
      "description_en": "Sun transits into Makara",
      "description_hi": "सूर्य मकर राशि में प्रवेश",
      "description_gu": "સૂર્ય મકર રાશિમાં પ્રવેશ",
      "event_type": "solar_sankranti",
      "day_selection_rule": "punyakaal",
      "lunar_month": "chaitra",
      "paksha": "shukla",
      "tithi_number": 1,
      "solar_month": "makara",
      "nakshatra_constraint": "none",
      "region_variant": "national",
      "rule_version": 1
    }
  },
  {
    "id": 37,
    "slug": "krishna-janmashtami",
    "modified": "2026-09-21T16:53:08",
    "acf": {
      "festival_id": "krishna_janmashtami",
      "category": "festival",
      "importance_level": "major",
      "is_fasting": true,
      "festival_name_en": "Krishna Janmashtami",
      "festival_name_hi": "श्रीकृष्ण जन्माष्टमी",
      "festival_name_gu": "શ્રીકૃષ્ણ જન્માષ્ટમી",
      "description_en": "Appearance of Sri Krishna",
      "description_hi": "श्रीकृष्ण जन्मोत्सव",
      "description_gu": "શ્રીકૃષ્ણ જન્મોત્સવ",
      "event_type": "lunar_tithi",
      "day_selection_rule": "nishita",
      "lunar_month": "bhadrapada",
      "paksha": "krishna",
      "tithi_number": 8,
      "solar_month": "makara",
      "nakshatra_constraint": "rohini",
      "region_variant": "national",
      "rule_version": 1
    }
  }
]
''';

  group('FestivalRule Model Tests', () {
    test('Parses from WordPress JSON successfully', () {
      final list = jsonDecode(sampleJson) as List<dynamic>;
      final rule = FestivalRule.fromWordPressJson(list[0] as Map<String, dynamic>);

      expect(rule.id, 33);
      expect(rule.festivalId, 'maha_shivaratri');
      expect(rule.category, 'festival');
      expect(rule.importanceLevel, 'major');
      expect(rule.isFasting, true);
      expect(rule.isMajor, true);
      expect(rule.isVrat, true);
      expect(rule.nameEn, 'Maha Shivaratri');
      expect(rule.nameHi, 'महाशिवरात्रि');
      expect(rule.nameGu, 'મહાશિવરાત્રી');
      expect(rule.daySelectionRule, 'nishita');
      expect(rule.lunarMonth, 'magha');
      expect(rule.paksha, 'krishna');
      expect(rule.tithiNumber, 14);
      expect(rule.nakshatraConstraint, isNull); // 'none' is mapped to null
      expect(rule.ruleVersion, 1);
    });

    test('Translates names and descriptions across AppLanguage', () {
      final list = jsonDecode(sampleJson) as List<dynamic>;
      final rule = FestivalRule.fromWordPressJson(list[0] as Map<String, dynamic>);

      expect(rule.name(AppLanguage.english), 'Maha Shivaratri');
      expect(rule.name(AppLanguage.hindi), 'महाशिवरात्रि');
      expect(rule.name(AppLanguage.gujarati), 'મહાશિવરાત્રી');

      expect(rule.description(AppLanguage.english), 'Great night of Shiva');
      expect(rule.description(AppLanguage.hindi), 'भगवान शिव की महान रात्रि');
      expect(rule.description(AppLanguage.gujarati), 'ભગવાન શિવની મહાન રાત્રિ');
    });

    test('toMap and fromMap roundtrip preserves all values', () {
      final list = jsonDecode(sampleJson) as List<dynamic>;
      final original = FestivalRule.fromWordPressJson(list[2] as Map<String, dynamic>);

      final map = original.toMap();
      final reconstructed = FestivalRule.fromMap(map);

      expect(reconstructed.id, original.id);
      expect(reconstructed.festivalId, original.festivalId);
      expect(reconstructed.isFasting, original.isFasting);
      expect(reconstructed.nakshatraConstraint, 'rohini');
      expect(reconstructed.daySelectionRule, 'nishita');
      expect(reconstructed.lunarMonth, 'bhadrapada');
      expect(reconstructed.tithiNumber, 8);
    });
  });

  group('AppDatabase Festivals SQLite Tests', () {
    late AppDatabase db;

    setUp(() async {
      AppDatabase.initializeFfiIfNeeded();
      await AppDatabase.initCustomDatabase(inMemory: true);
      db = AppDatabase.instance;
    });

    tearDown(() async {
      await db.close();
    });

    test('Upserts and queries festival rules in SQLite', () async {
      final list = jsonDecode(sampleJson) as List<dynamic>;
      final rules = list
          .whereType<Map<String, dynamic>>()
          .map(FestivalRule.fromWordPressJson)
          .toList();

      final count = await db.upsertFestivals(rules);
      expect(count, 3);

      final totalCount = await db.getFestivalsCount();
      expect(totalCount, 3);

      // Query by ID
      final shivaratri = await db.getFestivalRuleById('maha_shivaratri');
      expect(shivaratri, isNotNull);
      expect(shivaratri!.nameEn, 'Maha Shivaratri');
      expect(shivaratri.daySelectionRule, 'nishita');

      // Query for lunar tithi match
      final tithiMatches = await db.getFestivalRulesForTithi(
        lunarMonth: 'magha',
        paksha: 'krishna',
        tithiNumber: 14,
      );
      expect(tithiMatches.length, 1);
      expect(tithiMatches.first.festivalId, 'maha_shivaratri');

      // Query for sankranti match
      final sankrantiMatches = await db.getFestivalRulesForSankranti(
        solarMonth: 'makara',
      );
      expect(sankrantiMatches.length, 1);
      expect(sankrantiMatches.first.festivalId, 'makar_sankranti');

      // Query non-existent rule
      final emptyMatches = await db.getFestivalRulesForTithi(
        lunarMonth: 'chaitra',
        paksha: 'shukla',
        tithiNumber: 5,
      );
      expect(emptyMatches, isEmpty);
    });

    test('importFestivalsFromSeed populates SQLite from JSON string', () async {
      final count = await db.importFestivalsFromSeed(jsonContent: sampleJson);
      expect(count, 3);

      final all = await db.getAllFestivalRules();
      expect(all.length, 3);
      expect(all.map((r) => r.festivalId), containsAll(['maha_shivaratri', 'makar_sankranti', 'krishna_janmashtami']));
    });
  });

  group('WordPressSyncService Tests', () {
    late AppDatabase db;

    setUp(() async {
      AppDatabase.initializeFfiIfNeeded();
      await AppDatabase.initCustomDatabase(inMemory: true);
      db = AppDatabase.instance;
    });

    tearDown(() async {
      await db.close();
    });

    test('Syncs festivals successfully from mock HTTP client', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('festivals')) {
          return http.Response(
            sampleJson,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = WordPressSyncService.instance;
      final result = await service.syncFestivals(
        endpointUrl: 'http://localhost:8888/wp-json/wp/v2/festivals',
        client: mockClient,
      );

      expect(result.isSuccess, true);
      expect(result.count, 3);
      expect(result.fromCache, false);

      final countInDb = await db.getFestivalsCount();
      expect(countInDb, 3);
    });

    test('Falls back to cached SQLite data gracefully on network failure', () async {
      // Pre-seed SQLite cache
      await db.importFestivalsFromSeed(jsonContent: sampleJson);
      expect(await db.getFestivalsCount(), 3);

      // Client that simulates network offline
      final offlineClient = MockClient((request) async {
        throw const SocketException('No route to host');
      });

      final service = WordPressSyncService.instance;
      final result = await service.syncFestivals(
        endpointUrl: 'http://localhost:8888/wp-json/wp/v2/festivals',
        client: offlineClient,
      );

      expect(result.isSuccess, true);
      expect(result.count, 3);
      expect(result.fromCache, true);
      expect(result.errorMessage, contains('SocketException'));
    });

    test('Anant Chaturdashi calculates correctly on 25 September 2026', () async {
      await SwephService.instance.init();
      const anantRule = FestivalRule(
        id: 38,
        festivalId: 'anant_chaturdashi',
        category: 'festival',
        importanceLevel: 'major',
        isFasting: true,
        nameEn: 'Anant Chaturdashi',
        nameHi: 'अनंत चतुर्दशी',
        nameGu: 'અનંત ચતુર્દશી',
        eventType: 'lunar_tithi',
        daySelectionRule: 'udaya',
        lunarMonth: 'bhadrapada',
        paksha: 'shukla',
        tithiNumber: 14,
      );

      final sep25 = SwephService.instance.calculateCalendarDay(
        date: DateTime(2026, 9, 25),
        city: City.mumbai,
        today: DateTime(2026, 9, 22),
        festivalRules: [anantRule],
      );

      expect(sep25.festival, 'Anant Chaturdashi');
      expect(sep25.vrat, 'Anant Chaturdashi');
      expect(sep25.tithi, 'Chaturdashi');
      expect(sep25.paksha, 'Shukla Paksha');
    });
  });
}
