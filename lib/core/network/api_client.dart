import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';

/// Thin wrapper around Dio for our backend.
///
/// Its one job besides sending requests: make sure callers only ever see
/// an [AppFailure], never a `DioException` or a JSON parsing error. That
/// keeps every repository and screen free of HTTP details.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// GETs [path] and returns the decoded JSON body, which is always the
  /// contract's `{ "data": ..., "meta": ... }` envelope.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, Object>? queryParameters,
  }) async {
    final Response<Object?> response;
    try {
      response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }

    final body = response.data;
    if (body is Map<String, dynamic>) return body;
    throw const ServerFailure(code: 'MALFORMED_RESPONSE');
  }

  /// Runs [parse] on a response, turning any parsing error into a
  /// [ServerFailure] instead of letting a `TypeError` reach the UI.
  static T parse<T>(T Function() parse) {
    try {
      return parse();
    } on AppFailure {
      rethrow;
    } catch (error) {
      debugPrint('Could not parse API response: $error');
      throw const ServerFailure(code: 'MALFORMED_RESPONSE');
    }
  }
}

/// Translates a Dio error into the failure the UI knows how to show.
AppFailure mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      return _mapErrorResponse(error.response);
    case DioExceptionType.badCertificate:
      return const NetworkFailure();
    case DioExceptionType.cancel:
      return const ServerFailure(code: 'CANCELLED');
    case DioExceptionType.unknown:
      // No response at all usually means a low-level socket error (no
      // usable network); with a response, something failed on our side.
      return error.response == null
          ? const NetworkFailure()
          : const ServerFailure();
  }
}

/// Reads the backend's `{ "error": { "code": ... } }` body.
AppFailure _mapErrorResponse(Response<Object?>? response) {
  final body = response?.data;
  final code = body is Map<String, dynamic> && body['error'] is Map
      ? (body['error'] as Map)['code'] as String?
      : null;

  return switch (code) {
    'COIN_NOT_FOUND' => const NotFoundFailure(),
    'RATE_LIMITED' || 'UPSTREAM_RATE_LIMITED' => RateLimitedFailure(
      retryAfter: _retryAfter(response),
    ),
    'UPSTREAM_TIMEOUT' => const TimeoutFailure(),
    _ when response?.statusCode == 429 => RateLimitedFailure(
      retryAfter: _retryAfter(response),
    ),
    _ => ServerFailure(code: code ?? 'HTTP_${response?.statusCode}'),
  };
}

Duration? _retryAfter(Response<Object?>? response) {
  final seconds = int.tryParse(response?.headers.value('retry-after') ?? '');
  return seconds == null ? null : Duration(seconds: seconds);
}

/// Dio configured for our backend. A provider so tests can swap the
/// transport and so there is exactly one instance in the app.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      // The backend may wait up to ~8 s for CoinGecko (plus one retry).
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ),
  );

  if (kDebugMode) {
    // Request lines and status codes only: bodies are large and noisy.
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        responseBody: false,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }

  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
