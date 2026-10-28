// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The one distribution shape: every ensemble statistic the API serves, in the request's units.
///
/// Every field is optional; a missing field is absent, never 0. Read a range
/// with ``range(_:)`` and the median with ``median``. The wind direction is
/// not a `Quantiles` but a circular distribution, ``CircularStats``.
public struct Quantiles: Sendable, Hashable, Codable {
    /// Ensemble mean.
    public var mean: Double?
    /// 10th percentile (realistic lower bound for visualization).
    public var p10: Double?
    /// 25th percentile.
    public var p25: Double?
    /// Ensemble median -- the headline-appropriate amount for skewed precipitation (half the members above, half below).
    public var p50: Double?
    /// 75th percentile.
    public var p75: Double?
    /// 90th percentile (realistic upper bound for visualization).
    public var p90: Double?
    /// P0 (ensemble minimum -- absolute extreme, often an outlier).
    public var min: Double?
    /// P100 (ensemble maximum -- absolute extreme, often an outlier).
    public var max: Double?
    /// Only on the hourly `precipitation` and `snowfall`.
    public var probability: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        mean: Double? = nil, p10: Double? = nil, p25: Double? = nil, p50: Double? = nil,
        p75: Double? = nil, p90: Double? = nil, min: Double? = nil, max: Double? = nil,
        probability: Double? = nil
    ) {
        self.mean = mean
        self.p10 = p10
        self.p25 = p25
        self.p50 = p50
        self.p75 = p75
        self.p90 = p90
        self.min = min
        self.max = max
        self.probability = probability
    }

    enum CodingKeys: String, CodingKey {
        case mean
        case p10
        case p25
        case p50
        case p75
        case p90
        case min
        case max
        case probability
    }
}

/// One `?prob=` term, answered.
public struct ProbabilityResult: Sendable, Hashable, Codable {
    /// The term's canonical spelling, as the SDK sent it (`snowfall:ge:6.000:24h`): the key the
    /// SDK matches the caller's term by.
    public var term: String
    /// Variable.
    public var variable: ForecastVariable
    /// At least (`ge`) or at most (`le`).
    public var comparison: ProbabilityComparison
    /// In the request's units, at the variable's served precision.
    public var threshold: Double
    /// Window start hours.
    public var windowStartHours: Int
    /// Window end hours.
    public var windowEndHours: Int
    /// Aggregation.
    public var aggregation: ProbabilityAggregation
    /// The window's first instant.
    public var from: Date?
    /// The window's end (exclusive).
    public var to: Date?
    /// The share of members meeting the term, 0..1 (0.001); `nil` (never 0) when it cannot be
    /// answered: ``nullReason`` says why.
    public var probability: Double?
    /// Members that voted: for `total`, the members whose values cover the whole window; for `any`/`all`, those with a value in it.
    public var members: Int
    /// Why ``probability`` is `nil`; `nil` when it is not.
    public var nullReason: NullReason?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        term: String, variable: ForecastVariable, comparison: ProbabilityComparison,
        threshold: Double, windowStartHours: Int, windowEndHours: Int,
        aggregation: ProbabilityAggregation, from: Date? = nil, to: Date? = nil,
        probability: Double? = nil, members: Int, nullReason: NullReason? = nil
    ) {
        self.term = term
        self.variable = variable
        self.comparison = comparison
        self.threshold = threshold
        self.windowStartHours = windowStartHours
        self.windowEndHours = windowEndHours
        self.aggregation = aggregation
        self.from = from
        self.to = to
        self.probability = probability
        self.members = members
        self.nullReason = nullReason
    }

    enum CodingKeys: String, CodingKey {
        case term
        case variable
        case comparison = "op"
        case threshold
        case windowStartHours = "window_start_hours"
        case windowEndHours = "window_end_hours"
        case aggregation
        case from
        case to
        case probability
        case members
        case nullReason = "null_reason"
    }
}

/// One `?totals=` window, across the members.
public struct WindowTotal: Sendable, Hashable, Codable {
    /// The term's canonical spelling, as the SDK sent it (`snowfall:72h`): the key the SDK
    /// matches the caller's query by.
    public var term: String
    /// Variable.
    public var variable: ForecastVariable
    /// Window start hours.
    public var windowStartHours: Int
    /// Window end hours.
    public var windowEndHours: Int
    /// From.
    public var from: Date?
    /// To.
    public var to: Date?
    /// What each member contributes: ``WindowTotalAggregation/total`` for precipitation and snowfall.
    public var aggregation: WindowTotalAggregation
    /// The members' window totals, counted as the headline counts its windows (a straddling
    /// bucket by its share inside; only members covering the whole window); `nil` when the
    /// window cannot be answered: ``nullReason`` says why.
    public var quantiles: Quantiles?
    /// Members.
    public var members: Int
    /// Why ``quantiles`` is `nil`; `nil` when it is not.
    public var nullReason: NullReason?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        term: String, variable: ForecastVariable, windowStartHours: Int, windowEndHours: Int,
        from: Date? = nil, to: Date? = nil, aggregation: WindowTotalAggregation = .total,
        quantiles: Quantiles? = nil, members: Int, nullReason: NullReason? = nil
    ) {
        self.term = term
        self.variable = variable
        self.windowStartHours = windowStartHours
        self.windowEndHours = windowEndHours
        self.from = from
        self.to = to
        self.aggregation = aggregation
        self.quantiles = quantiles
        self.members = members
        self.nullReason = nullReason
    }

    enum CodingKeys: String, CodingKey {
        case term
        case variable
        case windowStartHours = "window_start_hours"
        case windowEndHours = "window_end_hours"
        case from
        case to
        case aggregation
        case quantiles
        case members
        case nullReason = "null_reason"
    }
}

/// A clockwise arc on the compass, degrees.
///
/// `to` may be numerically less than `from` when the arc crosses north: the width is
/// `(to - from) mod 360`. The SDK does not "fix" it.
public struct Sector: Sendable, Hashable, Codable {
    /// From.
    public var from: Double
    /// To.
    public var to: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(from: Double, to: Double) {
        self.from = from
        self.to = to
    }

    enum CodingKeys: String, CodingKey {
        case from
        case to
    }
}

/// A bearing's distribution stated on the circle.
public struct CircularStats: Sendable, Hashable, Codable {
    /// The resultant-vector mean direction, degrees clockwise from north, in [0, 360).
    public var mean: Double
    /// Standard deviation of the members' signed angular offsets from `mean`, degrees; `nil` on a
    /// single-member hour.
    public var standardDeviation: Double?
    /// The central 50 % of the members — the clockwise arc from the 25th to the 75th circular percentile.
    public var sector50: Sector
    /// The central 90 % of the members — the clockwise arc from the 5th to the 95th circular percentile.
    public var sector90: Sector

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(mean: Double, standardDeviation: Double? = nil, sector50: Sector, sector90: Sector)
    {
        self.mean = mean
        self.standardDeviation = standardDeviation
        self.sector50 = sector50
        self.sector90 = sector90
    }

    enum CodingKeys: String, CodingKey {
        case mean
        case standardDeviation = "stddev"
        case sector50 = "sector_50"
        case sector90 = "sector_90"
    }
}

/// The distribution of the members' running totals at this hour.
public struct MembersCumulative: Sendable, Hashable, Codable {
    /// Precipitation.
    public var precipitation: Quantiles?
    /// Snowfall.
    public var snowfall: Quantiles?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(precipitation: Quantiles? = nil, snowfall: Quantiles? = nil) {
        self.precipitation = precipitation
        self.snowfall = snowfall
    }

    enum CodingKeys: String, CodingKey {
        case precipitation
        case snowfall
    }
}
