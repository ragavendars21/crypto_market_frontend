import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/coin_details/presentation/coin_details_screen.dart';
import '../../features/market/presentation/market_screen.dart';
import '../../features/market_stats/presentation/market_stats_screen.dart';
import '../../features/watchlist/presentation/watchlist_screen.dart';
import 'app_shell.dart';

/// Route paths in one place, so screens never hardcode URL strings.
abstract final class AppRoutes {
  static const markets = '/markets';
  static const watchlist = '/watchlist';
  static const global = '/global';

  static String coinDetails(String coinId) => '/coins/$coinId';
}

/// The router is a provider so tests can read or override it, and so it is
/// created once and disposed with the [ProviderScope].
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.markets,
    routes: [
      // Each branch is a bottom-navigation tab. `indexedStack` keeps every
      // tab alive, so scroll position and state survive tab switches.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.markets,
                builder: (_, _) => const MarketScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.watchlist,
                builder: (_, _) => const WatchlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.global,
                builder: (_, _) => const MarketStatsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Outside the shell: opens full screen over the tabs, and works as a
      // deep link (e.g. /coins/bitcoin) because it only needs the ID.
      GoRoute(
        path: '/coins/:coinId',
        builder: (_, state) =>
            CoinDetailsScreen(coinId: state.pathParameters['coinId']!),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
