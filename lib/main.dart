import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope holds every Riverpod provider's state. It is also our
  // dependency-injection container: tests replace providers via `overrides`.
  runApp(const ProviderScope(child: CryptoMarketApp()));
}
