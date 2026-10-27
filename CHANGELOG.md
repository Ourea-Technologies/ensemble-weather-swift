# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project
uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
