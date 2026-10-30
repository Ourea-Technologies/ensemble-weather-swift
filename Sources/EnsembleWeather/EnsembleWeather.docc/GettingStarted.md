# Getting started

Make a first forecast call, add an API key, and handle errors.

## Add the package

```swift
.package(url: "https://github.com/Ourea-Technologies/ensemble-weather-swift", from: "0.1.0")
```

and add `"EnsembleWeather"` to your target's dependencies.

## Call anonymously

Forecasts, current conditions and alerts for named locations work without a
key, at the Free tier:

```swift
let client = EnsembleWeatherClient()
let forecast = try await client.forecast(for: "or/mt-hood-meadows")
for hour in forecast.forecast.timeseries ?? [] {
    print(hour.validTime, hour.ensemble.temperature.range(.p10ToP90) as Any)
}
```

## Add a key

Pass it to the client, or set `OUREA_API_KEY` in the environment. A Pro key
unlocks forecasts at any coordinates, 15 days, per-model data and every
member variable. See <https://oureawx.com/pricing>.

```swift
let client = EnsembleWeatherClient(apiKey: "ow_...")
let point = try await client.getPointForecast(latitude: 45.3311, longitude: -121.6649, elevationMeters: 1661)
```

Search, catalog detail and attribution are sent without the key even when
the client has one, so the edge cache can share them between all callers.
Set ``EnsembleWeatherClient/Configuration/sendsKeyOnOpenRoutes`` to change that.

## Handle errors

Every call throws ``EnsembleWeatherError``. Switch on its
``EnsembleWeatherError/category``, or compare its ``EnsembleWeatherError/code``:

```swift
do {
    _ = try await client.getPointForecast(latitude: 51.5, longitude: -0.1)
} catch let error as EnsembleWeatherError where error.code == .outsideCoverage {
    print(error.message)
}
```

Connection errors, 429, 502, 503 and 504 are retried (twice by default) with
`Retry-After` or full-jitter backoff. Read the rate-limit state from
``ResponseMetadata/rateLimit`` or ``EnsembleWeatherClient/rateLimit``.

## Caching

The client keeps an in-memory `ETag` cache (256 entries, 32 MiB) and
revalidates with `If-None-Match`; a `304` returns the cached body with
``ResponseMetadata/cacheStatus`` set to
``ResponseMetadata/CacheStatus/revalidated``. Pass your own
``ResponseCache``, or `nil` to turn caching off.
