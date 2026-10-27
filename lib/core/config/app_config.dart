import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DataSource {
  live,

  mock;

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

class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.dataSource});

  factory AppConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    const dataSource = String.fromEnvironment(
      'DATA_SOURCE',
      defaultValue: 'live',
    );

    return AppConfig(
      apiBaseUrl: baseUrl.isNotEmpty ? baseUrl : defaultApiBaseUrl(),
      dataSource: DataSource.parse(dataSource),
    );
  }

  final String apiBaseUrl;
  final DataSource dataSource;

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
