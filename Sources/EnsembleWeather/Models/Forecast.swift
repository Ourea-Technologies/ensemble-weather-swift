// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The event behind each served probability, in the request's units, so no client hard-codes them: P(amount >= the threshold).
public struct ProbabilityThresholds: Sendable, Hashable, Codable {
    /// The threshold of `ensemble.precipitation.probability`, 0.254 mm.
    public var hourlyPrecipitation: Double
    /// The threshold of `ensemble.snowfall.probability`, 0.254 mm.
    public var hourlySnowfall: Double
    /// The threshold of `daily[].precip_probability`, a day total of 2.5 mm.
    public var dailyPrecipitationProbability: Double
    /// The threshold of `daily[].precip_occurrence_probability`, 1.0 mm, also the "if wet" condition.
    public var dailyPrecipitationOccurrenceProbability: Double
    /// The threshold of `daily[].snow_probability`, a day snowfall of 2.5 mm.
    public var dailySnowProbability: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        hourlyPrecipitation: Double, hourlySnowfall: Double, dailyPrecipitationProbability: Double,
        dailyPrecipitationOccurrenceProbability: Double, dailySnowProbability: Double
    ) {
        self.hourlyPrecipitation = hourlyPrecipitation
        self.hourlySnowfall = hourlySnowfall
        self.dailyPrecipitationProbability = dailyPrecipitationProbability
        self.dailyPrecipitationOccurrenceProbability = dailyPrecipitationOccurrenceProbability
        self.dailySnowProbability = dailySnowProbability
    }

    enum CodingKeys: String, CodingKey {
        case hourlyPrecipitation = "hourly_precipitation"
        case hourlySnowfall = "hourly_snowfall"
        case dailyPrecipitationProbability = "daily_precip_probability"
        case dailyPrecipitationOccurrenceProbability = "daily_precip_occurrence_probability"
        case dailySnowProbability = "daily_snow_probability"
    }
}

/// The forecast options the server applied, after the tier clamps and bounds.
public struct AppliedOptions: Sendable, Hashable, Codable {
    /// Hours past the first served hour; `null` with `hourly=false`.
    public var maxHours: Int?
    /// Daily rows served for; `null` with `daily=false`.
    public var maxDays: Int?
    /// The requested options the server changed, in this order.
    public var clamped: [ClampedOption]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(maxHours: Int? = nil, maxDays: Int? = nil, clamped: [ClampedOption]) {
        self.maxHours = maxHours
        self.maxDays = maxDays
        self.clamped = clamped
    }

    enum CodingKeys: String, CodingKey {
        case maxHours = "max_hours"
        case maxDays = "max_days"
        case clamped
    }
}

/// Columbia Gorge gap flow status at the first served hour, from the forecast mean-sea-level-pressure difference across the Gorge (The Dalles minus Portland.
public struct GapFlow: Sendable, Hashable, Codable {
    /// Status.
    public var status: GapFlowStatus?
    /// Pressure diff hpa.
    public var pressureDifferenceHectopascals: Double?
    /// Wind multiplier.
    public var windMultiplier: Double?
    /// Direction.
    public var direction: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        status: GapFlowStatus? = nil, pressureDifferenceHectopascals: Double? = nil,
        windMultiplier: Double? = nil, direction: String? = nil
    ) {
        self.status = status
        self.pressureDifferenceHectopascals = pressureDifferenceHectopascals
        self.windMultiplier = windMultiplier
        self.direction = direction
    }

    enum CodingKeys: String, CodingKey {
        case status
        case pressureDifferenceHectopascals = "pressure_diff_hpa"
        case windMultiplier = "wind_multiplier"
        case direction
    }
}

/// The composition the forecast was blended from.
public struct ModelRun: Sendable, Hashable, Codable {
    /// The reference init: the NEWEST contributing model's cycle.
    public var initializedAt: Date
    /// Total members.
    public var totalMembers: Int
    /// One entry per contributing model, in the order `aifs`, `aigefs`, `gefs`, `ifs_ens`, `rrfs` (a model added later follows, by id).
    public var models: [ModelEntry]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(initializedAt: Date, totalMembers: Int, models: [ModelEntry]) {
        self.initializedAt = initializedAt
        self.totalMembers = totalMembers
        self.models = models
    }

    enum CodingKeys: String, CodingKey {
        case initializedAt = "initialized_at"
        case totalMembers = "total_members"
        case models
    }
}

/// (D-8) -- one contributing model.
public struct ModelEntry: Sendable, Hashable, Codable {
    /// The model id (`aifs`, `aigefs`, `gefs`, `ifs_ens`, `rrfs`; treat others as additive).
    public var id: String
    /// The model's own cycle init (per-model-latest).
    public var cycle: Date?
    /// How many of its members the forecast carries (in `model_run`); omitted in `/runs` `served`.
    public var members: Int?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(id: String, cycle: Date? = nil, members: Int? = nil) {
        self.id = id
        self.cycle = cycle
        self.members = members
    }

    enum CodingKeys: String, CodingKey {
        case id
        case cycle
        case members
    }
}

/// The forecast proper: the hourly series, the daily summaries and the snow outlook.
public struct ForecastData: Sendable, Hashable, Codable {
    /// The last served hour, in hours from the FIRST served one (the current hour by default, the run's init with `include_past=true` or a pinned `run`).
    public var maxHours: Int
    /// Interval hours.
    public var intervalHours: Int
    /// Omitted with `hourly=false`.
    public var timeseries: [TimeSeriesPoint]?
    /// Daily.
    public var daily: [DailyForecast]?
    /// Rolling snow-accumulation summary for common UI windows.
    public var snowOutlook: SnowOutlook?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        maxHours: Int, intervalHours: Int, timeseries: [TimeSeriesPoint]? = nil,
        daily: [DailyForecast]? = nil, snowOutlook: SnowOutlook? = nil
    ) {
        self.maxHours = maxHours
        self.intervalHours = intervalHours
        self.timeseries = timeseries
        self.daily = daily
        self.snowOutlook = snowOutlook
    }

    enum CodingKeys: String, CodingKey {
        case maxHours = "max_hours"
        case intervalHours = "interval_hours"
        case timeseries
        case daily
        case snowOutlook = "snow_outlook"
    }
}

/// Snow accumulation totals for common UI windows.
public struct SnowOutlook: Sendable, Hashable, Codable {
    /// Sum of the hourly snowfall means over the 24 h from the first served hour; `null` when the forecast does not reach its end.
    public var next24Hours: Double?
    /// Sum of the hourly snowfall means over the first 48 h; `null` when not covered.
    public var next48Hours: Double?
    /// Sum of the hourly snowfall means over the first 168 h; `null` when not covered.
    public var next7Days: Double?
    /// Snow expected overnight, local 16:00 today → 09:00 tomorrow: the sum of the hourly snowfall means in the window, read from the forecast whatever `max_hours` is.
    public var overnight4pmTo9am: Double?
    /// Quantiles.
    public var quantiles: SnowOutlookQuantiles?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        next24Hours: Double? = nil, next48Hours: Double? = nil, next7Days: Double? = nil,
        overnight4pmTo9am: Double? = nil, quantiles: SnowOutlookQuantiles? = nil
    ) {
        self.next24Hours = next24Hours
        self.next48Hours = next48Hours
        self.next7Days = next7Days
        self.overnight4pmTo9am = overnight4pmTo9am
        self.quantiles = quantiles
    }

    enum CodingKeys: String, CodingKey {
        case next24Hours = "next_24h"
        case next48Hours = "next_48h"
        case next7Days = "next_7d"
        case overnight4pmTo9am = "overnight_4pm_9am"
        case quantiles
    }
}

/// The RANGE of each `snow_outlook` window's snowfall total, on the default response (no `members` needed) and on every `elevation_forecasts[].snow_outlook`.
public struct SnowOutlookQuantiles: Sendable, Hashable, Codable {
    /// Next 24h.
    public var next24Hours: Quantiles?
    /// Next 48h.
    public var next48Hours: Quantiles?
    /// Next 7d.
    public var next7Days: Quantiles?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        next24Hours: Quantiles? = nil, next48Hours: Quantiles? = nil, next7Days: Quantiles? = nil
    ) {
        self.next24Hours = next24Hours
        self.next48Hours = next48Hours
        self.next7Days = next7Days
    }

    enum CodingKeys: String, CodingKey {
        case next24Hours = "next_24h"
        case next48Hours = "next_48h"
        case next7Days = "next_7d"
    }
}

/// Where a coordinate forecast (`GET /api/v1/forecast`) was computed.
public struct PointInfo: Sendable, Hashable, Codable {
    /// Latitude as sent.
    public var requestedLatitude: Double
    /// Longitude as sent.
    public var requestedLongitude: Double
    /// The quantized latitude the forecast was computed at.
    public var latitude: Double
    /// The quantized longitude the forecast was computed at.
    public var longitude: Double
    /// Quantization step in degrees (0.01).
    public var resolutionDegrees: Double
    /// Elevation the forecast was computed at, in the response's length unit (m; ft for `units=imperial`), like `location.elevation`.
    public var elevation: Double
    /// `request` = the caller's `elevation_m` (it always wins).
    public var elevationSource: ElevationSource
    /// USPS code of the state the point is in (sets the daily summaries' timezone).
    public var state: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        requestedLatitude: Double, requestedLongitude: Double, latitude: Double, longitude: Double,
        resolutionDegrees: Double, elevation: Double, elevationSource: ElevationSource,
        state: String
    ) {
        self.requestedLatitude = requestedLatitude
        self.requestedLongitude = requestedLongitude
        self.latitude = latitude
        self.longitude = longitude
        self.resolutionDegrees = resolutionDegrees
        self.elevation = elevation
        self.elevationSource = elevationSource
        self.state = state
    }

    enum CodingKeys: String, CodingKey {
        case requestedLatitude = "requested_lat"
        case requestedLongitude = "requested_lon"
        case latitude = "lat"
        case longitude = "lon"
        case resolutionDegrees = "resolution_deg"
        case elevation
        case elevationSource = "elevation_source"
        case state
    }
}

/// A nearby observation sensor, ranked by elevation-weighted distance.
public struct NearestSensor: Sendable, Hashable, Codable {
    /// The station's id in its network.
    public var stationID: String
    /// The station's name from the stations registry, else its id (it was one `station_name` holding the id).
    public var name: String
    /// Observation network (snotel, nws, raws, rwis, cdec, tempest, etc.).
    public var source: String
    /// Straight-line surface distance in km.
    public var distanceKilometers: Double
    /// Sensor elevation minus forecast-location elevation, in the caller's length units (m metric, ft imperial).
    public var elevationDifference: Double
    /// `distance_km + |elevation_diff_m| / 100`.
    public var effectiveDistanceKilometers: Double
    /// Observation time.
    public var observationTime: Date

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        stationID: String, name: String, source: String, distanceKilometers: Double,
        elevationDifference: Double, effectiveDistanceKilometers: Double, observationTime: Date
    ) {
        self.stationID = stationID
        self.name = name
        self.source = source
        self.distanceKilometers = distanceKilometers
        self.elevationDifference = elevationDifference
        self.effectiveDistanceKilometers = effectiveDistanceKilometers
        self.observationTime = observationTime
    }

    enum CodingKeys: String, CodingKey {
        case stationID = "station_id"
        case name
        case source
        case distanceKilometers = "distance_km"
        case elevationDifference = "elevation_diff"
        case effectiveDistanceKilometers = "effective_distance_km"
        case observationTime = "observation_time"
    }
}
