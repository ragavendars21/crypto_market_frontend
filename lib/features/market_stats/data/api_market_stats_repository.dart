import '../../../core/network/api_client.dart';
import '../domain/global_market_stats.dart';
import '../domain/market_stats_repository.dart';
import 'dtos/global_market_stats_dto.dart';

/// [MarketStatsRepository] backed by our Node.js backend.
class ApiMarketStatsRepository implements MarketStatsRepository {
  ApiMarketStatsRepository(this._client);

  final ApiClient _client;

  @override
  Future<GlobalMarketStats> getGlobalStats() async {
    final json = await _client.get('/market/global');
    return ApiClient.parse(
      () =>
          GlobalMarketStatsDto.fromJson(json['data'] as Map<String, dynamic>)
              .toDomain(),
    );
  }
}
