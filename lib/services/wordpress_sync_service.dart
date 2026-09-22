import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';
import '../models/festival_rule.dart';

/// Result summary of a WordPress festival sync operation.
class SyncResult {
  final bool isSuccess;
  final int count;
  final String? errorMessage;
  final DateTime? syncTime;
  final bool fromCache;

  const SyncResult({
    required this.isSuccess,
    required this.count,
    this.errorMessage,
    this.syncTime,
    this.fromCache = false,
  });

  factory SyncResult.success({required int count, DateTime? syncTime}) =>
      SyncResult(
        isSuccess: true,
        count: count,
        syncTime: syncTime ?? DateTime.now(),
        fromCache: false,
      );

  factory SyncResult.fromCache({required int count, String? error}) =>
      SyncResult(
        isSuccess: true,
        count: count,
        errorMessage: error,
        syncTime: DateTime.now(),
        fromCache: true,
      );

  factory SyncResult.failure(String error) => SyncResult(
        isSuccess: false,
        count: 0,
        errorMessage: error,
        fromCache: false,
      );
}

/// Service that handles syncing Vedic festival & vrat rules from the WordPress REST API.
///
/// Features:
/// - Connects to `/wp-json/wp/v2/festivals`.
/// - Resolves host address automatically: `localhost` on macOS Desktop/iOS vs `10.0.2.2` on Android Emulator.
/// - Parses ACF multilingual fields and astronomical rules.
/// - Persists records into SQLite (`AppDatabase.tableFestivals`).
/// - 100% Offline-first: Falls back to cached SQLite data or bundled seed JSON on network loss.
class WordPressSyncService {
  static final WordPressSyncService instance = WordPressSyncService._init();
  WordPressSyncService._init();

  /// Default production/staging base path for festivals REST endpoint.
  static const String defaultEndpointPath =
      '/udaysutaria/tithinow.data/wp-json/wp/v2/festivals';

  /// Resolves the default API endpoint URL according to running platform.
  static String get defaultEndpointUrl {
    final bool isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final String host = isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:8888$defaultEndpointPath';
  }

  /// Custom endpoint URL override (if user configures a live WordPress server).
  String? customEndpointUrl;

  /// Returns the active endpoint URL to fetch from.
  String get activeEndpointUrl => customEndpointUrl ?? defaultEndpointUrl;

  /// Syncs festivals from WordPress REST API into local SQLite database.
  ///
  /// - [endpointUrl]: Optional URL override.
  /// - [client]: Optional [http.Client] (useful for tests).
  /// - [timeout]: Request timeout (defaults to 10 seconds).
  Future<SyncResult> syncFestivals({
    String? endpointUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final targetUrl = endpointUrl ?? activeEndpointUrl;
    final httpClient = client ?? http.Client();

    try {
      final uri = Uri.parse(targetUrl).replace(
        queryParameters: {
          'per_page': '100',
        },
      );

      final response = await httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final rules = decoded
              .whereType<Map<String, dynamic>>()
              .map(FestivalRule.fromWordPressJson)
              .toList();

          final count = await AppDatabase.instance.upsertFestivals(rules);
          await AppDatabase.instance.setMeta(
            AppDatabase.metaFestivalsLastSync,
            DateTime.now().toIso8601String(),
          );

          return SyncResult.success(count: count);
        } else {
          return await _fallbackOrSeed('Invalid JSON format received from server.');
        }
      } else {
        return await _fallbackOrSeed(
          'WordPress server returned HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on TimeoutException {
      return await _fallbackOrSeed('Connection timed out while reaching WordPress server.');
    } on SocketException catch (e) {
      return await _fallbackOrSeed('Network error (SocketException): ${e.message}');
    } catch (e) {
      return await _fallbackOrSeed('Sync error: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Handles network failure gracefully by falling back to SQLite cache or seed JSON.
  Future<SyncResult> _fallbackOrSeed(String errorReason) async {
    final cachedCount = await AppDatabase.instance.getFestivalsCount();
    if (cachedCount > 0) {
      return SyncResult.fromCache(count: cachedCount, error: errorReason);
    }

    // If cache is empty (first offline launch), load from bundled seed
    final seedCount = await AppDatabase.instance.importFestivalsFromSeed();
    if (seedCount > 0) {
      return SyncResult.fromCache(count: seedCount, error: '$errorReason (loaded offline seed)');
    }

    return SyncResult.failure(errorReason);
  }
}
