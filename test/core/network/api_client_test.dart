import 'package:crypto_market/core/errors/app_failure.dart';
import 'package:crypto_market/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = FakeHttpAdapter();
    client = apiClientWith(adapter);
  });

  Future<Object?> failureFor(ResponseBody Function(RequestOptions) handler) {
    adapter.handler = handler;
    return client
        .get('/anything')
        .then<Object?>((_) => null, onError: (Object e) => e);
  }

  ResponseBody errorBody(
    int status,
    String code, {
    Map<String, String>? headers,
  }) => jsonResponse(status, {
    'error': {'code': code, 'message': 'Some message.'},
  }, headers: headers ?? const {});

  test('returns the decoded envelope on success', () async {
    adapter.handler = (_) => jsonResponse(200, {
      'data': {'ok': true},
      'meta': {'source': 'live'},
    });

    final json = await client.get('/health');

    expect(json['data'], {'ok': true});
  });

  test('maps COIN_NOT_FOUND to NotFoundFailure', () async {
    expect(
      await failureFor((_) => errorBody(404, 'COIN_NOT_FOUND')),
      isA<NotFoundFailure>(),
    );
  });

  test('maps provider rate limiting and keeps Retry-After', () async {
    final failure = await failureFor(
      (_) => errorBody(
        503,
        'UPSTREAM_RATE_LIMITED',
        headers: {'retry-after': '30'},
      ),
    );

    expect(failure, isA<RateLimitedFailure>());
    expect(
      (failure! as RateLimitedFailure).retryAfter,
      const Duration(seconds: 30),
    );
  });

  test('maps our own 429 even without a body code', () async {
    expect(
      await failureFor((_) => jsonResponse(429, 'Too many')),
      isA<RateLimitedFailure>(),
    );
  });

  test('maps an upstream timeout to TimeoutFailure', () async {
    expect(
      await failureFor((_) => errorBody(504, 'UPSTREAM_TIMEOUT')),
      isA<TimeoutFailure>(),
    );
  });

  test('maps other errors to ServerFailure with the code for logs', () async {
    final failure = await failureFor((_) => errorBody(502, 'UPSTREAM_ERROR'));

    expect(failure, isA<ServerFailure>());
    expect((failure! as ServerFailure).code, 'UPSTREAM_ERROR');
  });

  test('maps Dio timeouts and connection errors', () async {
    for (final (type, expected) in [
      (DioExceptionType.connectionTimeout, isA<TimeoutFailure>()),
      (DioExceptionType.receiveTimeout, isA<TimeoutFailure>()),
      (DioExceptionType.connectionError, isA<NetworkFailure>()),
      (DioExceptionType.unknown, isA<NetworkFailure>()),
    ]) {
      final failure = await failureFor(
        (options) => throw DioException(requestOptions: options, type: type),
      );
      expect(failure, expected, reason: type.name);
    }
  });

  test('rejects a body that is not a JSON object', () async {
    final failure = await failureFor(
      (_) => jsonResponse(200, ['not', 'an', 'object']),
    );

    expect(failure, isA<ServerFailure>());
    expect((failure! as ServerFailure).code, 'MALFORMED_RESPONSE');
  });

  test('parse turns unexpected shapes into ServerFailure', () {
    expect(
      () => ApiClient.parse(() => ({'a': 1} as Map)['missing'] as String),
      throwsA(isA<ServerFailure>()),
    );
  });
}
