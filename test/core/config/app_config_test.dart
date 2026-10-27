import 'package:crypto_market/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DataSource.parse', () {
    test('accepts live and mock, ignoring case and whitespace', () {
      expect(DataSource.parse('live'), DataSource.live);
      expect(DataSource.parse(' MOCK '), DataSource.mock);
    });

    test('rejects unknown values instead of guessing', () {
      expect(() => DataSource.parse('production'), throwsArgumentError);
    });
  });

  test('defaults to live data when no DATA_SOURCE is given', () {
    expect(AppConfig.fromEnvironment().dataSource, DataSource.live);
  });

  test('picks the right host address per platform when no URL is given', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(AppConfig.defaultApiBaseUrl(), 'http://10.0.2.2:3000/api/v1');

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AppConfig.defaultApiBaseUrl(), 'http://localhost:3000/api/v1');
  });
}
