import '../../../core/network/api_client.dart';
import '../domain/coin_details.dart';
import '../domain/coin_details_repository.dart';
import '../domain/price_history.dart';
import 'dtos/coin_details_dto.dart';
import 'dtos/price_history_dto.dart';

class ApiCoinDetailsRepository implements CoinDetailsRepository {
  ApiCoinDetailsRepository(this._client);

  final ApiClient _client;

  @override
  Future<CoinDetails> getCoinDetails(String coinId) async {
    final json = await _client.get('/coins/${Uri.encodeComponent(coinId)}');
    return ApiClient.parse(
      () =>
          CoinDetailsDto.fromJson(json['data'] as Map<String, dynamic>)
              .toDomain(),
    );
  }

  @override
  Future<PriceHistory> getPriceHistory(String coinId, ChartRange range) async {
    final json = await _client.get(
      '/coins/${Uri.encodeComponent(coinId)}/market-chart',
      queryParameters: {'range': range.apiValue},
    );
    return ApiClient.parse(
      () =>
          PriceHistoryDto.fromJson(json['data'] as Map<String, dynamic>)
              .toDomain(),
    );
  }
}
