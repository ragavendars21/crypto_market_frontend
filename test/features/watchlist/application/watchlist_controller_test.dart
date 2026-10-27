import 'package:crypto_market/core/di/repository_providers.dart';
import 'package:crypto_market/features/watchlist/application/watchlist_controller.dart';
import 'package:crypto_market/features/watchlist/domain/watchlist_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryWatchlistRepository implements WatchlistRepository {
  _MemoryWatchlistRepository([List<String> initial = const []])
    : saved = [...initial];

  List<String> saved;
  bool failSaves = false;

  @override
  List<String> loadIds() => saved;

  @override
  Future<void> saveIds(List<String> ids) async {
    if (failSaves) throw StateError('disk full');
    saved = [...ids];
  }
}

void main() {
  late _MemoryWatchlistRepository repository;
  late ProviderContainer container;

  void createContainer([List<String> initial = const []]) {
    repository = _MemoryWatchlistRepository(initial);
    container = ProviderContainer.test(
      overrides: [watchlistRepositoryProvider.overrideWithValue(repository)],
    );
  }

  WatchlistController controller() =>
      container.read(watchlistProvider.notifier);
  List<String> ids() => container.read(watchlistProvider);

  test('starts with the IDs saved on the device', () {
    createContainer(['bitcoin', 'solana']);

    expect(ids(), ['bitcoin', 'solana']);
  });

  test('toggle adds, then removes, and saves each change', () async {
    createContainer();

    expect(await controller().toggle('bitcoin'), WatchlistToggleResult.added);
    expect(ids(), ['bitcoin']);
    expect(repository.saved, ['bitcoin']);

    expect(await controller().toggle('bitcoin'), WatchlistToggleResult.removed);
    expect(ids(), isEmpty);
    expect(repository.saved, isEmpty);
  });

  test('refuses to grow past the limit', () async {
    createContainer([
      for (var i = 0; i < WatchlistRepository.maxCoins; i++) 'coin-$i',
    ]);

    expect(await controller().toggle('one-more'), WatchlistToggleResult.full);
    expect(ids(), hasLength(WatchlistRepository.maxCoins));
  });

  test('undo restores a coin at its original position', () async {
    createContainer(['bitcoin', 'ethereum', 'solana']);

    await controller().remove('ethereum');
    await controller().restore('ethereum', 1);

    expect(ids(), ['bitcoin', 'ethereum', 'solana']);
    expect(repository.saved, ['bitcoin', 'ethereum', 'solana']);
  });

  test('rolls back and rethrows when saving fails', () async {
    createContainer(['bitcoin']);
    repository.failSaves = true;

    await expectLater(controller().toggle('solana'), throwsStateError);

    expect(ids(), ['bitcoin']);
  });

  test('the exposed list cannot be modified from outside', () async {
    createContainer();
    await controller().toggle('bitcoin');

    expect(() => ids().add('hack'), throwsUnsupportedError);
  });
}
