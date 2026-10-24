import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the app gets its market data from.
enum DataSource {
  /// Real data from our Node.js backend.
  live,

  /// Bundled sample data. Deterministic, works offline, used by tests.
  mock;

  /// Parses the `DATA_SOURCE` build value. Fails fast on typos so a
  /// misconfigured build never silently runs against the wrong data.
  static DataSource parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'live' => DataSource.live,
      'mock' => DataSource.mock,
      _ => throw ArgumentError.value(
        value,
        'DATA_SOURCE',
        'Expected "live" or "mock"',
      ),
    };
  }
}

/// Build-time configuration, supplied with `--dart-define`:
///
/// ```
/// flutter run --dart-define=DATA_SOURCE=live --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
/// ```
///
/// The app never holds provider API keys; it only knows our backend's URL.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.dataSource});

  factory AppConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    const dataSource = String.fromEnvironment(
      'DATA_SOURCE',
      defaultValue: 'mock',
    );

    return AppConfig(
      apiBaseUrl: baseUrl.isNotEmpty ? baseUrl : defaultApiBaseUrl(),
      dataSource: DataSource.parse(dataSource),
    );
  }

  final String apiBaseUrl;
  final DataSource dataSource;

  /// The Android emulator reaches the host machine at 10.0.2.2, while web
  /// and the iOS simulator can use localhost. Physical devices need the
  /// computer's LAN IP passed via `API_BASE_URL`.
  static String defaultApiBaseUrl() {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final host = isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:3000/api/v1';
  }
}

final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);
