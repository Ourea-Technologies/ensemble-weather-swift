// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The forecast's `location` -- the one `LocationRef` (every field where it was) plus what a forecast client labels and picks with, so the forecast body alone is enough to draw a plume or a meteogram at a named elevation (no `/nearby` call, no client-side unit conversion).
public struct ForecastLocation: Sendable, Hashable, Codable {
    /// The location's key: its catalog slug.
    public var slug: String?
    /// The lowercase USPS state code.
    public var state: String
    /// The display name.
    public var name: String
    /// Lat.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// Elevation in metres, whatever `units` is (0.1 m).
    public var elevationMeters: Double
    /// The primary location type, snake_case.
    public var type: LocationType?
    /// The IANA zone the location's local days and hours are kept in -- the zone `daily` dates, sunrise and sunset are computed in.
    public var timezone: String
    /// `elevation_m` in the request's length units (m for `metric`/`kelvin`, ft for `imperial`), to 0.1 -- the elevation `forecast.timeseries` (and its members) is served at.
    public var elevation: Double
    /// The location's named elevations -- exactly the list its `/nearby` and list rows serve (`LocationSummary.elevations`): the primary first and its ONE `default: true`, then each other elevation (ski-area base / mid / summit), in the request's ...
    public var elevations: [ElevationSummary]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String? = nil, state: String, name: String, latitude: Double, longitude: Double,
        elevationMeters: Double, type: LocationType? = nil, timezone: String, elevation: Double,
        elevations: [ElevationSummary]? = nil
    ) {
        self.slug = slug
        self.state = state
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.type = type
        self.timezone = timezone
        self.elevation = elevation
        self.elevations = elevations
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case state
        case name
        case latitude = "lat"
        case longitude = "lon"
        case elevationMeters = "elevation_m"
        case type
        case timezone
        case elevation
        case elevations
    }
}

/// One of a location's elevation points, as `/nearby`, the list rows and the forecast's `location.elevations` serve it.
public struct ElevationSummary: Sendable, Hashable, Codable {
    /// The elevation's id: the name to pass in `?elevations=` (case, `-`, `_` and spaces ignored).
    public var name: String
    /// What the place is called, for display ("K-1 Lodge", "FourRunner Quad top").
    public var displayName: String?
    /// (JSON `elevation`) In the caller's length units (m, ft), to 0.1.
    public var height: Double
    /// Present (true) on the primary only.
    public var isDefault: Bool?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        name: String, displayName: String? = nil, height: Double, isDefault: Bool? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.height = height
        self.isDefault = isDefault
    }

    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case height = "elevation"
        case isDefault = "default"
    }
}

/// A distribution over the ensemble MEMBERS (`members_cumulative`, `members_spread`, `members_6h`): the `Quantiles` shape.
public struct MemberQuantiles: Sendable, Hashable, Codable {
    /// Mean.
    public var mean: Double
    /// The 10th percentile.
    public var p10: Double
    /// The 25th percentile.
    public var p25: Double
    /// The members' median.
    public var p50: Double?
    /// The 75th percentile.
    public var p75: Double
    /// The 90th percentile.
    public var p90: Double
    /// Min.
    public var min: Double
    /// Max.
    public var max: Double
    /// As `Quantiles.probability`, where the use says.
    public var probability: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        mean: Double, p10: Double, p25: Double, p50: Double? = nil, p75: Double, p90: Double,
        min:
            Double, max: Double, probability: Double? = nil
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

/// The members' spread at this hour for the plume's instantaneous variables -- the Quantiles of every member's own `temperature` (temperature unit) and `snow_level` (length unit) here, over the members as served.
public struct MembersSpread: Sendable, Hashable, Codable {
    /// Temperature.
    public var temperature: MemberQuantiles?
    /// Snow level.
    public var snowLevel: MemberQuantiles?
    /// The Quantiles of the members' own `snow_level_wet_bulb` (the snow level on the NWS scale), over the members `snow_level` is over.
    public var snowLevelWetBulb: MemberQuantiles?
    /// The snow-to-liquid ratio over the members SNOWING at this hour (their own `snowfall` above 0), at 00/06/12/18Z only, in both member views.
    public var snowToLiquidRatio: MemberQuantiles?
    /// The members' own wind speed at this hour, in the wind unit.
    public var windSpeed: MemberQuantiles?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        temperature: MemberQuantiles? = nil, snowLevel: MemberQuantiles? = nil,
        snowLevelWetBulb:
            MemberQuantiles? = nil, snowToLiquidRatio: MemberQuantiles? = nil,
        windSpeed:
            MemberQuantiles? = nil
    ) {
        self.temperature = temperature
        self.snowLevel = snowLevel
        self.snowLevelWetBulb = snowLevelWetBulb
        self.snowToLiquidRatio = snowToLiquidRatio
        self.windSpeed = windSpeed
    }

    enum CodingKeys: String, CodingKey {
        case temperature
        case snowLevel = "snow_level"
        case snowLevelWetBulb = "snow_level_wet_bulb"
        case snowToLiquidRatio = "slr"
        case windSpeed = "wind_speed"
    }
}

/// This hour's headline precipitation (`ensemble.precipitation.mean`) split by phase, in the precipitation units -- `rain + snow + rain_snow_mix + freezing_rain` is the hour's mean (to the served precision), so a stacked bar is the headline bar.
public struct PrecipitationByType: Sendable, Hashable, Codable {
    /// Rain.
    public var rain: Double
    /// The liquid that falls as snow (not snow depth; that is `ensemble.snowfall`).
    public var snow: Double
    /// Rain snow mix.
    public var rainSnowMix: Double
    /// -- liquid that freezes on contact (counted in `rain` before).
    public var freezingRain: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        rain: Double, snow: Double, rainSnowMix: Double, freezingRain: Double
    ) {
        self.rain = rain
        self.snow = snow
        self.rainSnowMix = rainSnowMix
        self.freezingRain = freezingRain
    }

    enum CodingKeys: String, CodingKey {
        case rain
        case snow
        case rainSnowMix = "rain_snow_mix"
        case freezingRain = "freezing_rain"
    }
}

/// A day's snow level over its wet hours (m, or ft with `units=imperial`): the lowest and highest hourly ensemble-mean snow level among them, and their precipitation-weighted mean.
public struct SnowLevelRange: Sendable, Hashable, Codable {
    /// The lowest hourly snow level among the wet hours.
    public var low: Double
    /// The highest hourly snow level among the wet hours.
    public var high: Double
    /// The wet hours' snow level, weighted by their precipitation.
    public var mean: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        low: Double, high: Double, mean: Double
    ) {
        self.low = low
        self.high = high
        self.mean = mean
    }

    enum CodingKeys: String, CodingKey {
        case low
        case high
        case mean
    }
}

/// The day's climate normal at the forecast point: the mean, over the day of year +/-15 days of every year of the station's record, of the very quantities this row states -- the local CALENDAR date's maximum hourly temperature (`high`, the quantity `high` is), its minimum (`low`) and its precipitation TOTAL (`precipitation`, dry days included; a daily total, never an hourly amount).
public struct DayNormal: Sendable, Hashable, Codable {
    /// Mean local-calendar-day maximum temperature.
    public var high: Double?
    /// Mean local-calendar-day minimum temperature.
    public var low: Double?
    /// Mean local-calendar-day precipitation total, dry days included.
    public var precipitation: Double?
    /// A climatology station's own record, or the ERA5 cell of the point.
    public var source: String
    /// Great-circle distance from the point to the station (or the cell centre), km.
    public var distanceKilometers: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        high: Double? = nil, low: Double? = nil, precipitation: Double? = nil, source: String,
        distanceKilometers: Double
    ) {
        self.high = high
        self.low = low
        self.precipitation = precipitation
        self.source = source
        self.distanceKilometers = distanceKilometers
    }

    enum CodingKeys: String, CodingKey {
        case high
        case low
        case precipitation
        case source
        case distanceKilometers = "distance_km"
    }
}

/// The served headline minus the normal, in the request's units: `high.p50 - normal.high` and `low.p50 - normal.low`.
public struct DayDeparture: Sendable, Hashable, Codable {
    /// High.
    public var high: Double?
    /// Low.
    public var low: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        high: Double? = nil, low: Double? = nil
    ) {
        self.high = high
        self.low = low
    }

    enum CodingKeys: String, CodingKey {
        case high
        case low
    }
}

/// How unusual the day is: where the served headline (`p50`) falls in the day's climatological distribution, as a percentile 0-100, `Pr{climate <= forecast}` -- 95 for `precipitation` reads "wetter than 95% of this date's days".
public struct DayPercentile: Sendable, Hashable, Codable {
    /// High.
    public var high: Double?
    /// Low.
    public var low: Double?
    /// Precipitation.
    public var precipitation: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        high: Double? = nil, low: Double? = nil, precipitation: Double? = nil
    ) {
        self.high = high
        self.low = low
        self.precipitation = precipitation
    }

    enum CodingKeys: String, CodingKey {
        case high
        case low
        case precipitation
    }
}

/// Rolling liquid-equivalent totals over the same windows as `snow_outlook`, for places where rain is the story (the favorites cards' "0.6 in rain" with its range).
public struct PrecipOutlook: Sendable, Hashable, Codable {
    /// Sum of the hourly precipitation means over the 24 h from the first served hour; `null` when not covered.
    public var next24Hours: Double?
    /// The same over 48 h.
    public var next48Hours: Double?
    /// The same over 72 h.
    public var next72Hours: Double?
    /// The same over 168 h.
    public var next7Days: Double?
    /// Quantiles.
    public var quantiles: SnowOutlookQuantiles?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        next24Hours: Double? = nil, next48Hours: Double? = nil, next72Hours: Double? = nil,
        next7Days: Double? = nil, quantiles: SnowOutlookQuantiles? = nil
    ) {
        self.next24Hours = next24Hours
        self.next48Hours = next48Hours
        self.next72Hours = next72Hours
        self.next7Days = next7Days
        self.quantiles = quantiles
    }

    enum CodingKeys: String, CodingKey {
        case next24Hours = "next_24h"
        case next48Hours = "next_48h"
        case next72Hours = "next_72h"
        case next7Days = "next_7d"
        case quantiles
    }
}

/// What the snowpack model states is on the ground at a spot at one hour.
public struct SnowOnGround: Sendable, Hashable, Codable {
    /// Always `true` while the product is a beta; fields may be added.
    public var isBeta: Bool
    /// Snow depth: cm, or in (imperial).
    public var depth: Double
    /// `measured`: the run started from a snow-depth sensor at the spot.
    public var basis: String
    /// The surface class at the hour; `definitions.surface` of `/snowpack` carries the text of each value (an open set).
    public var surface: String?
    /// The hour the depth is for.
    public var validTime: Date
    /// When the snowpack run that produced it finished.
    public var generatedAt: Date

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        isBeta: Bool, depth: Double, basis: String, surface: String? = nil, validTime: Date,
        generatedAt: Date
    ) {
        self.isBeta = isBeta
        self.depth = depth
        self.basis = basis
        self.surface = surface
        self.validTime = validTime
        self.generatedAt = generatedAt
    }

    enum CodingKeys: String, CodingKey {
        case isBeta = "beta"
        case depth
        case basis
        case surface
        case validTime = "valid_time"
        case generatedAt = "generated_at"
    }
}

/// The avalanche center's danger rating for the forecast zone the location's point is in, from avalanche.org's public map layer.
public struct AvalancheForecast: Sendable, Hashable, Codable {
    /// The avalanche center's short id.
    public var centerID: String
    /// Center name.
    public var centerName: String
    /// avalanche.org's id for the forecast zone; for a CAIC forecast area, an id at or above 2^52 derived from CAIC's area id (stable for that grouping of CAIC's polygons).
    public var zoneID: Int
    /// Zone name.
    public var zoneName: String
    /// The North American Public Avalanche Danger Scale level, 1-5; present only when `status` is `rated`.
    public var dangerLevel: Int?
    /// Display text: the scale's English name for `danger_level` (Low, Moderate, Considerable, High, Extreme), derived from the level, never the center's own wording; `null` exactly when `danger_level` is.
    public var dangerLabel: String?
    /// `rated`: a current rating.
    public var status: String
    /// When the center's current product took effect (UTC), when stated.
    public var validFrom: Date?
    /// When the center's current product expires (UTC), when stated.
    public var validUntil: Date?
    /// (JSON `forecast_url`) The center's full forecast for the zone.
    public var url: String
    /// Center URL.
    public var centerURL: String
    /// The credit to show with the block: "Avalanche forecast by <center> via avalanche.org", or "Avalanche forecast by Colorado Avalanche Information Center via avalanche.state.co.us" for a CAIC area.
    public var attribution: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        centerID: String, centerName: String, zoneID: Int, zoneName: String,
        dangerLevel: Int? =
            nil, dangerLabel: String? = nil, status: String, validFrom: Date? = nil,
        validUntil: Date? =
            nil, url: String, centerURL: String, attribution: String
    ) {
        self.centerID = centerID
        self.centerName = centerName
        self.zoneID = zoneID
        self.zoneName = zoneName
        self.dangerLevel = dangerLevel
        self.dangerLabel = dangerLabel
        self.status = status
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.url = url
        self.centerURL = centerURL
        self.attribution = attribution
    }

    enum CodingKeys: String, CodingKey {
        case centerID = "center_id"
        case centerName = "center_name"
        case zoneID = "zone_id"
        case zoneName = "zone_name"
        case dangerLevel = "danger_level"
        case dangerLabel = "danger_label"
        case status
        case validFrom = "valid_from"
        case validUntil = "valid_until"
        case url = "forecast_url"
        case centerURL = "center_url"
        case attribution
    }
}

/// Present only on a day part of which is a measurement -- the leading date, when the radar (MRMS radar-only) measured hours between its local midnight and the reference init -- and absent otherwise.
public struct MeasuredPrecipitation: Sendable, Hashable, Codable {
    /// Amount.
    public var amount: Double
    /// Through.
    public var through: Date

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        amount: Double, through: Date
    ) {
        self.amount = amount
        self.through = through
    }

    enum CodingKeys: String, CodingKey {
        case amount
        case through
    }
}
