# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - Unreleased

The first release: SwiftPM by URL, from the `v0.1.0` tag. Targets the v1
contract at ensemble-weather-spec `7954268` (the server's public spec at
256cd770, byte for byte); all 58 shared vectors pass.

### The client

- `Client` for every v1 operation except `getMapsToken`: location and
  point forecasts, current conditions, alerts, nearby locations, search,
  explore, composition, the season, the snow trend, the snowpack (beta),
  location lists, the location and station catalog (pages and lazy
  `PageSequence`s), model runs, the GeoJSON alert outlines and avalanche
  zones, and attribution.
- The coordinate methods are `getPointForecast`, `getPointCurrent`,
  `getPointAlerts` and `getPointNearby`; the named-location methods are
  `forecast(for:)`, `currentConditions(for:)`, `alerts(for:)` and
  `nearbyLocations(to:)`.
- `ProbabilityQuery` (`prob=`) and `WindowTotalQuery` (`totals=`), with
  exact threshold unit conversion and the server's rounding; answers are
  matched to the caller's terms by the canonical `term` the server echoes,
  never by position.
- Canonical URLs (comma lists sorted, de-duplicated and sent with literal
  commas), keyless open routes, same-host redirects (the key is dropped
  across hosts), retries with `Retry-After` or full jitter, an in-memory
  `ETag` cache, deprecation notices and typed `OureaError`s with `code`,
  `docURL`, `parameter`, `nearestLocation` and `requestID`.
- Hand-written `Sendable`, `Codable`, `Hashable` models for every schema the
  operations reach; unknown enum values keep their raw string.

### Added since the v1 contract of 2026-10-27

- `explorePage(_:...)` and `explore(_:...)`: places ranked by an
  `ExploreMetric` (`.snow5Days`, `.baseDepth`, `.seasonPrecip`, ...), with
  `order` (`RankOrder`), `type`, `state`, `near` (`Coordinate`),
  `radiusKilometers`, elevation bounds, `points` (`ExplorePoints`) and
  cursor paging.
- `season(for:)`, `snowTrend(for:)` (Plus or Pro), `snowpack(for:)` and
  `snowpackPlume(for:)` (beta), `composition()` (an open route, sent without
  the key), and the GeoJSON routes `alertOutlines(classes:boundingBox:)`
  and `avalancheZones()`.
- `searchLocations` takes `sort`, `order`, `near`, `radiusKilometers` and
  `units`; a hit carries `explore` with a metric sort.
- `ForecastOptions.members` (`MemberSelection`: `.excluded`, `.rows` or
  `.plume`) replaces `includesMembers`; the plume view is in
  `ForecastData.plume` (`MemberPlume`), and `MembersView.pool` is new.
- `near` and `bbox` are typed (`Coordinate`, `BoundingBox`), sent with the
  shortest decimals and literal commas; an out-of-range value, or a box with
  west > east or south > north, is a usage error.
- `ErrorCode.plusRequired` (`PLUS_REQUIRED`), a permission error.
- New fields: `ForecastResponse.location` is a `ForecastLocation` (adds
  `elevation` and `elevations`), `.snowOnGround` and `.avalanche`;
  `snowLevelWetBulb` on `EnsembleStats`, `ModelMean`, `MemberForecast` and
  `DailyForecast`; `TimeSeriesPoint.isMeasured`, `.snowCharacter`,
  `.membersSpread`, `.members6Hours`, `.precipitationByType`;
  `DailyForecast.coveredFrom`, `.measuredPrecipitation`, `.snowCharacter`,
  `.snowToLiquidRatio`, `.snowLevelRange`, `.snowLevelWetBulbRange`,
  `.normal`, `.departure`, `.percentile`; `ForecastData` and
  `ElevationForecast` `.precipitationOutlook` and `.plume`;
  `ElevationForecast.displayName`, `.snowOnGround`, `.nearestSensors`;
  `SnowOutlook.next72Hours`; `WindowTotal.method`;
  `CurrentConditions.isMeasured` and `.cloudCover`;
  `ConditionsStation.isCalm`; `CurrentConditionsResponse.summary`
  (`PlaceSummary`) and `.pass` (`PassForecast`);
  `SensorObservation.distanceKilometers` and `.elevationDifference`; ten
  NWS fields on `ActiveAlert` (`sent`, `messageType`, `description`,
  `instruction`, ...); `PrecipDisplay.snowAmount`;
  `ModelEntry.displayMembers`; `SearchHit.explore`;
  `CatalogElevation.displayName`; `CatalogStationDetail.isIndexable`.
  `LocationSummary.elevations` and `NearbyLocation.elevations` are
  `ElevationSummary` (adds `displayName`); `MembersCumulative` holds
  `MemberQuantiles`.
- Enum values: `light_snow` and `heavy_snow` conditions and icons (and their
  night icons), `AttributionSourceKind.avalancheForecast`; new enums
  `SnowCharacter`, `AlertClass`, `PassStatusLevel` and `ExploreMetric`.
- The `SnowReport` and `Maps` examples; a field-level spec-drift test (every field of
  every schema has a coding key).

### Changed

- JSON fields that repeat a word of their own type have SDK names
  (BEHAVIOR.md 3.0, one table for every Ourea SDK), mapped by each model's
  `CodingKeys`:
  - `ForecastResponse.forecast` is `series` and `.elevationForecasts` is
    `elevations`.
  - `CurrentConditionsResponse.current` is `now`.
  - `ProbabilityResult.probability` is `value`.
  - The list responses' rows are `items` and their counts `count`
    (`alerts`, `alertCount`, `locations`, `runs`; nearby's `location` is
    `origin`, and both nearby routes use `items`).
  - `WindowTotal.windowStartHours`/`windowEndHours` are
    `startHours`/`endHours`.
  - `CurrentConditions.condition`, `.conditionText` and `.conditionIcon`
    are `code`, `text` and `icon`.
  - An elevation's `elevation` is `height`.
  - The rest of the table is in the README's "Names that differ from the
    API's JSON".

  GeoJSON bodies are not renamed: a feature's `properties` is a
  `[String: JSONValue]` with the API's own keys.
- No name stutters (BEHAVIOR.md 3.0): `EnsembleWeatherClient` is `Client`,
  `EnsembleWeatherError` is `OureaError`, `EnsembleWeatherVersion` is
  `SDKVersion` (its `sdk` is `current`) and `WeatherCondition` is
  `Condition`.

### Removed

- `stormReports(limit:)`, `stormReport(id:)` and their models, the catalog's
  `ads`, and the fields, diagnostics and error codes the server withdrew
  before the v1 contract.

[Unreleased]: https://github.com/Ourea-Technologies/ensemble-weather-swift/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Ourea-Technologies/ensemble-weather-swift/releases/tag/v0.1.0
