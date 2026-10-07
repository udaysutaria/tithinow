import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../constants/panchang_terms.dart';
import '../models/city.dart';
import '../models/festival_rule.dart';
import '../models/alarm_record.dart';
import '../constants/alarm_sound_data.dart';

/// SQLite Database manager for TithiNow.
///
/// Features:
/// - Manages SQLite database lifecycle across mobile, desktop, and tests.
/// - Imports 7,100+ cities and coordinates from `assets/data/cities.csv` on app first launch.
/// - Provides fast indexed queries for city search and location coordinate lookups.
/// - Caches Vedic festival and vrat rules synced from WordPress REST API.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  /// Reactive notifier for the active application language.
  ValueNotifier<AppLanguage> get languageNotifier => appLanguageNotifier;

  /// Reactive notifier for the active selected city.
  final ValueNotifier<City?> cityNotifier = ValueNotifier<City?>(null);

  /// Constant identifiers for the supported Vedic lunar calendar systems.
  static const String lunarPurnimanta = 'purnimanta';
  static const String lunarAmanta = 'amanta';

  /// Reactive notifier for the active lunar calendar system ('purnimanta' or 'amanta').
  final ValueNotifier<String> lunarSystemNotifier =
      ValueNotifier<String>(lunarPurnimanta);

  /// Reactive notifier that triggers whenever festival rules are imported, synced, or updated.
  final ValueNotifier<int> festivalsNotifier = ValueNotifier<int>(0);

  /// Reactive notifier for the selected alarm sound ('sound_1', 'sound_2', etc.).
  final ValueNotifier<String> alarmSoundNotifier =
      ValueNotifier<String>(AlarmSounds.defaultSoundId);

  /// Default database file name.
  static const String dbName = 'tithinow.db';

  /// Table names.
  static const String tableCities = 'cities';
  static const String tableMeta = 'app_meta';
  static const String tableFestivals = 'festivals';
  static const String tableAlarms = 'alarms';

  /// Meta keys.
  static const String metaCitiesImported = 'cities_imported';
  static const String metaFestivalsImported = 'festivals_imported';
  static const String metaFestivalsSeedVersion = 'festivals_seed_version';
  static const int currentFestivalsSeedVersion = 4;
  static const String metaFestivalsLastSync = 'festivals_last_sync';
  static const String metaOnboardingCompleted = 'onboarding_completed';
  static const String metaLunarSystem = 'lunar_system';
  static const String metaCityId = 'city_id';
  static const String metaCityName = 'city_name';
  static const String metaCityState = 'city_state';
  static const String metaCityLat = 'city_lat';
  static const String metaCityLng = 'city_lng';
  static const String metaLanguage = 'language';
  static const String metaAlarmSound = 'alarm_sound';

  /// Ensures SQLite FFI is initialized for Linux, Windows, or unit tests.
  static void initializeFfiIfNeeded() {
    if (!kIsWeb &&
        (Platform.isWindows ||
            Platform.isLinux ||
            Platform.environment.containsKey('FLUTTER_TEST'))) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Returns the singleton [Database] instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDB(dbName);
    return _database!;
  }

  /// Initializes the SQLite database file and schema.
  Future<Database> _initDB(String fileName, {bool inMemory = false}) async {
    initializeFfiIfNeeded();

    if (inMemory) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: _createDB,
      );
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // Ensure festivals and alarms tables exist even if DB was created previously
        await _ensureFestivalsTable(db);
        await _ensureAlarmsTable(db);
        // Check if cities and festivals need to be imported on first launch
        await _checkAndImportCities(db);
        await _checkAndImportFestivals(db);
      },
    );
  }

  /// Helper for unit tests to initialize an isolated in-memory or custom database.
  static Future<Database> initCustomDatabase({
    bool inMemory = true,
    String? path,
  }) async {
    initializeFfiIfNeeded();
    final db = await openDatabase(
      inMemory ? inMemoryDatabasePath : (path ?? inMemoryDatabasePath),
      version: 1,
      onCreate: instance._createDB,
    );
    _database = db;
    return db;
  }

  /// Creates schema tables and search indexes.
  Future<void> _createDB(Database db, int version) async {
    // 1. Cities Table
    await db.execute('''
      CREATE TABLE $tableCities (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        state TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');

    // Indexes for fast auto-complete & filtering
    await db.execute(
      'CREATE INDEX idx_cities_name ON $tableCities (name COLLATE NOCASE)',
    );
    await db.execute(
      'CREATE INDEX idx_cities_state ON $tableCities (state COLLATE NOCASE)',
    );

    // 2. App Metadata Table (Tracks migrations, initial import flags, etc.)
    await db.execute('''
      CREATE TABLE $tableMeta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 3. Festivals & Vrats Rules Table
    await _createFestivalsTable(db);

    // 4. Alarms Table
    await _createAlarmsTable(db);
  }

  /// Creates the festivals table and its performance indexes.
  Future<void> _createFestivalsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableFestivals (
        id INTEGER PRIMARY KEY,
        festival_id TEXT UNIQUE NOT NULL,
        category TEXT NOT NULL,
        importance_level TEXT NOT NULL,
        is_fasting INTEGER NOT NULL,
        name_en TEXT NOT NULL,
        name_hi TEXT NOT NULL,
        name_gu TEXT NOT NULL,
        desc_en TEXT NOT NULL,
        desc_hi TEXT NOT NULL,
        desc_gu TEXT NOT NULL,
        event_type TEXT NOT NULL,
        day_selection_rule TEXT NOT NULL,
        lunar_month TEXT,
        paksha TEXT,
        tithi_number INTEGER,
        solar_month TEXT,
        nakshatra_constraint TEXT,
        region_variant TEXT NOT NULL,
        rule_version INTEGER NOT NULL,
        modified TEXT,
        fasting_type TEXT,
        parana_rule TEXT,
        duration_days INTEGER DEFAULT 1,
        end_festival_id TEXT,
        parent_festival_id TEXT,
        offset_days INTEGER,
        fixed_month INTEGER,
        fixed_day INTEGER,
        eclipse_type TEXT,
        sutak_applies INTEGER DEFAULT 0,
        tie_break_rule TEXT,
        adhika_masa_policy TEXT,
        weekday TEXT,
        weekday_rule TEXT,
        repeat_weekday INTEGER DEFAULT 0,
        avoid_bhadra INTEGER DEFAULT 0,
        purnimanta_month TEXT,
        nakshatra_trigger TEXT,
        nakshatra_solar_month TEXT,
        nakshatra_lunar_month TEXT,
        sampradaya TEXT,
        source_reference TEXT,
        ayanamsa TEXT,
        verified INTEGER DEFAULT 0,
        verification_notes TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_festivals_fid ON $tableFestivals (festival_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_festivals_rule ON $tableFestivals (event_type, lunar_month, paksha, tithi_number)',
    );
  }

  /// Ensures festivals table exists (for existing app databases without version bump).
  Future<void> _ensureFestivalsTable(Database db) async {
    await _createFestivalsTable(db);
    final tableInfo = await db.rawQuery('PRAGMA table_info($tableFestivals)');
    final existingColumns = tableInfo
        .map((row) => (row['name'] as String?)?.toLowerCase())
        .whereType<String>()
        .toSet();

    const newColumns = [
      'fasting_type TEXT',
      'parana_rule TEXT',
      'duration_days INTEGER DEFAULT 1',
      'end_festival_id TEXT',
      'parent_festival_id TEXT',
      'offset_days INTEGER',
      'fixed_month INTEGER',
      'fixed_day INTEGER',
      'eclipse_type TEXT',
      'sutak_applies INTEGER DEFAULT 0',
      'tie_break_rule TEXT',
      'adhika_masa_policy TEXT',
      'weekday TEXT',
      'weekday_rule TEXT',
      'repeat_weekday INTEGER DEFAULT 0',
      'avoid_bhadra INTEGER DEFAULT 0',
      'purnimanta_month TEXT',
      'nakshatra_trigger TEXT',
      'nakshatra_solar_month TEXT',
      'nakshatra_lunar_month TEXT',
      'sampradaya TEXT',
      'source_reference TEXT',
      'ayanamsa TEXT',
      'verified INTEGER DEFAULT 0',
      'verification_notes TEXT',
    ];
    for (final col in newColumns) {
      final colName = col.split(' ').first.toLowerCase();
      if (!existingColumns.contains(colName)) {
        try {
          await db.execute('ALTER TABLE $tableFestivals ADD COLUMN $col');
        } catch (_) {}
      }
    }
  }

  /// Creates the alarms table and performance indexes.
  Future<void> _createAlarmsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableAlarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        external_id INTEGER UNIQUE NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        time_display TEXT NOT NULL,
        trigger_time INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        parent_rule_id TEXT,
        is_repeating INTEGER NOT NULL DEFAULT 0,
        tithi_name TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alarms_ext ON $tableAlarms (external_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alarms_trigger ON $tableAlarms (trigger_time)',
    );
  }

  /// Ensures alarms table exists and has latest columns.
  Future<void> _ensureAlarmsTable(Database db) async {
    await _createAlarmsTable(db);
    final tableInfo = await db.rawQuery('PRAGMA table_info($tableAlarms)');
    final existingColumns = tableInfo
        .map((row) => (row['name'] as String?)?.toLowerCase())
        .whereType<String>()
        .toSet();

    const newColumns = [
      'parent_rule_id TEXT',
      'is_repeating INTEGER NOT NULL DEFAULT 0',
      'tithi_name TEXT',
    ];
    for (final col in newColumns) {
      final colName = col.split(' ').first.toLowerCase();
      if (!existingColumns.contains(colName)) {
        try {
          await db.execute('ALTER TABLE $tableAlarms ADD COLUMN $col');
        } catch (_) {}
      }
    }
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_alarms_parent_rule ON $tableAlarms (parent_rule_id)',
      );
    } catch (_) {}
  }

  /// Checks if cities CSV was already imported. If not, imports it.
  Future<void> _checkAndImportCities(Database db) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    final count = await getCitiesCount(db: db);
    if (count == 0) {
      await importCitiesFromCsv(db: db);
    }
  }

  /// Checks if festivals seed data was imported. If empty or outdated, imports bundled seed.
  Future<void> _checkAndImportFestivals(Database db) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    final count = await getFestivalsCount(db: db);
    final versionStr = await getMeta(metaFestivalsSeedVersion, db: db);
    final currentVersion = int.tryParse(versionStr ?? '') ?? (count > 0 ? 1 : 0);

    if (count == 0 || currentVersion < currentFestivalsSeedVersion) {
      await importFestivalsFromSeed(db: db);
    }
  }

  /// Imports cities from `assets/data/cities.csv` into the SQLite database.
  ///
  /// Uses a high-performance batched transaction to import ~7,100 records in milliseconds.
  /// If [csvData] is provided, parses from string directly (useful for tests).
  Future<int> importCitiesFromCsv({
    Database? db,
    String? csvData,
    String csvAssetPath = 'assets/data/cities.csv',
  }) async {
    final targetDb = db ?? await database;

    final String content;
    if (csvData != null) {
      content = csvData;
    } else {
      content = await rootBundle.loadString(csvAssetPath);
    }

    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) return 0;

    // Batch insert inside a single transaction for maximum speed
    final batch = targetDb.batch();
    int importedCount = 0;

    // Line 0 is header: id,name,state,latitude,longitude
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length < 5) continue;

      final id = int.tryParse(parts[0].trim());
      final name = parts[1].trim();
      final state = parts[2].trim();
      final lat = double.tryParse(parts[3].trim());
      final lon = double.tryParse(parts[4].trim());

      if (id != null && lat != null && lon != null && name.isNotEmpty) {
        batch.insert(
          tableCities,
          {
            'id': id,
            'name': name,
            'state': state,
            'latitude': lat,
            'longitude': lon,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        importedCount++;
      }
    }

    // Record meta flag
    batch.insert(
      tableMeta,
      {'key': metaCitiesImported, 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await batch.commit(noResult: true);
    return importedCount;
  }

  /// Returns total number of cities in the database.
  Future<int> getCitiesCount({Database? db}) async {
    final targetDb = db ?? await database;
    final result = await targetDb.rawQuery('SELECT COUNT(*) as count FROM $tableCities');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Searches cities by name or state with prefix prioritizing and limit.
  ///
  /// Example: `searchCities('Mum')` returns `[City(name: 'Mumbai', ...)]`.
  Future<List<City>> searchCities(String query, {int limit = 50, Database? db}) async {
    final targetDb = db ?? await database;
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      // Default: Return major cities (or first N cities)
      final maps = await targetDb.query(
        tableCities,
        limit: limit,
        orderBy: 'id ASC',
      );
      return maps.map(City.fromMap).toList();
    }

    // Tier 1: Fast exact prefix match on city name (uses B-Tree index idx_cities_name)
    final prefixMaps = await targetDb.query(
      tableCities,
      where: 'name LIKE ?',
      whereArgs: ['$trimmed%'],
      orderBy: 'name ASC',
      limit: limit,
    );

    if (prefixMaps.length >= limit) {
      return prefixMaps.map(City.fromMap).toList();
    }

    // Tier 2: If additional results are needed to fulfill limit, query substring & state matches
    final remainingLimit = limit - prefixMaps.length;
    final List<Map<String, dynamic>> secondaryMaps;

    if (prefixMaps.isEmpty) {
      secondaryMaps = await targetDb.rawQuery(
        '''
        SELECT * FROM $tableCities
        WHERE name LIKE ? OR state LIKE ?
        ORDER BY
          CASE
            WHEN name LIKE ? THEN 0
            WHEN state LIKE ? THEN 1
            ELSE 2
          END,
          name ASC
        LIMIT ?
        ''',
        [
          '%$trimmed%',
          '%$trimmed%',
          '%$trimmed%',
          '$trimmed%',
          remainingLimit,
        ],
      );
    } else {
      final existingIds = prefixMaps.map((m) => m['id'] as int).toList();
      final idPlaceholders = List.filled(existingIds.length, '?').join(',');
      secondaryMaps = await targetDb.rawQuery(
        '''
        SELECT * FROM $tableCities
        WHERE id NOT IN ($idPlaceholders)
          AND (name LIKE ? OR state LIKE ?)
        ORDER BY
          CASE
            WHEN name LIKE ? THEN 0
            WHEN state LIKE ? THEN 1
            ELSE 2
          END,
          name ASC
        LIMIT ?
        ''',
        [
          ...existingIds,
          '%$trimmed%',
          '%$trimmed%',
          '%$trimmed%',
          '$trimmed%',
          remainingLimit,
        ],
      );
    }

    return [
      ...prefixMaps.map(City.fromMap),
      ...secondaryMaps.map(City.fromMap),
    ];
  }

  /// Returns a specific city by its [id].
  Future<City?> getCityById(int id, {Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableCities,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return City.fromMap(maps.first);
    }
    return null;
  }

  /// Returns a city matching [name] and optional [state].
  Future<City?> getCityByName(String name, {String? state, Database? db}) async {
    final targetDb = db ?? await database;
    final whereClause = state != null ? 'name = ? AND state = ?' : 'name = ?';
    final whereArgs = state != null ? [name, state] : [name];

    final maps = await targetDb.query(
      tableCities,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return City.fromMap(maps.first);
    }
    return null;
  }

  /// Returns all cities belonging to a particular [state].
  Future<List<City>> getCitiesByState(String state, {Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableCities,
      where: 'state = ?',
      whereArgs: [state],
      orderBy: 'name ASC',
    );
    return maps.map(City.fromMap).toList();
  }

  /// Returns an alphabetically sorted list of all unique states.
  Future<List<String>> getAllStates({Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.rawQuery(
      'SELECT DISTINCT state FROM $tableCities ORDER BY state ASC',
    );
    return maps.map((row) => row['state'] as String).toList();
  }

  /// Checks if the initial CSV import has been performed.
  Future<bool> isCitiesImported({Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableMeta,
      where: 'key = ?',
      whereArgs: [metaCitiesImported],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// Retrieves a value from the app metadata table.
  Future<String?> getMeta(String key, {Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableMeta,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  /// Sets or replaces a key-value pair in the app metadata table.
  Future<void> setMeta(String key, String value, {Database? db}) async {
    final targetDb = db ?? await database;
    await targetDb.insert(
      tableMeta,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Checks if the user has completed initial onboarding.
  Future<bool> isOnboardingCompleted({Database? db}) async {
    final val = await getMeta(metaOnboardingCompleted, db: db);
    return val == 'true';
  }

  /// Sets the onboarding completion flag.
  Future<void> setOnboardingCompleted(bool completed, {Database? db}) async {
    await setMeta(
      metaOnboardingCompleted,
      completed ? 'true' : 'false',
      db: db,
    );
  }

  /// Retrieves all saved user preferences.
  Future<Map<String, String?>> getUserPreferences({Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(tableMeta);
    final result = <String, String?>{};
    for (final row in maps) {
      final key = row['key'] as String?;
      final value = row['value'] as String?;
      if (key != null) {
        result[key] = value;
      }
    }
    return result;
  }

  /// Atomically saves the user's preferences to the database.
  Future<void> saveUserPreferences({
    required String lunarSystem,
    required City city,
    required String language,
    bool markOnboardingCompleted = false,
    Database? db,
  }) async {
    final targetDb = db ?? await database;
    final batch = targetDb.batch();
    batch.insert(
      tableMeta,
      {'key': metaLunarSystem, 'value': lunarSystem},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      tableMeta,
      {'key': metaCityId, 'value': city.id.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      tableMeta,
      {'key': metaCityName, 'value': city.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      tableMeta,
      {'key': metaCityState, 'value': city.state},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      tableMeta,
      {'key': metaCityLat, 'value': city.latitude.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      tableMeta,
      {'key': metaCityLng, 'value': city.longitude.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    batch.insert(
      tableMeta,
      {'key': metaLanguage, 'value': language},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (markOnboardingCompleted) {
      batch.insert(
        tableMeta,
        {'key': metaOnboardingCompleted, 'value': 'true'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    final appLang = AppLanguage.fromString(language);
    languageNotifier.value = appLang;
    cityNotifier.value = city;
    lunarSystemNotifier.value = lunarSystem;
  }

  /// Saves the active lunar system to the database and updates [lunarSystemNotifier].
  Future<void> saveLunarSystem(String lunarSystem, {Database? db}) async {
    await setMeta(metaLunarSystem, lunarSystem, db: db);
    lunarSystemNotifier.value = lunarSystem;
  }

  /// Retrieves the saved lunar calendar system, falling back to [lunarPurnimanta].
  Future<String> getSavedLunarSystem({Database? db}) async {
    final system = await getMeta(metaLunarSystem, db: db);
    final effective = (system != null && system.isNotEmpty) ? system : lunarPurnimanta;
    lunarSystemNotifier.value = effective;
    return effective;
  }

  /// Saves the active [AppLanguage] to the database and updates [languageNotifier].
  Future<void> saveLanguage(AppLanguage language, {Database? db}) async {
    await setMeta(metaLanguage, language.name, db: db);
    languageNotifier.value = language;
  }

  /// Retrieves the saved [AppLanguage], falling back to [AppLanguage.english].
  Future<AppLanguage> getSavedLanguage({Database? db}) async {
    final langStr = await getMeta(metaLanguage, db: db);
    final lang = langStr != null
        ? AppLanguage.fromString(langStr)
        : AppLanguage.english;
    languageNotifier.value = lang;
    return lang;
  }

  /// Retrieves the saved [City] record if one was previously selected.
  Future<City?> getSavedCity({Database? db}) async {
    final idStr = await getMeta(metaCityId, db: db);
    final id = idStr != null ? int.tryParse(idStr) : null;
    if (id != null) {
      final city = await getCityById(id, db: db);
      if (city != null) {
        cityNotifier.value = city;
        return city;
      }
    }

    final name = await getMeta(metaCityName, db: db);
    final state = await getMeta(metaCityState, db: db);
    if (name != null && state != null) {
      final city = await getCityByName(name, state: state, db: db);
      if (city != null) {
        cityNotifier.value = city;
        return city;
      }
    }

    // Reconstruct directly from stored metadata if table row is absent
    if (id != null && name != null && state != null) {
      final latStr = await getMeta(metaCityLat, db: db);
      final lngStr = await getMeta(metaCityLng, db: db);
      final lat = latStr != null ? double.tryParse(latStr) ?? 0.0 : 0.0;
      final lng = lngStr != null ? double.tryParse(lngStr) ?? 0.0 : 0.0;
      final city = City(
        id: id,
        name: name,
        state: state,
        latitude: lat,
        longitude: lng,
      );
      cityNotifier.value = city;
      return city;
    }

    return null;
  }

  // ===========================================================================
  // Festivals & Vrats Storage & Queries
  // ===========================================================================

  /// Imports festival seed data from `assets/data/seed_festivals.json` or provided JSON string.
  Future<int> importFestivalsFromSeed({
    Database? db,
    String? jsonContent,
    String seedAssetPath = 'assets/data/seed_festivals.json',
  }) async {
    final targetDb = db ?? await database;
    final String content;
    if (jsonContent != null) {
      content = jsonContent;
    } else {
      try {
        content = await rootBundle.loadString(seedAssetPath);
      } catch (_) {
        return 0;
      }
    }

    if (content.trim().isEmpty) return 0;
    try {
      final list = jsonDecode(content) as List<dynamic>;
      final rules = list
          .whereType<Map<String, dynamic>>()
          .map(FestivalRule.fromWordPressJson)
          .toList();
      final count = await upsertFestivals(rules, db: targetDb);
      await setMeta(metaFestivalsImported, DateTime.now().toIso8601String(), db: targetDb);
      await setMeta(metaFestivalsSeedVersion, currentFestivalsSeedVersion.toString(), db: targetDb);
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Upserts a batch of [FestivalRule] records into the SQLite database.
  Future<int> upsertFestivals(List<FestivalRule> rules, {Database? db}) async {
    if (rules.isEmpty) return 0;
    final targetDb = db ?? await database;
    final batch = targetDb.batch();

    for (final rule in rules) {
      batch.insert(
        tableFestivals,
        rule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    FestivalRule.registerRules(rules);
    festivalsNotifier.value++;
    return rules.length;
  }

  /// Returns total count of festival rules in SQLite.
  Future<int> getFestivalsCount({Database? db}) async {
    final targetDb = db ?? await database;
    final result = await targetDb.rawQuery('SELECT COUNT(*) as count FROM $tableFestivals');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Retrieves all cached [FestivalRule] records.
  Future<List<FestivalRule>> getAllFestivalRules({Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableFestivals,
      orderBy: 'importance_level ASC, name_en ASC',
    );
    final rules = maps.map(FestivalRule.fromMap).toList();
    if (rules.isNotEmpty) {
      FestivalRule.registerRules(rules);
    }
    return rules;
  }

  /// Retrieves a specific [FestivalRule] by its unique [festivalId] slug.
  Future<FestivalRule?> getFestivalRuleById(String festivalId, {Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableFestivals,
      where: 'festival_id = ?',
      whereArgs: [festivalId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return FestivalRule.fromMap(maps.first);
    }
    return null;
  }

  /// Queries festival rules matching a lunar tithi combination.
  ///
  /// Matches exact month (or 'any' month) AND paksha (or 'both') AND tithi number.
  Future<List<FestivalRule>> getFestivalRulesForTithi({
    required String lunarMonth,
    required String paksha,
    required int tithiNumber,
    Database? db,
  }) async {
    final targetDb = db ?? await database;
    final normalizedMonth = lunarMonth.toLowerCase().trim();
    final normalizedPaksha = paksha.toLowerCase().trim();

    final List<String> monthAliases = [normalizedMonth];
    if (normalizedMonth == 'ashwin') {
      monthAliases.add('ashvina');
    } else if (normalizedMonth == 'ashvina') {
      monthAliases.add('ashwin');
    } else if (normalizedMonth == 'kartika') {
      monthAliases.add('kartik');
    } else if (normalizedMonth == 'kartik') {
      monthAliases.add('kartika');
    }

    final placeholders = List.filled(monthAliases.length, '?').join(',');
    final maps = await targetDb.query(
      tableFestivals,
      where: 'event_type = ? AND (lunar_month IN ($placeholders) OR lunar_month = ? OR lunar_month IS NULL) AND (paksha = ? OR paksha = ? OR paksha IS NULL) AND tithi_number = ?',
      whereArgs: [
        'lunar_tithi',
        ...monthAliases,
        'any',
        normalizedPaksha,
        'both',
        tithiNumber,
      ],
    );
    return maps.map(FestivalRule.fromMap).toList();
  }

  /// Queries festival rules matching a solar sankranti (ingress into [solarMonth]).
  Future<List<FestivalRule>> getFestivalRulesForSankranti({
    required String solarMonth,
    Database? db,
  }) async {
    final targetDb = db ?? await database;
    final normalizedSolar = solarMonth.toLowerCase().trim();

    final maps = await targetDb.query(
      tableFestivals,
      where: 'event_type = ? AND solar_month = ?',
      whereArgs: ['solar_sankranti', normalizedSolar],
    );
    return maps.map(FestivalRule.fromMap).toList();
  }

  // ===========================================================================
  // Alarms & Ringtones CRUD Methods
  // ===========================================================================

  /// Inserts or updates an alarm schedule record.
  Future<void> saveAlarm(AlarmRecord record, {Database? db}) async {
    final targetDb = db ?? await database;
    await targetDb.insert(
      tableAlarms,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserts a batch of alarm records in a single high-performance transaction.
  Future<void> saveAlarms(List<AlarmRecord> records, {Database? db}) async {
    if (records.isEmpty) return;
    final targetDb = db ?? await database;
    final batch = targetDb.batch();
    for (final record in records) {
      batch.insert(
        tableAlarms,
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Deletes an alarm by its external ID.
  Future<void> deleteAlarm(int externalId, {Database? db}) async {
    final targetDb = db ?? await database;
    await targetDb.delete(
      tableAlarms,
      where: 'external_id = ?',
      whereArgs: [externalId],
    );
  }

  /// Deletes all alarms belonging to a repeating rule series by [parentRuleId].
  Future<void> deleteAlarmsByParentRuleId(String parentRuleId, {Database? db}) async {
    final targetDb = db ?? await database;
    await targetDb.delete(
      tableAlarms,
      where: 'parent_rule_id = ?',
      whereArgs: [parentRuleId],
    );
  }

  /// Fetches all alarms belonging to a repeating rule series by [parentRuleId].
  Future<List<AlarmRecord>> getAlarmsByParentRuleId(String parentRuleId, {Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableAlarms,
      where: 'parent_rule_id = ?',
      whereArgs: [parentRuleId],
      orderBy: 'trigger_time ASC',
    );
    return maps.map(AlarmRecord.fromMap).toList();
  }

  /// Fetches an alarm by its external ID.
  Future<AlarmRecord?> getAlarmByExternalId(int externalId, {Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableAlarms,
      where: 'external_id = ?',
      whereArgs: [externalId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AlarmRecord.fromMap(maps.first);
  }

  /// Retrieves all alarms ordered by scheduled trigger time ascending.
  Future<List<AlarmRecord>> getAllAlarms({Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableAlarms,
      orderBy: 'trigger_time ASC',
    );
    return maps.map(AlarmRecord.fromMap).toList();
  }

  /// Retrieves all active alarms ordered by scheduled trigger time ascending.
  Future<List<AlarmRecord>> getActiveAlarms({Database? db}) async {
    final targetDb = db ?? await database;
    final maps = await targetDb.query(
      tableAlarms,
      where: 'is_active = 1',
      orderBy: 'trigger_time ASC',
    );
    return maps.map(AlarmRecord.fromMap).toList();
  }

  /// Toggles the active status of an alarm.
  Future<void> toggleAlarmActive(int externalId, bool isActive, {Database? db}) async {
    final targetDb = db ?? await database;
    await targetDb.update(
      tableAlarms,
      {'is_active': isActive ? 1 : 0},
      where: 'external_id = ?',
      whereArgs: [externalId],
    );
  }

  /// Reads the saved alarm sound ID from metadata (defaults to [AlarmSounds.defaultSoundId]).
  Future<String> getSavedAlarmSound({Database? db}) async {
    final val = await getMeta(metaAlarmSound, db: db);
    final soundId = val ?? AlarmSounds.defaultSoundId;
    if (alarmSoundNotifier.value != soundId) {
      alarmSoundNotifier.value = soundId;
    }
    return soundId;
  }

  /// Persists the selected alarm sound ID and notifies listeners.
  Future<void> saveAlarmSound(String soundId, {Database? db}) async {
    await setMeta(metaAlarmSound, soundId, db: db);
    alarmSoundNotifier.value = soundId;
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }

  /// Deletes the database file (useful for full resets or testing).
  Future<void> deleteDb() async {
    await close();
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);
    await deleteDatabase(path);
  }
}
