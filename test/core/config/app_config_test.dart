import 'package:crypto_market/core/config/app_config.dart';
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

  test('defaults to mock data when no DATA_SOURCE is given', () {
    expect(AppConfig.fromEnvironment().dataSource, DataSource.mock);
  });
}
