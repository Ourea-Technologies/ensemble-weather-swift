// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// What a forecast request asks for.
///
/// Every option left at its default is left out of the URL, so equal requests share one edge-cache
/// entry.
///
/// ```swift
/// var options = ForecastOptions()
/// options.maxHours = 72
/// options.probabilities = [.snowfall(atLeast: .inches(6))]
/// options.windowTotals = [.snowfall(in: .hours(72))]
/// ```
public struct ForecastOptions: Sendable, Hashable {
    /// The unit system; `nil` uses the client's.
    public var units: UnitSystem?
    /// Hours of the hourly series past its first hour (6...360, clamped to the tier: Free 240, Pro
    /// 360).
    ///
    /// Default 24.
    public var maxHours = 24
    /// Serves the hourly series from the model run's init, past hours included.
    public var includesPast = false
    /// Includes each model's own distribution per hour (Pro).
    public var includesModels = false
    /// Includes individual ensemble members per hour (Free: the plume view).
    public var includesMembers = false
    /// Forecasts at the location's other named elevations.
    public var elevations: ElevationSelection?
    /// Includes the daily summaries.
    ///
    /// Default `true`.
    public var includesDaily = true
    /// The number of daily rows (1...15); `nil` is the tier's full horizon.
    public var maxDays: Int?
    /// Includes the hourly series.
    ///
    /// Default `true`.
    public var includesHourly = true
    /// A specific model run's init time, for historical queries (Pro).
    public var run: Date?
    /// An allowlist of observation sources for the nowcast blend.
    public var sources: [String]?
    /// A denylist of observation sources, added to the built-in one.
    public var excludedSources: [String]?
    /// Blends the live nowcast layer into the first hours.
    ///
    /// Default `true`; `false` serves the pure, edge-cacheable base forecast.
    public var usesNowcast = true
    /// Probability terms the server answers in ``ForecastResponse/probabilities``.
    public var probabilities: [ProbabilityQuery] = []
    /// Window totals the server answers in ``ForecastResponse/windowTotals``.
    public var windowTotals: [WindowTotalQuery] = []
    /// Opt-in serve-path diagnostics.
    public var diagnostics: Set<ForecastDiagnostic> = []
    /// The feels-like indices to serve; empty is the default (`nws`).
    public var feelsLike: Set<FeelsLikeIndex> = []

    /// Creates options at their defaults.
    public init() {}

    /// Creates options with probability terms and window totals.
    public init(
        units: UnitSystem? = nil,
        maxHours: Int = 24,
        probabilities: [ProbabilityQuery] = [],
        windowTotals: [WindowTotalQuery] = []
    ) {
        self.units = units
        self.maxHours = maxHours
        self.probabilities = probabilities
        self.windowTotals = windowTotals
    }
}

/// Which extra elevations a forecast includes.
public enum ElevationSelection: Sendable, Hashable {
    /// Every named elevation of the location.
    case all
    /// The named elevations (`location.elevations[].name`), such as `["base", "summit"]`.
    case named([String])
}

/// An opt-in forecast diagnostic.
public enum ForecastDiagnostic: String, Sendable, Hashable, CaseIterable {
    /// Each hour's provenance tags.
    case provenance
    /// The model-native precipitation-type code quantiles.
    case ptype
}

/// A feels-like index.
public enum FeelsLikeIndex: String, Sendable, Hashable, CaseIterable {
    /// The NWS apparent temperature (the default).
    case nws
    /// The Universal Thermal Climate Index (not served yet: the server answers 400).
    case utci
}

/// Optional extras of a catalog detail.
public enum CatalogExtra: String, Sendable, Hashable, CaseIterable {
    /// Resolved content entries.
    case content
    /// The page template.
    case template
    /// Resolved ad slots.
    case ads
}

extension ForecastOptions {
    /// Adds the forecast parameters to `query`, returning the resolved terms
    /// and totals for matching the answers.
    func apply(to query: inout QueryString, units: UnitSystem) throws(EnsembleWeatherError) -> (
        [ResolvedProbabilityTerm], [ResolvedWindowTotal]
    ) {
        var terms: [ResolvedProbabilityTerm] = []
        for probability in probabilities {
            terms.append(try ResolvedProbabilityTerm(probability, units: units))
        }
        var totals: [ResolvedWindowTotal] = []
        for total in windowTotals { totals.append(try ResolvedWindowTotal(total)) }

        query.add("max_hours", maxHours, default: 24)
        query.add("include_past", includesPast, default: false)
        query.add("units", units.rawValue, default: UnitSystem.metric.rawValue)
        query.add("models", includesModels, default: false)
        query.add("members", includesMembers, default: false)
        switch elevations {
        case .all: query.add("elevations", "all")
        case .named(let names): query.addList("elevations", names)
        case nil: break
        }
        query.add("daily", includesDaily, default: true)
        query.add("max_days", maxDays)
        query.add("hourly", includesHourly, default: true)
        query.add("run", run.map(JSONCoding.formatTimestamp))
        query.addList("sources", sources)
        query.addList("exclude_sources", excludedSources)
        query.add("nowcast", usesNowcast, default: true)
        query.addWireValue("prob", ResolvedProbabilityTerm.wireValue(for: terms))
        query.addWireValue("totals", ResolvedWindowTotal.wireValue(for: totals))
        query.addList("diagnostics", diagnostics.map(\.rawValue).sorted())
        if feelsLike != [.nws] { query.addList("feels_like", feelsLike.map(\.rawValue).sorted()) }
        return (terms, totals)
    }
}
