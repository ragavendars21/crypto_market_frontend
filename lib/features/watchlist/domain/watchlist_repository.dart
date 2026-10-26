/// Stores the IDs of the coins the user follows.
///
/// Only IDs are saved, never prices: prices go stale, so they are always
/// fetched fresh when the watchlist is shown.
abstract interface class WatchlistRepository {
  /// Matches the backend's limit for `GET /coins?ids=`.
  static const int maxCoins = 50;

  /// Saved IDs in the order they were added. Synchronous because the store
  /// is loaded into memory once when the app starts.
  List<String> loadIds();

  Future<void> saveIds(List<String> ids);
}
