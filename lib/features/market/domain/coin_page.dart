import 'coin_summary.dart';

class CoinPage {
  const CoinPage({
    required this.coins,
    required this.page,
    required this.totalItems,
    required this.hasNextPage,
    this.isStale = false,
  });

  final List<CoinSummary> coins;
  final int page;

  final int totalItems;
  final bool hasNextPage;

  final bool isStale;
}
