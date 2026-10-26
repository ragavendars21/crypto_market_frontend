import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/repository_providers.dart';
import '../domain/watchlist_repository.dart';

enum WatchlistToggleResult { added, removed, full }

/// The single source of truth for which coins are saved.
///
/// Every star button, the watchlist screen and anything else reads this one
/// provider, so a change made on any screen shows up on every screen.
/// Updates are optimistic: the UI changes immediately, and if saving to the
/// device fails the change is rolled back and the error rethrown.
class WatchlistController extends Notifier<List<String>> {
  WatchlistRepository get _repository => ref.read(watchlistRepositoryProvider);

  @override
  List<String> build() => ref.watch(watchlistRepositoryProvider).loadIds();

  bool contains(String coinId) => state.contains(coinId);

  Future<WatchlistToggleResult> toggle(String coinId) async {
    if (state.contains(coinId)) {
      await remove(coinId);
      return WatchlistToggleResult.removed;
    }
    if (state.length >= WatchlistRepository.maxCoins) {
      return WatchlistToggleResult.full;
    }
    await _update([...state, coinId]);
    return WatchlistToggleResult.added;
  }

  Future<void> remove(String coinId) => _update([...state]..remove(coinId));

  /// Puts a removed coin back at its old position (used by "Undo").
  Future<void> restore(String coinId, int index) async {
    if (state.contains(coinId)) return;
    final ids = [...state]..insert(index.clamp(0, state.length), coinId);
    await _update(ids);
  }

  Future<void> _update(List<String> next) async {
    final previous = state;
    state = List.unmodifiable(next);
    try {
      await _repository.saveIds(state);
    } catch (_) {
      if (ref.mounted) state = previous;
      rethrow;
    }
  }
}

final watchlistProvider = NotifierProvider<WatchlistController, List<String>>(
  WatchlistController.new,
);
