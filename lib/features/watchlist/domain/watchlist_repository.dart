abstract interface class WatchlistRepository {
  static const int maxCoins = 50;

  List<String> loadIds();

  Future<void> saveIds(List<String> ids);
}
