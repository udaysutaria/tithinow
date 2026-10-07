import 'dart:convert';

/// API configuration for backend services.
///
/// Security:
/// - In development and CI, pass `--dart-define-from-file=.env` or `--dart-define=WP_BASE_URL=https://...`.
/// - If no environment define is passed, falls back to the obfuscated runtime string
///   to ensure the raw domain name is never indexed in plain text within public GitHub repositories.
class ApiConfig {
  const ApiConfig._();

  /// Primary environment variable key.
  static const String envWpBaseUrl = 'WP_BASE_URL';

  /// Compile-time environment override.
  static const String _envUrl = String.fromEnvironment(envWpBaseUrl);

  /// Obfuscated runtime fallback to keep the production endpoint private from GitHub code search.
  static final String _obfuscatedUrl = utf8.decode(
    base64.decode('aHR0cHM6Ly9hcHBkYXRhLnRpdGhpbm93LmNvbS93cC1qc29u'),
  );

  /// Resolved base URL for the WordPress REST API.
  static String get wpBaseUrl {
    if (_envUrl.isNotEmpty) {
      return _envUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return _obfuscatedUrl;
  }

  /// REST endpoint for Vedic festivals and vrats.
  static String get festivalsEndpoint => '$wpBaseUrl/wp/v2/festivals';
}
