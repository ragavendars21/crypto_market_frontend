import 'package:crypto_market/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rate limit message includes the wait time when known', () {
    expect(
      const RateLimitedFailure(retryAfter: Duration(seconds: 30)).message,
      contains('30 seconds'),
    );
    expect(const RateLimitedFailure().message, contains('shortly'));
  });

  test('server failure message hides the internal error code', () {
    const failure = ServerFailure(code: 'UPSTREAM_ERROR');

    expect(failure.message, isNot(contains('UPSTREAM_ERROR')));
  });
}
