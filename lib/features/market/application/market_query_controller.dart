import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/market_query.dart';

/// Holds the current search text, sort and filters for the market list.
///
/// The market list watches this provider, so changing any value here
/// automatically reloads the list from page 1.
class MarketQueryController extends Notifier<MarketQuery> {
  @override
  MarketQuery build() => const MarketQuery();
}

final marketQueryProvider =
    NotifierProvider<MarketQueryController, MarketQuery>(
      MarketQueryController.new,
    );
