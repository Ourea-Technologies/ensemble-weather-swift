# ``EnsembleWeather``

The official Swift SDK for the Ourea probabilistic weather API.

## Overview

[Ourea](https://oureawx.com) forecasts are ensembles: every value is a distribution computed from
every member of up to five weather models. This SDK carries those
distributions to your app and asks the server for probabilities, so you never
compute statistics yourself.

```swift
import EnsembleWeather

let client = EnsembleWeatherClient()   // anonymous, or OUREA_API_KEY
let sixInches = ProbabilityQuery.snowfall(atLeast: .inches(6))
let forecast = try await client.forecast(
    for: "or/mt-hood-meadows",
    options: ForecastOptions(probabilities: [sixInches]))

if let chance = forecast.probability(for: sixInches)?.probability {
    print("Chance of 6 in of snow in 24 h: \(chance.formatted(.percent))")
}
```

The SDK targets API contract v1. Guides live at
<https://docs.oureawx.com/swift>.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Probabilities>
- ``EnsembleWeatherClient``
- ``EnsembleWeatherClient/Configuration``
- ``APIResponse``
- ``ResponseMetadata``

### Asking for probabilities and totals

- ``ForecastOptions``
- ``ProbabilityQuery``
- ``WindowTotalQuery``
- ``Threshold``
- ``ForecastWindow``

### Forecast models

- ``ForecastResponse``
- ``ForecastData``
- ``TimeSeriesPoint``
- ``DailyForecast``
- ``Quantiles``
- ``QuantileRange``
- ``QuantileInterval``
- ``ProbabilityResult``
- ``WindowTotal``
- ``NullReason``
- ``EnsembleStats``
- ``CircularStats``
- ``Sector``

### Locations and the catalog

- ``LocationID``
- ``LocationReference``
- ``LocationSummary``
- ``LocationSearchResults``
- ``CatalogLocation``
- ``CatalogStation``
- ``PageSequence``

### Errors, retries and rate limits

- ``EnsembleWeatherError``
- ``ErrorCode``
- ``NearestLocation``
- ``RateLimit``
- ``DeprecationNotice``
- ``DeprecationReporter``

### Customising transport and caching

- ``HTTPTransport``
- ``URLSessionTransport``
- ``HTTPRequest``
- ``HTTPResponse``
- ``HTTPHeaders``
- ``RetryClock``
- ``SystemRetryClock``
- ``ResponseCache``
- ``MemoryResponseCache``
- ``CachedResponse``
