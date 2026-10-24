import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope holds every Riverpod provider's state. It is also our
  // dependency-injection container: tests replace providers via `overrides`.
  //
  // Riverpod retries failed providers automatically by default. We turn
  // that off: the user sees the error and decides when to retry, which
  // avoids repeated hidden requests against a rate-limited API.
  runApp(ProviderScope(retry: (_, _) => null, child: const CryptoMarketApp()));
}
