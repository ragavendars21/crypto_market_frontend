import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

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
      return error.response == null
          ? const NetworkFailure()
          : const ServerFailure();
  }
}

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

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ),
  );

  if (kDebugMode) {
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
