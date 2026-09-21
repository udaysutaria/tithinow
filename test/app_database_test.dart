import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tithinow/database/app_database.dart';
import 'package:tithinow/models/city.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('City Model Tests', () {
    test('City model serializes and formats correctly', () {
      const city = City(
        id: 1,
        name: 'Mumbai',
        state: 'Maharashtra',
        latitude: 19.0761,
        longitude: 72.8775,
      );

      expect(city.displayName, 'Mumbai, Maharashtra');
      expect(city.coordinatesDisplay, '19.0761° N, 72.8775° E');

      final map = city.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Mumbai');
      expect(map['state'], 'Maharashtra');
      expect(map['latitude'], 19.0761);
      expect(map['longitude'], 72.8775);

      final fromMap = City.fromMap(map);
      expect(fromMap, equals(city));
    });
  });

  group('AppDatabase SQLite Tests', () {
    late Database db;
    late AppDatabase appDb;

    setUp(() async {
      appDb = AppDatabase.instance;
      db = await AppDatabase.initCustomDatabase(inMemory: true);
    });

    tearDown(() async {
      if (db.isOpen) {
        await db.close();
      }
    });

    test('Initializes schema tables and indexes', () async {
      final count = await appDb.getCitiesCount(db: db);
      expect(count, 0);

      final imported = await appDb.isCitiesImported(db: db);
      expect(imported, isFalse);
    });

    test('Saves and retrieves user preferences', () async {
      const city = City(
        id: 1,
        name: 'Ahmedabad',
        state: 'Gujarat',
        latitude: 23.0225,
        longitude: 72.5714,
      );

      await appDb.saveUserPreferences(
        lunarSystem: 'amanta',
        city: city,
        language: 'Gujarati',
        markOnboardingCompleted: true,
        db: db,
      );

      final isCompleted = await appDb.isOnboardingCompleted(db: db);
      expect(isCompleted, isTrue);

      final prefs = await appDb.getUserPreferences(db: db);
      expect(prefs[AppDatabase.metaLunarSystem], equals('amanta'));
      expect(prefs[AppDatabase.metaLanguage], equals('Gujarati'));

      final savedCity = await appDb.getSavedCity(db: db);
      expect(savedCity, isNotNull);
      expect(savedCity!.name, equals('Ahmedabad'));
    });

    test('Imports sample CSV data and verifies records', () async {
      const sampleCsv = '''id,name,state,latitude,longitude
1,Mumbai,Maharashtra,19.0761,72.8775
2,Kolkata,West Bengal,22.5675,88.37
3,Bangalore,Karnataka,12.9789,77.5917
4,Chennai,Tamil Nadu,13.0825,80.275
5,Hyderabad,Telangana,17.3617,78.4747
6,Pune,Maharashtra,18.5203,73.8567
7,Ahmedabad,Gujarat,23.0225,72.5714
8,Surat,Gujarat,21.205,72.84
''';

      final importedCount = await appDb.importCitiesFromCsv(
        db: db,
        csvData: sampleCsv,
      );
      expect(importedCount, 8);

      final totalCount = await appDb.getCitiesCount(db: db);
      expect(totalCount, 8);

      final isImported = await appDb.isCitiesImported(db: db);
      expect(isImported, isTrue);

      // Verify getCityById
      final mumbai = await appDb.getCityById(1, db: db);
      expect(mumbai, isNotNull);
      expect(mumbai!.name, 'Mumbai');
      expect(mumbai.state, 'Maharashtra');
      expect(mumbai.latitude, 19.0761);
      expect(mumbai.longitude, 72.8775);

      // Verify search with prefix matching
      final searchResults = await appDb.searchCities('Ahme', db: db);
      expect(searchResults.length, 1);
      expect(searchResults.first.name, 'Ahmedabad');

      // Verify search matching state
      final gujaratCities = await appDb.getCitiesByState('Gujarat', db: db);
      expect(gujaratCities.length, 2);
      expect(gujaratCities.map((c) => c.name).toList(), ['Ahmedabad', 'Surat']);

      // Verify distinct states
      final states = await appDb.getAllStates(db: db);
      expect(states, ['Gujarat', 'Karnataka', 'Maharashtra', 'Tamil Nadu', 'Telangana', 'West Bengal']);
    });

    test('Imports full assets/data/cities.csv and verifies 7100+ cities', () async {
      final file = File('assets/data/cities.csv');
      expect(file.existsSync(), isTrue);

      final csvContent = await file.readAsString();
      final count = await appDb.importCitiesFromCsv(
        db: db,
        csvData: csvContent,
      );

      expect(count, 7102);
      expect(await appDb.getCitiesCount(db: db), 7102);

      // Test searching major Indian cities
      final mumbai = await appDb.getCityByName('Mumbai', db: db);
      expect(mumbai, isNotNull);
      expect(mumbai!.state, 'Maharashtra');

      final delhi = await appDb.searchCities('Delhi', db: db);
      expect(delhi.isNotEmpty, isTrue);

      final ahmedabad = await appDb.getCityByName('Ahmedabad', db: db);
      expect(ahmedabad, isNotNull);
      expect(ahmedabad!.state, 'Gujarat');
    });
  });
}
