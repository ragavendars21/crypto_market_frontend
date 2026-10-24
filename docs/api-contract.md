# API Contract — Crypto Market Backend (v1)

This is the contract between the Flutter app (`crypto_market_frontend`) and the Node.js backend
(`D:\backend\crypto_market_backend`). The Flutter app depends **only** on this contract, never on
CoinGecko's raw response format. If the provider changes, only the backend's client/mapper changes.

- Base path: `/api/v1`
- Format: JSON, UTF-8
- Currency: all monetary values are **USD**
- Timestamps: ISO 8601 strings (UTC) in objects; chart points use epoch milliseconds
- Missing data: a value the provider does not supply is returned as `null`. It is **never** replaced
  with `0` or an estimate.

## 1. Response envelope

Every successful response:

```json
{
  "data": { },
  "meta": {
    "source": "live",
    "cachedAt": "2026-10-23T10:15:00.000Z"
  }
}
```

| `meta` field | Type | Description |
|---|---|---|
| `source` | `"live" \| "mock" \| "stale"` | `live` = fresh provider data, `mock` = fixture data, `stale` = provider failed so the last cached copy was served |
| `cachedAt` | string \| null | When the data was fetched from the provider |

Paginated endpoints add pagination fields to `meta` (see `GET /coins`).

Every error response:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid query parameters.",
    "details": [{ "field": "perPage", "message": "Number must be less than or equal to 100" }]
  }
}
```

`details` is only present for validation errors. Messages never contain stack traces, provider
URLs or API keys.

## 2. Error codes

| HTTP | `code` | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | Invalid path or query parameter |
| 404 | `COIN_NOT_FOUND` | Provider does not know the coin ID |
| 404 | `ROUTE_NOT_FOUND` | Unknown endpoint |
| 429 | `RATE_LIMITED` | Client exceeded **our** API rate limit. Includes `Retry-After` header |
| 502 | `UPSTREAM_ERROR` | Provider returned a 5xx error or a malformed response |
| 503 | `UPSTREAM_RATE_LIMITED` | Provider rate limit hit and no cached copy exists. Includes `Retry-After` header |
| 504 | `UPSTREAM_TIMEOUT` | Provider did not respond within the timeout |
| 500 | `INTERNAL_ERROR` | Unexpected server error (details logged server-side only) |

## 3. Endpoints

### 3.1 `GET /api/v1/health`

Confirms that the backend is running. Never calls the provider.

```json
{
  "data": {
    "status": "ok",
    "dataSource": "live",
    "uptimeSeconds": 1234,
    "version": "1.0.0"
  }
}
```

### 3.2 `GET /api/v1/coins` — market listing

**How it works:** the backend fetches the **top 250 coins by market cap** from CoinGecko in one
request and caches it for 60 seconds. Search, filters, sorting and pagination are applied by the
backend to that set. This is necessary because CoinGecko cannot sort by price or price change,
and sorting one small page at a time would give misleading results.

| Query param | Type | Default | Rules |
|---|---|---|---|
| `page` | integer | `1` | ≥ 1 |
| `perPage` | integer | `25` | 1–100 |
| `search` | string | — | Trimmed, 1–50 chars. Case-insensitive match on coin name or symbol |
| `sort` | enum | `market_cap_desc` | `market_cap_desc`, `market_cap_asc`, `price_desc`, `price_asc`, `change_24h_desc`, `change_24h_asc`, `volume_desc`, `volume_asc` |
| `movement` | enum | `all` | `all`, `gainers` (24h change > 0), `losers` (24h change < 0) |
| `tier` | enum | `all` | `all`, `large` (market cap ≥ $10B), `mid` ($1B to < $10B), `small` (< $1B) |
| `ids` | string | — | Comma-separated coin IDs, max 50, each `^[a-z0-9-]+$`. Used by the watchlist |

Rules:

- `ids` cannot be combined with `search`, `movement`, `tier` or `page`. Combining them returns
  `400 VALIDATION_ERROR`. `sort` may be used with `ids`.
- In `ids` mode the backend requests those coins directly from the provider, so watchlist coins
  outside the top 250 still work. Unknown IDs are simply absent from the result.
- Coins with a `null` value for the sort field are always placed last, whichever direction is used.
- Unknown query parameters return `400`.

Example: `GET /api/v1/coins?page=1&perPage=2&sort=change_24h_desc&tier=large`

```json
{
  "data": [
    {
      "id": "solana",
      "symbol": "sol",
      "name": "Solana",
      "imageUrl": "https://coin-images.coingecko.com/coins/images/4128/large/solana.png",
      "marketCapRank": 6,
      "priceUsd": 172.41,
      "priceChange24hUsd": 9.12,
      "priceChangePercentage24h": 5.58,
      "marketCapUsd": 81234567890,
      "totalVolumeUsd": 4123456789,
      "circulatingSupply": 471234567.12,
      "lastUpdated": "2026-10-23T10:14:31.000Z"
    }
  ],
  "meta": {
    "source": "live",
    "cachedAt": "2026-10-23T10:15:00.000Z",
    "page": 1,
    "perPage": 2,
    "totalItems": 14,
    "totalPages": 7,
    "hasNextPage": true,
    "universeSize": 250
  }
}
```

An empty result is still `200` with `"data": []` and `totalItems: 0`.

**Coin summary fields:** every field except `id`, `symbol` and `name` is nullable.

### 3.3 `GET /api/v1/coins/:coinId` — coin details

| Param | Rules |
|---|---|
| `coinId` | `^[a-z0-9-]{1,100}$` (CoinGecko IDs, e.g. `bitcoin`, `usd-coin`) |

```json
{
  "data": {
    "id": "bitcoin",
    "symbol": "btc",
    "name": "Bitcoin",
    "imageUrl": "https://coin-images.coingecko.com/coins/images/1/large/bitcoin.png",
    "marketCapRank": 1,
    "priceUsd": 67012.5,
    "marketCapUsd": 1321000000000,
    "fullyDilutedValuationUsd": 1407000000000,
    "totalVolumeUsd": 31200000000,
    "high24hUsd": 67890.1,
    "low24hUsd": 65900.0,
    "circulatingSupply": 19712345,
    "totalSupply": 21000000,
    "maxSupply": 21000000,
    "priceChangePercentages": {
      "1h": 0.12,
      "24h": 1.85,
      "7d": -2.4,
      "14d": 3.1,
      "30d": 8.9,
      "60d": 12.3,
      "200d": 25.6,
      "1y": 98.7
    },
    "allTimeHigh": { "priceUsd": 73738, "changePercentage": -9.1, "date": "2024-03-14T07:10:36.635Z" },
    "allTimeLow": { "priceUsd": 67.81, "changePercentage": 98700.2, "date": "2013-07-06T00:00:00.000Z" },
    "lastUpdated": "2026-10-23T10:14:31.000Z"
  },
  "meta": { "source": "live", "cachedAt": "2026-10-23T10:15:00.000Z" }
}
```

- Every numeric field is nullable. `maxSupply` is `null` for coins with no supply cap (e.g. Ethereum).
- Each key in `priceChangePercentages` is always present, with `null` when unavailable.
- `allTimeHigh` / `allTimeLow` are `null` if the provider does not supply them.

### 3.4 `GET /api/v1/coins/:coinId/market-chart` — price history

| Param | Rules |
|---|---|
| `coinId` | Same as above |
| `range` | Required. `1d`, `7d`, `30d`, `1y` |

These ranges map to CoinGecko `days=1, 7, 30, 365`. Ranges beyond 365 days are not offered because
the CoinGecko demo plan only provides the past 365 days.

```json
{
  "data": {
    "coinId": "bitcoin",
    "range": "7d",
    "granularity": "hourly",
    "points": [
      { "timestamp": 1760000000000, "priceUsd": 66012.4 },
      { "timestamp": 1760003600000, "priceUsd": 66150.9 }
    ]
  },
  "meta": { "source": "live", "cachedAt": "2026-10-23T10:15:00.000Z" }
}
```

- `granularity` follows the provider's automatic rules: `1d` → `5m`, `7d`/`30d` → `hourly`,
  `1y` → `daily`.
- Points are sorted by `timestamp` ascending. Points with a `null` or non-numeric price are dropped,
  never interpolated.
- `points` can be empty or very short (for example, a newly listed coin). The client must show a
  "not enough data" state when there are fewer than 2 points instead of drawing a line.

### 3.5 `GET /api/v1/market/global` — global statistics

```json
{
  "data": {
    "totalMarketCapUsd": 2410000000000,
    "totalVolumeUsd": 98700000000,
    "marketCapChangePercentage24h": 1.42,
    "volumeChangePercentage24h": -6.3,
    "activeCryptocurrencies": 17321,
    "markets": 1287,
    "dominance": [
      { "symbol": "btc", "percentage": 54.8 },
      { "symbol": "eth", "percentage": 13.2 }
    ],
    "updatedAt": "2026-10-23T10:12:00.000Z"
  },
  "meta": { "source": "live", "cachedAt": "2026-10-23T10:15:00.000Z" }
}
```

- `dominance` is sorted by `percentage` descending and contains what the provider returns
  (usually the top 10). The client may group the remainder as "Others" (100 − sum).
- All numeric fields are nullable.

## 4. Caching (server-side)

| Data | Cache key | TTL |
|---|---|---|
| Top-250 market set | `markets:top250` | 60 s |
| Coins by `ids` | `markets:ids:<sorted ids>` | 60 s |
| Coin details | `coin:<id>` | 60 s |
| Chart `1d` | `chart:<id>:1d` | 2 min |
| Chart `7d`, `30d` | `chart:<id>:<range>` | 10 min |
| Chart `1y` | `chart:<id>:1y` | 1 h |
| Global stats | `global` | 120 s |

Concurrent requests for the same key share one in-flight provider call. If the provider fails and an
expired copy exists, it is served with `meta.source = "stale"`.
