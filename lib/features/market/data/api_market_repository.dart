import '../../../core/network/api_client.dart';
import '../domain/coin_page.dart';
import '../domain/coin_summary.dart';
import '../domain/market_query.dart';
import '../domain/market_repository.dart';
import 'dtos/coin_summary_dto.dart';

/// [MarketRepository] backed by our Node.js backend (`GET /coins`).
///
/// Search, filters and sorting are sent to the server, which applies them
/// to its cached top-250 list (see docs/api-contract.md).
class ApiMarketRepository implements MarketRepository {
  ApiMarketRepository(this._client);

  final ApiClient _client;

  @override
  Future<CoinPage> getCoins({
    required MarketQuery query,
    int page = 1,
    int perPage = MarketRepository.defaultPageSize,
  }) async {
    final json = await _client.get(
      '/coins',
      queryParameters: {
        'page': page,
        'perPage': perPage,
        'sort': query.sort.apiValue,
        'movement': query.movement.apiValue,
        'tier': query.tier.apiValue,
        // The backend rejects an empty search, so only send real text.
        if (query.trimmedSearch.isNotEmpty) 'search': query.trimmedSearch,
      },
    );
    return ApiClient.parse(() => CoinPageResponseDto.fromJson(json).toDomain());
  }

  @override
  Future<List<CoinSummary>> getCoinsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];

    final json = await _client.get(
      '/coins',
      queryParameters: {'ids': ids.join(',')},
    );
    return ApiClient.parse(
      () => (json['data'] as List<dynamic>)
          .map((item) => CoinSummaryDto.fromJson(item as Map<String, dynamic>))
          .map((dto) => dto.toDomain())
          .toList(),
    );
  }
}
