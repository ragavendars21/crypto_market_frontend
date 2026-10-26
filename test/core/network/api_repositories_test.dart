import 'package:crypto_market/core/errors/app_failure.dart';
import 'package:crypto_market/features/coin_details/data/api_coin_details_repository.dart';
import 'package:crypto_market/features/coin_details/domain/price_history.dart';
import 'package:crypto_market/features/market/data/api_market_repository.dart';
import 'package:crypto_market/features/market/domain/market_query.dart';
import 'package:crypto_market/features/market_stats/data/api_market_stats_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

const _bitcoin = {
  'id': 'bitcoin',
  'symbol': 'btc',
  'name': 'Bitcoin',
  'priceUsd': 80320,
  'marketCapRank': 1,
};

void main() {
  late FakeHttpAdapter adapter;

  setUp(() => adapter = FakeHttpAdapter());

  group('ApiMarketRepository', () {
    test('sends the query as backend parameters and parses the page', () async {
      adapter.handler = (_) => jsonResponse(200, {
        'data': [_bitcoin],
        'meta': {
          'source': 'live',
          'page': 2,
          'perPage': 20,
          'totalItems': 250,
          'totalPages': 13,
          'hasNextPage': true,
        },
      });
      final repository = ApiMarketRepository(apiClientWith(adapter));

      final page = await repository.getCoins(
        query: const MarketQuery(
          search: ' btc ',
          sort: MarketSort.priceDesc,
          movement: MarketMovement.gainers,
          tier: MarketCapTier.large,
        ),
        page: 2,
      );

      final request = adapter.requests.single;
      expect(request.path, '/coins');
      expect(request.queryParameters, {
        'page': 2,
        'perPage': 20,
        'sort': 'price_desc',
        'movement': 'gainers',
        'tier': 'large',
        'search': 'btc',
      });
      expect(page.coins.single.priceUsd, 80320.0);
      expect(page.hasNextPage, isTrue);
    });

    test('omits an empty search, which the backend would reject', () async {
      adapter.handler = (_) => jsonResponse(200, {
        'data': <Object>[],
        'meta': {
          'source': 'live',
          'page': 1,
          'perPage': 20,
          'totalItems': 0,
          'totalPages': 0,
          'hasNextPage': false,
        },
      });

      await ApiMarketRepository(apiClientWith(adapter))
          .getCoins(query: const MarketQuery(search: '   '));

      expect(
        adapter.requests.single.queryParameters,
        isNot(contains('search')),
      );
    });

    test('looks up watchlist coins with the ids parameter only', () async {
      adapter.handler = (_) => jsonResponse(200, {
        'data': [_bitcoin],
        'meta': {'source': 'live'},
      });

      final coins = await ApiMarketRepository(apiClientWith(adapter))
          .getCoinsByIds(['bitcoin', 'solana']);

      expect(adapter.requests.single.queryParameters, {
        'ids': 'bitcoin,solana',
      });
      expect(coins.single.id, 'bitcoin');
    });

    test('makes no request for an empty watchlist', () async {
      final coins = await ApiMarketRepository(apiClientWith(adapter))
          .getCoinsByIds([]);

      expect(coins, isEmpty);
      expect(adapter.requests, isEmpty);
    });

    test('a response missing required fields becomes a ServerFailure', () {
      adapter.handler = (_) => jsonResponse(200, {
        'data': [
          {'symbol': 'btc'},
        ],
        'meta': {'source': 'live'},
      });

      expect(
        ApiMarketRepository(apiClientWith(adapter)).getCoinsByIds(['x']),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('ApiCoinDetailsRepository', () {
    test('requests details and maps a 404 to NotFoundFailure', () async {
      adapter.handler = (_) => jsonResponse(404, {
        'error': {'code': 'COIN_NOT_FOUND', 'message': 'No coin.'},
      });

      await expectLater(
        ApiCoinDetailsRepository(apiClientWith(adapter)).getCoinDetails('nope'),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(adapter.requests.single.path, '/coins/nope');
    });

    test('requests the chart range and parses points', () async {
      adapter.handler = (_) => jsonResponse(200, {
        'data': {
          'coinId': 'bitcoin',
          'range': '30d',
          'granularity': 'hourly',
          'points': [
            {'timestamp': 1000, 'priceUsd': 1},
            {'timestamp': 2000, 'priceUsd': 2},
          ],
        },
        'meta': {'source': 'live'},
      });

      final history = await ApiCoinDetailsRepository(apiClientWith(adapter))
          .getPriceHistory('bitcoin', ChartRange.month);

      expect(adapter.requests.single.path, '/coins/bitcoin/market-chart');
      expect(adapter.requests.single.queryParameters, {'range': '30d'});
      expect(history.changePercentage, closeTo(100, 0.001));
    });
  });

  test('ApiMarketStatsRepository parses global statistics', () async {
    adapter.handler = (_) => jsonResponse(200, {
      'data': {
        'totalMarketCapUsd': 2.68e12,
        'dominance': [
          {'symbol': 'btc', 'percentage': 60.1},
        ],
      },
      'meta': {'source': 'live'},
    });

    final stats = await ApiMarketStatsRepository(apiClientWith(adapter))
        .getGlobalStats();

    expect(adapter.requests.single.path, '/market/global');
    expect(stats.bitcoinDominance, 60.1);
  });
}
