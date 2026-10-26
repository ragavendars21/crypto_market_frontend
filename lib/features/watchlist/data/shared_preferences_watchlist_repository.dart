import 'package:shared_preferences/shared_preferences.dart';

import '../domain/watchlist_repository.dart';

/// Keeps watchlist IDs in SharedPreferences (a small key-value store on the
/// device), so they survive app restarts.
///
/// SharedPreferences fits because we store one short list of strings. A
/// database (SQLite, Hive) would be overkill until the app needs to store
/// structured or larger data.
class SharedPreferencesWatchlistRepository implements WatchlistRepository {
  SharedPreferencesWatchlistRepository(this._preferences);

  static const _key = 'watchlist_coin_ids';

  final SharedPreferences _preferences;

  @override
  List<String> loadIds() => _preferences.getStringList(_key) ?? const [];

  @override
  Future<void> saveIds(List<String> ids) async {
    final saved = await _preferences.setStringList(_key, ids);
    if (!saved) {
      throw StateError('The watchlist could not be saved on this device.');
    }
  }
}
