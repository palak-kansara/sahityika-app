/// API host and flavor are chosen at **compile time** via `--dart-define`.
///
/// **Option A — flavor (defaults)**  
/// - Development (default when nothing is passed): ngrok / local backend  
/// - Production: `FLAVOR=production`
///
/// ```bash
/// flutter run
/// flutter run --dart-define=FLAVOR=development
/// flutter run --dart-define=FLAVOR=production
/// flutter build apk --dart-define=FLAVOR=production
/// flutter build ios --dart-define=FLAVOR=production
/// ```
///
/// **Option B — explicit base URL** (overrides flavor)  
/// Must be the API root **without** a trailing slash (e.g. `https://host.com/api`).
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://192.168.1.10:8000/api
/// ```

class Environment {
  Environment._();

  static const String flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'development',
  );

  /// When non-empty, used as [baseUrl] instead of the flavor default.
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _devDefaultBaseUrl =
      'https://unmirthful-alla-lyrate.ngrok-free.dev/api';

  static const String _prodDefaultBaseUrl =
      'https://sahityika.onrender.com/api';

  static String get baseUrl {
    final override = _apiBaseUrlOverride.trim();
    if (override.isNotEmpty) {
      return _stripTrailingSlashes(override);
    }
    return switch (flavor) {
      'production' => _prodDefaultBaseUrl,
      _ => _devDefaultBaseUrl,
    };
  }

  static bool get isProduction => flavor == 'production';

  static String _stripTrailingSlashes(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
