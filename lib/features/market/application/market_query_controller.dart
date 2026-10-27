import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/market_query.dart';

final searchDebounceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 350),
);

class MarketQueryController extends Notifier<MarketQuery> {
  Timer? _searchDebounce;

  @override
  MarketQuery build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return const MarketQuery();
  }

  void updateSearch(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      ref.read(searchDebounceProvider),
      () => _apply(state.copyWith(search: text)),
    );
  }

  void submitSearch(String text) {
    _searchDebounce?.cancel();
    _apply(state.copyWith(search: text));
  }

  void setSort(MarketSort sort) => _apply(state.copyWith(sort: sort));

  void toggleMovement(MarketMovement movement) {
    final next = state.movement == movement ? MarketMovement.all : movement;
    _apply(state.copyWith(movement: next));
  }

  void toggleTier(MarketCapTier tier) {
    final next = state.tier == tier ? MarketCapTier.all : tier;
    _apply(state.copyWith(tier: next));
  }

  void clearSearchAndFilters() {
    _searchDebounce?.cancel();
    _apply(MarketQuery(sort: state.sort));
  }

  void _apply(MarketQuery next) {
    if (next == state) return;
    state = next;
  }
}

final marketQueryProvider =
    NotifierProvider<MarketQueryController, MarketQuery>(
      MarketQueryController.new,
    );
