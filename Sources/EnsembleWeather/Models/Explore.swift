// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// One page of a ranking.
public struct ExploreResponse: Sendable, Hashable, Codable {
    /// Metric.
    public var metric: ExploreMetric
    /// Order.
    public var order: String
    /// Units.
    public var units: UnitSystem
    /// The unit of every `value`, `p10` and `p90`.
    public var unit: String
    /// Items.
    public var items: [ExploreItem]
    /// Items on this page.
    public var count: Int
    /// Pass as `?cursor=` (same other parameters) for the next page; null at the end.
    public var nextCursor: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        metric: ExploreMetric, order: String, units: UnitSystem, unit: String, items: [ExploreItem],
        count: Int, nextCursor: String? = nil
    ) {
        self.metric = metric
        self.order = order
        self.units = units
        self.unit = unit
        self.items = items
        self.count = count
        self.nextCursor = nextCursor
    }

    enum CodingKeys: String, CodingKey {
        case metric
        case order
        case units
        case unit
        case items
        case count
        case nextCursor = "next_cursor"
    }
}

/// One ranked point of a place.
public struct ExploreItem: Sendable, Hashable, Codable {
    /// 1-based, across pages.
    public var rank: Int
    /// Location.
    public var location: LocationReference
    /// The named elevation; `null` = the place's own point.
    public var elevationName: String?
    /// What the elevation `elevation_name` is called, as `ElevationSummary.display_name`; absent where it has no name.
    public var elevationDisplayName: String?
    /// The point's elevation, m or ft by `units`.
    public var elevation: Double
    /// The metric's value as the place's page serves it, in `unit`.
    public var value: Double
    /// Present only on `snow_today` (the day's served `total_snowfall.p10`, where it has a `snow_amount`) and `precip_today` (`total_precipitation_if_wet.p10`, where the day is not `none`).
    public var p10: Double?
    /// As `p10`.
    public var p90: Double?
    /// When the value was taken: the forecast windows when recorded from the served run, `base_depth` its hour, `new_snow_24h` the snowpack run's first hour, the season its newest computed day.
    public var asOf: Date
    /// Forecast windows only, the served run's `model_run.initialized_at`.
    public var initializedAt: Date?
    /// Source.
    public var source: String
    /// With `near` only, from it (0.1 km).
    public var distanceKilometers: Double?
    /// The place's forecast route; add `?elevations=<elevation_name>` for a named point.
    public var path: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        rank: Int, location: LocationReference, elevationName: String? = nil,
        elevationDisplayName:
            String? = nil, elevation: Double, value: Double, p10: Double? = nil, p90: Double? = nil,
        asOf: Date, initializedAt: Date? = nil, source: String, distanceKilometers: Double? = nil,
        path: String
    ) {
        self.rank = rank
        self.location = location
        self.elevationName = elevationName
        self.elevationDisplayName = elevationDisplayName
        self.elevation = elevation
        self.value = value
        self.p10 = p10
        self.p90 = p90
        self.asOf = asOf
        self.initializedAt = initializedAt
        self.source = source
        self.distanceKilometers = distanceKilometers
        self.path = path
    }

    enum CodingKeys: String, CodingKey {
        case rank
        case location
        case elevationName = "elevation_name"
        case elevationDisplayName = "elevation_display_name"
        case elevation
        case value
        case p10
        case p90
        case asOf = "as_of"
        case initializedAt = "initialized_at"
        case source
        case distanceKilometers = "distance_km"
        case path
    }
}

/// A search hit's explore value; each field means what it means on an `ExploreItem`.
public struct ExploreValue: Sendable, Hashable, Codable {
    /// Metric.
    public var metric: ExploreMetric
    /// Value.
    public var value: Double
    /// Unit.
    public var unit: String
    /// The 10th percentile.
    public var p10: Double?
    /// The 90th percentile.
    public var p90: Double?
    /// As of.
    public var asOf: Date
    /// Initialized at.
    public var initializedAt: Date?
    /// Source.
    public var source: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        metric: ExploreMetric, value: Double, unit: String, p10: Double? = nil, p90: Double? = nil,
        asOf: Date, initializedAt: Date? = nil, source: String
    ) {
        self.metric = metric
        self.value = value
        self.unit = unit
        self.p10 = p10
        self.p90 = p90
        self.asOf = asOf
        self.initializedAt = initializedAt
        self.source = source
    }

    enum CodingKeys: String, CodingKey {
        case metric
        case value
        case unit
        case p10
        case p90
        case asOf = "as_of"
        case initializedAt = "initialized_at"
        case source
    }
}

/// `GET /api/v1/composition`.
public struct CompositionResponse: Sendable, Hashable, Codable {
    /// The reference init: the newest contributing cycle, a forecast's `model_run.initialized_at`.
    public var initializedAt: Date
    /// Each contributing model, its own cycle and its members (`members` absent only when the cycle's member count is not known).
    public var models: [ModelEntry]
    /// Entries in `models`.
    public var modelCount: Int
    /// The sum of `models[].members`: the members the blend draws on.
    public var totalMembers: Int

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        initializedAt: Date, models: [ModelEntry], modelCount: Int, totalMembers: Int
    ) {
        self.initializedAt = initializedAt
        self.models = models
        self.modelCount = modelCount
        self.totalMembers = totalMembers
    }

    enum CodingKeys: String, CodingKey {
        case initializedAt = "initialized_at"
        case models
        case modelCount = "model_count"
        case totalMembers = "total_members"
    }
}
