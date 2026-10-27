import '../../../core/mock/mock_market_data.dart';
import '../domain/global_market_stats.dart';
import '../domain/market_stats_repository.dart';
import 'dtos/global_market_stats_dto.dart';

class MockMarketStatsRepository implements MarketStatsRepository {
  MockMarketStatsRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  @override
  Future<GlobalMarketStats> getGlobalStats() async {
    await Future<void>.delayed(latency);
    return GlobalMarketStatsDto.fromJson(mockGlobalStatsJson).toDomain();
  }
}
