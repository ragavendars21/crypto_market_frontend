# Crypto Market — Flutter App

[![CI](https://github.com/ragavendars21/crypto_market_frontend/actions/workflows/ci.yml/badge.svg)](https://github.com/ragavendars21/crypto_market_frontend/actions/workflows/ci.yml)

A CoinGecko-style crypto research app built with Flutter: live market list with server-side search,
filters and sorting, coin details with interactive price charts, global market statistics and a
persistent watchlist.

It talks only to its own [Node.js backend](https://github.com/ragavendars21/crypto_market_backend),
which holds the CoinGecko API key, caches responses and returns a small, stable JSON contract.
Data provided by CoinGecko.

| | |
|---|---|
| **Architecture** | Feature-first layers: presentation → application (Riverpod) → domain ← data |
| **State** | Riverpod 3 (`Notifier`, `AsyncNotifier`, `family`, `select`) |
| **Networking** | Dio, with every error mapped to a typed `AppFailure` |
| **Navigation** | GoRouter with a stateful bottom-navigation shell and deep links (`/coins/bitcoin`) |
| **Charts** | fl_chart line chart; dominance shown as a stacked bar |
| **Storage** | SharedPreferences for the watchlist |
| **Tests** | 160 unit, widget and accessibility tests, no network needed |

Docs: [architecture](docs/architecture.md) · [API contract](docs/api-contract.md)

## Run it

Requires Flutter 3.47 (Dart 3.13).

```bash
flutter pub get
```

**With live data** (default) — start the backend first (`npm run dev` in the backend repo, with a
CoinGecko Demo key in its `.env`), then:

```bash
flutter run                      # emulator / simulator: finds the backend automatically
```

| Where the app runs | Backend URL used |
|---|---|
| Android emulator | `http://10.0.2.2:3000/api/v1` (automatic) |
| iOS simulator, web, desktop | `http://localhost:3000/api/v1` (automatic) |
| Physical phone (same Wi-Fi) | `flutter run --dart-define=API_BASE_URL=http://<your-PC-IP>:3000/api/v1` |

**Offline with sample data** — no backend or key needed:

```bash
flutter run --dart-define=DATA_SOURCE=mock
```

VS Code users can pick these from the Run panel (see `.vscode/launch.json`).

## Develop

```bash
dart format lib test        # format
flutter analyze             # static analysis (strict mode)
flutter test                # all tests
dart run build_runner build # regenerate JSON parsing code after editing a DTO
```

## Project structure

```text
lib/
├── main.dart, app.dart         Bootstrap, theme, router
├── core/                       Config, DI (repository providers), network, errors, routing, theme
├── shared/                     Reusable widgets and formatters
└── features/
    ├── market/                 Market list, search, sort, filters
    ├── coin_details/           Details screen and price chart
    ├── market_stats/           Global statistics
    └── watchlist/              Saved coins
```

Each feature has `domain/` (entities, repository interfaces), `data/` (DTOs, API and mock
repositories), `application/` (Riverpod providers) and `presentation/` (screens and widgets).

## Troubleshooting

| Problem | Fix |
|---|---|
| "You appear to be offline" in live mode | Is the backend running? `GET http://localhost:3000/api/v1/health` should answer. On a physical phone, pass your PC's IP and allow port 3000 through the Windows firewall. |
| Health says `"dataSource": "mock"` | Start the backend with `npm run dev` / `npm start`, not `node src/server.js` (that skips `.env`). |
| Android: `Could not close incremental caches` | Run `flutter clean`. Kotlin incremental builds are already disabled in `android/gradle.properties` because the project and the pub cache are on different drives. |
| Emulator listed as `offline` | Cold boot it from Android Studio's Device Manager. |
