import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/coin_details/presentation/coin_details_screen.dart';
import '../../features/market/presentation/market_screen.dart';
import '../../features/market_stats/presentation/market_stats_screen.dart';
import '../../features/watchlist/presentation/watchlist_screen.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const markets = '/markets';
  static const watchlist = '/watchlist';
  static const global = '/global';

  static String coinDetails(String coinId) => '/coins/$coinId';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.markets,
    routes: [
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
