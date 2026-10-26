import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_market/core/network/api_client.dart';
import 'package:dio/dio.dart';

/// Replaces Dio's network transport in tests: returns canned responses and
/// records each request, so the real Dio pipeline (status checks, JSON
/// decoding, error types) runs without a server.
class FakeHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  /// Produces the response for each request; may throw a [DioException].
  ResponseBody Function(RequestOptions options) handler = (_) =>
      jsonResponse(200, {'data': <Object>[]});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(
  int status,
  Object body, {
  Map<String, String> headers = const {},
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      for (final entry in headers.entries) entry.key: [entry.value],
    },
  );
}

/// An [ApiClient] whose Dio uses [adapter] instead of the network.
ApiClient apiClientWith(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiClient(dio);
}
