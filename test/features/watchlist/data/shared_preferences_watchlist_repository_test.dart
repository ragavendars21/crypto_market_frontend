import 'package:crypto_market/features/watchlist/data/shared_preferences_watchlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns an empty list on first launch', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SharedPreferencesWatchlistRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.loadIds(), isEmpty);
  });

  test('saved IDs are read back in the same order', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await SharedPreferencesWatchlistRepository(preferences)
        .saveIds(['solana', 'bitcoin']);

    expect(SharedPreferencesWatchlistRepository(preferences).loadIds(), [
      'solana',
      'bitcoin',
    ]);
  });

  test('reads IDs saved by an earlier session', () async {
    SharedPreferences.setMockInitialValues({
      'watchlist_coin_ids': ['ethereum'],
    });

    final repository = SharedPreferencesWatchlistRepository(
      await SharedPreferences.getInstance(),
    );

    expect(repository.loadIds(), ['ethereum']);
  });
}
