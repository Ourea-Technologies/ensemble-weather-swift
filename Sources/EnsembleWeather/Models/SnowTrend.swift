// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// -- each recent run's daily snowfall at a location's point, by source.
public struct SnowTrendResponse: Sendable, Hashable, Codable {
    /// Location.
    public var location: LocationReference
    /// Units.
    public var units: UnitSystem
    /// The point the grids are for.
    public var elevation: SnowTrendElevation
    /// How many days back runs are kept.
    public var retentionDays: Int
    /// The columns, location-local dates ascending.
    public var dates: [String]
    /// `ourea` first; with the `model_data` entitlement then `aifs`, `aigefs`, `gefs`, `ifs_ens` and `rrfs`.
    public var grids: [SnowTrendGrid]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        location: LocationReference, units: UnitSystem, elevation: SnowTrendElevation,
        retentionDays: Int, dates: [String], grids: [SnowTrendGrid]
    ) {
        self.location = location
        self.units = units
        self.elevation = elevation
        self.retentionDays = retentionDays
        self.dates = dates
        self.grids = grids
    }

    enum CodingKeys: String, CodingKey {
        case location
        case units
        case elevation
        case retentionDays = "retention_days"
        case dates
        case grids
    }
}

/// The point the grids are for.
public struct SnowTrendElevation: Sendable, Hashable, Codable {
    /// The named elevation; `null` for a location with one point.
    public var name: String?
    /// What that elevation is called, as `ElevationSummary.display_name`; absent where it has no name.
    public var displayName: String?
    /// (JSON `elevation`) Its elevation, in m (metric) or ft (imperial).
    public var height: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        name: String? = nil, displayName: String? = nil, height: Double
    ) {
        self.name = name
        self.displayName = displayName
        self.height = height
    }

    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case height = "elevation"
    }
}

/// One source's snow trend: its recent runs, each a row of daily snowfall.
public struct SnowTrendGrid: Sendable, Hashable, Codable {
    /// `ourea`, or a model id.
    public var source: String
    /// Oldest first; the last is the newest.
    public var runs: [SnowTrendRun]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        source: String, runs: [SnowTrendRun]
    ) {
        self.source = source
        self.runs = runs
    }

    enum CodingKeys: String, CodingKey {
        case source
        case runs
    }
}

/// One run's daily snowfall, one cell per date.
public struct SnowTrendRun: Sendable, Hashable, Codable {
    /// `true`: re-rendered after the fact from the pinned run (`?run=<initialized_at>`) by the post-deploy backfill -- today's calibration and no live nowcast, so it can differ slightly from what was served then.
    public var backfilled: Bool
    /// `ourea`: the served body's `model_run.initialized_at`.
    public var initializedAt: Date
    /// One entry per `dates` entry, in order; `null` where the run has no value.
    public var days: [SnowTrendDay?]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        backfilled: Bool, initializedAt: Date, days: [SnowTrendDay?]
    ) {
        self.backfilled = backfilled
        self.initializedAt = initializedAt
        self.days = days
    }

    enum CodingKeys: String, CodingKey {
        case backfilled
        case initializedAt = "initialized_at"
        case days
    }
}

/// One run's snowfall on one day.
public struct SnowTrendDay: Sendable, Hashable, Codable {
    /// The `dates` entry this day is for.
    public var date: String
    /// (JSON `snow`) The day's snowfall in mm (metric) or inches (imperial), at the served amount precision.
    public var amount: Double?
    /// The run covers only part of this local day.
    public var isPartial: Bool
    /// The range's low end.
    public var p10: Double?
    /// The range's high end, as `p10`.
    public var p90: Double?
    /// `ourea` only: the day's `precipitation_display.kind`.
    public var kind: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        date: String, amount: Double? = nil, isPartial: Bool, p10: Double? = nil,
        p90: Double? =
            nil, kind: String? = nil
    ) {
        self.date = date
        self.amount = amount
        self.isPartial = isPartial
        self.p10 = p10
        self.p90 = p90
        self.kind = kind
    }

    enum CodingKeys: String, CodingKey {
        case date
        case amount = "snow"
        case isPartial = "partial"
        case p10
        case p90
        case kind
    }
}
