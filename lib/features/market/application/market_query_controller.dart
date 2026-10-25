import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/market_query.dart';

/// How long typing must pause before a search request is sent.
/// A provider so tests can shorten it.
final searchDebounceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 350),
);

/// Holds the current search text, sort and filters for the market list.
///
/// The market list watches this provider, so every accepted change reloads
/// the list from page 1. Two things keep requests to a minimum:
///  * search text is debounced, so typing "bitcoin" sends one request,
///    not seven;
///  * an update that produces an equal query (e.g. adding a trailing
///    space) is ignored, because [MarketQuery] compares by value.
class MarketQueryController extends Notifier<MarketQuery> {
  Timer? _searchDebounce;

  @override
  MarketQuery build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return const MarketQuery();
  }

  /// Called on every keystroke; applies the text once typing pauses.
  void updateSearch(String text) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      ref.read(searchDebounceProvider),
      () => _apply(state.copyWith(search: text)),
    );
  }

  /// Applies the text immediately, e.g. when the keyboard's search key is
  /// pressed or the field is cleared.
  void submitSearch(String text) {
    _searchDebounce?.cancel();
    _apply(state.copyWith(search: text));
  }

  void setSort(MarketSort sort) => _apply(state.copyWith(sort: sort));

  /// Tapping the active movement chip again turns the filter off.
  void toggleMovement(MarketMovement movement) {
    final next = state.movement == movement ? MarketMovement.all : movement;
    _apply(state.copyWith(movement: next));
  }

  /// Tapping the active tier chip again turns the filter off.
  void toggleTier(MarketCapTier tier) {
    final next = state.tier == tier ? MarketCapTier.all : tier;
    _apply(state.copyWith(tier: next));
  }

  /// Clears search and filters but keeps the chosen sort order.
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
