# ensemble-weather-swift

Official Swift SDK for the [Ourea](https://oureawx.com) probabilistic weather API.

[![CI](https://github.com/Ourea-Technologies/ensemble-weather-swift/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Ourea-Technologies/ensemble-weather-swift/actions/workflows/ci.yml?query=branch%3Amain)
[![Security](https://github.com/Ourea-Technologies/ensemble-weather-swift/actions/workflows/security.yml/badge.svg?branch=main)](https://github.com/Ourea-Technologies/ensemble-weather-swift/actions/workflows/security.yml?query=branch%3Amain)
[![Version](https://img.shields.io/github/v/tag/Ourea-Technologies/ensemble-weather-swift?label=version&sort=semver)](https://swiftpackageindex.com/Ourea-Technologies/ensemble-weather-swift)
[![Swift versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOurea-Technologies%2Fensemble-weather-swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Ourea-Technologies/ensemble-weather-swift)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FOurea-Technologies%2Fensemble-weather-swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Ourea-Technologies/ensemble-weather-swift)
[![License: BSD-2-Clause](https://img.shields.io/badge/license-BSD--2--Clause-blue.svg)](LICENSE)
[![Docs](https://img.shields.io/badge/docs-docs.oureawx.com-informational)](https://docs.oureawx.com/swift)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/Ourea-Technologies/ensemble-weather-swift/badge)](https://securityscorecards.dev/viewer/?uri=github.com/Ourea-Technologies/ensemble-weather-swift)

Every Ourea forecast is an ensemble: up to five weather models, every member,
every hour, served as a full distribution. This SDK targets the v1 API
contract and works on iOS 15, macOS 12, tvOS 15, watchOS 8 and Linux, with no
dependencies.

## Install

Add the package to `Package.swift` (or File > Add Package Dependencies in Xcode):

```swift
.package(url: "https://github.com/Ourea-Technologies/ensemble-weather-swift", from: "0.1.0")
```

and `.product(name: "EnsembleWeather", package: "ensemble-weather-swift")` to your target.

## Quickstart

An anonymous forecast for Mt. Hood Meadows: the next 24 hours' temperature as
a range, and the chance of at least 6 in (15 cm) of snow. No signup, no key.

```swift
import EnsembleWeather

let client = EnsembleWeatherClient()
let sixInches = ProbabilityQuery.snowfall(atLeast: .inches(6))

let forecast = try await client.forecast(
    for: "or/mt-hood-meadows",
    options: ForecastOptions(probabilities: [sixInches]))

print("\(forecast.location.name), temperature over the next 24 h (p10 to p90):")
for hour in forecast.forecast.timeseries ?? [] {
    if let range = hour.ensemble.temperature.range(.p10ToP90) {
        let unit = forecast.units.temperatureUnit
        print(
            "  \(hour.validTime.formatted(date: .omitted, time: .shortened))  \(range.lower)\(unit) to \(range.upper)\(unit)"
        )
    }
}

if let snow = forecast.probability(for: sixInches), let chance = snow.probability {
    print(
        "Chance of at least 6 in of snow in the next 24 h: \(chance.formatted(.percent)) (\(snow.members) members)"
    )
}
```

This is [`examples/Sources/Quickstart/main.swift`](examples/Sources/Quickstart/main.swift);
run it with `swift run --package-path examples Quickstart`.

## Authentication

Without a key, calls are anonymous at the Free tier: named-location
forecasts, current conditions and alerts, 10 days ahead, the latest run, and
members as the plume view. A Pro key adds forecasts at any coordinates, 15
days, per-model data, historical runs and every member variable. See
[pricing](https://oureawx.com/pricing).

```swift
let client = EnsembleWeatherClient(apiKey: "ow_...")   // or set OUREA_API_KEY
```

With no `apiKey`, the client reads `OUREA_API_KEY` from the environment. The
key is sent as `X-API-Key`, never logged, never in an error, and never sent to
another host on a redirect. Search, catalog detail and attribution are sent
without the key even when the client has one, so every caller shares the edge
cache; set `Configuration.sendsKeyOnOpenRoutes` to send it anyway.

## Probabilities, not single numbers

The server computes every probability and total from the full ensemble. The
SDK never sums, averages or interpolates quantiles, because summing hourly
quantiles gives a wrong storm total. Ask the server instead
([how probabilities work](https://docs.oureawx.com/concepts/probabilities)).

The chance of an event (`prob=`), answered with its window and member count:

```swift
let freeze = ProbabilityQuery.temperature(atMost: .fahrenheit(32), in: .hours(48), aggregation: .all)
let forecast = try await client.forecast(
    for: "or/mt-hood-meadows", options: ForecastOptions(probabilities: [freeze]))
if let answer = forecast.probability(for: freeze) {
    print(answer.probability as Any, answer.members)   // nil, with answer.nullReason, when unanswered
}
```

A storm total (`totals=`), the distribution of each member's own total:

```swift
let storm = try await client.forecast(
    for: "or/mt-hood-meadows", options: ForecastOptions(windowTotals: [.snowfall(in: .hours(72))]))
let range = storm.windowTotals.first?.quantiles?.range(.p10ToP90)
```

Quantiles, the shape of every value:

```swift
let hour = forecast.forecast.timeseries?.first
let likely = hour?.ensemble.temperature.range(.p10ToP90)   // only served pairs
let median = hour?.ensemble.temperature.median             // the median, not "the forecast"
```

Thresholds with a unit (`.inches(6)`, `.fahrenheit(32)`) are converted to the
request's units with exact factors; response values are never converted, so
ask for `ForecastOptions(units: .imperial)` to get imperial values.

## More examples

| Example | Shows |
|---|---|
| [`Quickstart`](examples/Sources/Quickstart/main.swift) | the program above, anonymous |
| [`PointForecast`](examples/Sources/PointForecast/main.swift) | a forecast at coordinates with elevation (Pro key from `OUREA_API_KEY`) |
| [`ChanceOfSnow`](examples/Sources/ChanceOfSnow/main.swift) | several `prob` terms in one call, with their windows and member counts |
| [`StormTotal`](examples/Sources/StormTotal/main.swift) | `totals` window distributions for precipitation and snowfall |
| [`SearchAndCatalog`](examples/Sources/SearchAndCatalog/main.swift) | search, then page through the catalog with the cursor |
| [`CurrentAndAlerts`](examples/Sources/CurrentAndAlerts/main.swift) | current conditions and active alerts for a location |
| [`ErrorHandling`](examples/Sources/ErrorHandling/main.swift) | catching an out-of-coverage error by its code; reading rate-limit state |
| [`Units`](examples/Sources/Units/main.swift) | the same forecast in metric and imperial |

`scripts/run-examples` runs them all against a local mock of the API.

## Errors, retries and rate limits

Every call throws `EnsembleWeatherError` (or `CancellationError`). It carries
`category` (`.authentication`, `.permission`, `.notFound`, `.invalidRequest`,
`.outsideCoverage`, `.rateLimited`, `.unavailable`, `.connection`, `.usage`,
`.invalidResponse`), the API's `code` verbatim, `status`, `message`,
`requestID`, `docURL` (the code's entry on the docs errors page), `parameter`
(on a 400 about one query parameter), `nearestLocation` (on a `PRO_REQUIRED`
coordinate request: a named location that answers without a key) and, for
429/503/504, `retryAfter`.

```swift
do {
    _ = try await client.forecast(latitude: 51.5, longitude: -0.1)
} catch let error as EnsembleWeatherError where error.code == .outsideCoverage {
    print(error.message)
}
```

Connection errors (except TLS failures), 429, 502, 503 and 504 are retried,
twice by default (`Configuration.maxRetries`), waiting `Retry-After` (up to
60 s; longer is returned as the error) or full-jitter backoff. Nothing else
is retried. Read the rate-limit state from `response.metadata.rateLimit` or
`client.rateLimit`; budgets differ by tier, so never hard-code them.
Responses are revalidated through a local `ETag` cache (on by default).

## Documentation

- Guides: https://docs.oureawx.com
- This SDK's guide: https://docs.oureawx.com/swift
- API reference (DocC): [Swift Package Index](https://swiftpackageindex.com/Ourea-Technologies/ensemble-weather-swift/documentation/ensembleweather), or build it with `scripts/build-docs`
- The OpenAPI contract: [ensemble-weather-spec](https://github.com/Ourea-Technologies/ensemble-weather-spec/blob/main/openapi/v1/openapi.yaml) (pinned copy in [`spec/`](spec/openapi/v1/openapi.yaml))

## Supported versions

CI tests Swift 6.1 and 6.2 on Linux (the official `swift` images) and Swift
6.2 (Xcode 26) on macOS. The package supports iOS 15+, macOS 12+, tvOS 15+,
watchOS 8+ and Linux, in Swift 6 language mode with strict concurrency.

## Contributing, security, licence

- Contributing: see [CONTRIBUTING.md](CONTRIBUTING.md).
- Security: report privately, see [SECURITY.md](SECURITY.md).
- Licence: [BSD-2-Clause](LICENSE), Copyright (c) 2026 Ourea Technologies.
