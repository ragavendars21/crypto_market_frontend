import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/di/repository_providers.dart';

Future<void> main() async {
  // Required before using plugins (SharedPreferences) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  runApp(
    // ProviderScope holds every Riverpod provider's state. It is also our
    // dependency-injection container: tests replace providers via
    // `overrides`, and here it injects the preloaded SharedPreferences.
    //
    // Riverpod retries failed providers automatically by default. We turn
    // that off: the user sees the error and decides when to retry, which
    // avoids repeated hidden requests against a rate-limited API.
    ProviderScope(
      retry: (_, _) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const CryptoMarketApp(),
    ),
  );
}
