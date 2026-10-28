# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

The v1 contract as deployed on api.oureawx.com (KAN-1561): pinned spec
`8b85fea`, the server's public spec byte for byte. Breaking for callers of
the removed and renamed members below.

### Removed

- `stormReports(limit:)`, `stormReport(id:)`, `StormReportList` and
  `StormReport`: `/api/v1/storm-reports` is not in the public API.
- The catalog's `ads` (`CatalogExtra.ads`, `CatalogResolvedAdSlot` and its
  placement types): not in the public API.
- `ForecastDiagnostic.ptype`, `EnsembleStats.precipitationTypeCode`,
  `FeelsLikeIndex.utci`, `EnsembleStats.feelsLikeUTCI`,
  `DailyForecast.feelsLikeUTCIHigh`/`Low`, `EnsembleStats.windDirectionCircular`,
  `ElevationForecast.timeseries`/`isDefault` and `ElevationHour`: withdrawn
  by the server.
- `ErrorCode.forbidden`, `.modelRunNotFound`, `.gone`, `.invalidMaxHours`,
  `.ambiguous` and `.feelsLikeUnavailable`: not public codes (an unknown code
  still keeps its string and maps by HTTP status).

### Changed

- `EnsembleStats.windDirection` and `ModelMean.windDirection` are
  `CircularStats` (mean, standard deviation, 50 % and 90 % sectors), not
  `Quantiles`.
- Probability and window-total answers are matched to the caller's terms by
  the canonical `term` the server echoes, never by position.
- The `precip_*` wire names are `precipitation_*` (daily, hourly, current,
  sensor and threshold fields); the Swift property names were already
  spelled out and are unchanged.
- `LocationReference.slug` and `.type` are optional: `nil` on a point
  forecast.
- `CurrentConditions.conditionIcon` is a `ConditionIcon`;
  `ConditionsStation` gains `stationID`; `ActiveAlert` gains `certainty`, and
  its `severity` and `urgency` are snake_case.
- `AvailableRuns.served` is optional; `availableRuns(limit:cursor:)` pages
  with `nextCursor`.
- Comma lists (`sources`, `elevations`, `network`, `capability`, ...) are
  sent sorted and de-duplicated, and `capability` as one comma list, the
  server's canonical form. Catalog `network`, `status` and `template`
  values are snake_case (`snotel`, `active`, `mountain`).
- `OUTSIDE_COVERAGE` is a 404; `Retry-After` is honoured on 504 as well as
  429 and 503.

### Added

- `EnsembleWeatherError.docURL`, `.parameter` and `.nearestLocation`;
  `requestID` is read from the error body, else `X-Request-Id`.
  `ErrorCode.authUnavailable` (an unavailable error).
- `ProbabilityResult.term`/`.nullReason`, `WindowTotal.term`/`.aggregation`/
  `.nullReason`, `NullReason`, `WindowTotalAggregation`.
- `ForecastOptions.extraVariables` (`include=skin_temperature,mslp`):
  `skinTemperature` and `meanSeaLevelPressure` are served only when asked.
- Four night `ConditionIcon` cases (`nightMoonShowers`, `nightChanceRain`,
  `nightRainLikely`, `nightShowers`).

## [0.1.0] - 2026-10-26

### Added

- `EnsembleWeatherClient` for every v1 operation except `getMapsToken`:
  location and point forecasts, current conditions, alerts, nearby
  locations, search, location lists, the location and station catalog
  (pages and lazy `PageSequence`s), model runs, storm reports and
  attribution.
- `ProbabilityQuery` (`prob=`) and `WindowTotalQuery` (`totals=`), with
  exact threshold unit conversion and the server's rounding; answers in the
  caller's order.
- Canonical URLs, keyless open routes, same-host redirects (the key is
  dropped across hosts), retries with `Retry-After` or full jitter, an
  in-memory `ETag` cache, deprecation notices and typed
  `EnsembleWeatherError`s.
- Hand-written `Sendable`, `Codable`, `Hashable` models for every schema the
  operations reach; unknown enum values keep their raw string.
- Pinned spec `12e904b`; all 43 shared vectors pass.

[Unreleased]: https://github.com/Ourea-Technologies/ensemble-weather-swift/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Ourea-Technologies/ensemble-weather-swift/releases/tag/v0.1.0
