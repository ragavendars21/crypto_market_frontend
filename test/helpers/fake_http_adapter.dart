import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_market/core/network/api_client.dart';
import 'package:dio/dio.dart';

class FakeHttpAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

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

ApiClient apiClientWith(FakeHttpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api/v1'))
    ..httpClientAdapter = adapter;
  return ApiClient(dio);
}
