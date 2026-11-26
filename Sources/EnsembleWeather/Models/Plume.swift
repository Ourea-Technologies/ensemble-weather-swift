// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// One served series' members in columns (`members=plume`).
public struct MemberPlume: Sendable, Hashable, Codable {
    /// Headline.
    public var headline: PlumeHeadline
    /// Bands.
    public var bands: PlumeBands
    /// One entry per model with members in the served window, in the order aifs, aigefs, gefs, ifs_ens, rrfs.
    public var models: [ModelColumns]
    /// (JSON `members`) The members as one unlabelled pool, in the `pool` view only.
    public var pool: PooledColumns?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        headline: PlumeHeadline, bands: PlumeBands, models: [ModelColumns],
        pool: PooledColumns? =
            nil
    ) {
        self.headline = headline
        self.bands = bands
        self.models = models
        self.pool = pool
    }

    enum CodingKeys: String, CodingKey {
        case headline
        case bands
        case models
        case pool = "members"
    }
}

/// The lines a plume draws over its members, at every served hour (`valid_time`): the blend's `temperature` and `snow_level` means (`ensemble.*.mean`) and its running totals (`cumulative_precipitation`, `cumulative_snowfall`: the "Ourea forecast" line), and that snowfall line at a 10:1 snow-to-liquid ratio (`cumulative_snowfall_10to1`), and its `wind_speed` mean and its snowfall in each 6 hours ...
public struct PlumeHeadline: Sendable, Hashable, Codable {
    /// Valid time.
    public var validTime: [Date]
    /// Temperature.
    public var temperature: [Double?]
    /// Snow level.
    public var snowLevel: [Double?]
    /// The blend's snow level on the NWS scale (`ensemble.snow_level_wet_bulb.mean`, the height of the 0.5 C wet-bulb); `snow_level` is the rain line.
    public var snowLevelWetBulb: [Double?]
    /// Cumulative precipitation.
    public var cumulativePrecipitation: [Double?]
    /// The hourly series' `cumulative_snowfall`: the running sum of the day cards' snowfall (`daily[].precipitation_display.snow_amount`), spread inside each local date by the blend's hourly mean snowfall, so at the end of each date served whole ...
    public var cumulativeSnowfall: [Double?]
    /// The headline's running snowfall at a fixed 10:1 snow-to-liquid ratio, in the snowfall units (in / mm), at the amount precision: each hour's served snowfall with its SLR (`ensemble.slr.mean`) replaced by 10 -- the liquid that falls as snow, ...
    public var cumulativeSnowfall10to1: [Double?]
    /// The forecast's hourly wind speed, the hourly series' `ensemble.wind_speed.mean`, in the wind unit (mph / km/h / m/s as `units` says) at the wind precision (0.1), at every served hour.
    public var windSpeed: [Double?]
    /// The forecast's snowfall in the 6 hours ending at each 00/06/12/18Z hour, in the snowfall units (in / mm) at the amount precision: the rise of `cumulative_snowfall` over `(valid_time - 6 h, valid_time]`, computed here so no client ...
    public var snowfall6Hours: [Double?]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        validTime: [Date], temperature: [Double?], snowLevel: [Double?],
        snowLevelWetBulb:
            [Double?], cumulativePrecipitation: [Double?], cumulativeSnowfall: [Double?],
        cumulativeSnowfall10to1: [Double?], windSpeed: [Double?], snowfall6Hours: [Double?]
    ) {
        self.validTime = validTime
        self.temperature = temperature
        self.snowLevel = snowLevel
        self.snowLevelWetBulb = snowLevelWetBulb
        self.cumulativePrecipitation = cumulativePrecipitation
        self.cumulativeSnowfall = cumulativeSnowfall
        self.cumulativeSnowfall10to1 = cumulativeSnowfall10to1
        self.windSpeed = windSpeed
        self.snowfall6Hours = snowfall6Hours
    }

    enum CodingKeys: String, CodingKey {
        case validTime = "valid_time"
        case temperature
        case snowLevel = "snow_level"
        case snowLevelWetBulb = "snow_level_wet_bulb"
        case cumulativePrecipitation = "cumulative_precipitation"
        case cumulativeSnowfall = "cumulative_snowfall"
        case cumulativeSnowfall10to1 = "cumulative_snowfall_10to1"
        case windSpeed = "wind_speed"
        case snowfall6Hours = "snowfall_6h"
    }
}

/// The members' distributions, at the served hours that carry at least one (`valid_time`; the synoptic hours in practice): `cumulative_precipitation` / `cumulative_snowfall` are the row form's `members_cumulative` (the spread of the members' running totals, never a sum of hourly percentiles), `temperature` / `snow_level` its `members_spread`, `precipitation_6h` / `snowfall_6h` its `members_6h` ...
public struct PlumeBands: Sendable, Hashable, Codable {
    /// Valid time.
    public var validTime: [Date]
    /// Cumulative precipitation.
    public var cumulativePrecipitation: BandColumns
    /// Cumulative snowfall.
    public var cumulativeSnowfall: BandColumns
    /// The members' running snowfall at 10:1 -- each member's snowfall with its SLR replaced by 10 (its snowing liquid x 10, every phase gate of its `snowfall` kept, the `snowfall_total_10to1` map's member rule), totalled as `cumulative_snowfall` ...
    public var cumulativeSnowfall10to1: BandColumns
    /// Temperature.
    public var temperature: BandColumns
    /// Snow level.
    public var snowLevel: BandColumns
    /// The row form's `members_spread.snow_level_wet_bulb` -- the members' snow level on the NWS scale, at the hours `snow_level` carries a band.
    public var snowLevelWetBulb: BandColumns
    /// Precipitation 6 h.
    public var precipitation6Hours: BandColumns
    /// Snowfall 6 h.
    public var snowfall6Hours: BandColumns
    /// Snow-to-liquid ratio.
    public var snowToLiquidRatio: BandColumns?
    /// `members_spread.wind_speed`.
    public var windSpeed: BandColumns?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        validTime: [Date], cumulativePrecipitation: BandColumns, cumulativeSnowfall: BandColumns,
        cumulativeSnowfall10to1: BandColumns, temperature: BandColumns, snowLevel: BandColumns,
        snowLevelWetBulb: BandColumns, precipitation6Hours: BandColumns,
        snowfall6Hours:
            BandColumns, snowToLiquidRatio: BandColumns? = nil, windSpeed: BandColumns? = nil
    ) {
        self.validTime = validTime
        self.cumulativePrecipitation = cumulativePrecipitation
        self.cumulativeSnowfall = cumulativeSnowfall
        self.cumulativeSnowfall10to1 = cumulativeSnowfall10to1
        self.temperature = temperature
        self.snowLevel = snowLevel
        self.snowLevelWetBulb = snowLevelWetBulb
        self.precipitation6Hours = precipitation6Hours
        self.snowfall6Hours = snowfall6Hours
        self.snowToLiquidRatio = snowToLiquidRatio
        self.windSpeed = windSpeed
    }

    enum CodingKeys: String, CodingKey {
        case validTime = "valid_time"
        case cumulativePrecipitation = "cumulative_precipitation"
        case cumulativeSnowfall = "cumulative_snowfall"
        case cumulativeSnowfall10to1 = "cumulative_snowfall_10to1"
        case temperature
        case snowLevel = "snow_level"
        case snowLevelWetBulb = "snow_level_wet_bulb"
        case precipitation6Hours = "precipitation_6h"
        case snowfall6Hours = "snowfall_6h"
        case snowToLiquidRatio = "slr"
        case windSpeed = "wind_speed"
    }
}

/// One band's statistics (Hyndman-Fan type 7 over the served member values), each an array aligned to `PlumeBands.valid_time`, `null` where the band is absent at that hour.
public struct BandColumns: Sendable, Hashable, Codable {
    /// Mean.
    public var mean: [Double?]
    /// Min.
    public var min: [Double?]
    /// The 10th percentile.
    public var p10: [Double?]
    /// The 25th percentile.
    public var p25: [Double?]
    /// The 50th percentile.
    public var p50: [Double?]?
    /// The 75th percentile.
    public var p75: [Double?]
    /// The 90th percentile.
    public var p90: [Double?]
    /// Max.
    public var max: [Double?]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        mean: [Double?], min: [Double?], p10: [Double?], p25: [Double?], p50: [Double?]? = nil,
        p75:
            [Double?], p90: [Double?], max: [Double?]
    ) {
        self.mean = mean
        self.min = min
        self.p10 = p10
        self.p25 = p25
        self.p50 = p50
        self.p75 = p75
        self.p90 = p90
        self.max = max
    }

    enum CodingKeys: String, CodingKey {
        case mean
        case min
        case p10
        case p25
        case p50
        case p75
        case p90
        case max
    }
}

/// The members as ONE unlabelled pool, for a caller without the plume's paid detail (Free and anonymous; `members_view: pool`).
public struct PooledColumns: Sendable, Hashable, Codable {
    /// Valid time.
    public var validTime: [Date]
    /// Temperature.
    public var temperature: [[Double?]]
    /// Precipitation.
    public var precipitation: [[Double?]]
    /// `[member][step]`: the hours each `precipitation` and `snowfall` value covers: the grid step (6), less where a member's first value covers less; `null` where the value is absent.
    public var precipitationHours: [[Int?]]
    /// Cumulative precipitation.
    public var cumulativePrecipitation: [[Double?]]
    /// Snow level.
    public var snowLevel: [[Double?]]
    /// Snow level wet bulb.
    public var snowLevelWetBulb: [[Double?]]
    /// Snowfall.
    public var snowfall: [[Double?]]
    /// Cumulative snowfall.
    public var cumulativeSnowfall: [[Double?]]
    /// Snow-to-liquid ratio.
    public var snowToLiquidRatio: [[Double?]]
    /// The rows (indices into every column) in `bands.cumulative_precipitation`'s fixed population, ascending: that band's `mean` is the mean of these rows' running totals.
    public var cumulativePrecipitationBandMembers: [Int]
    /// Likewise for `bands.cumulative_snowfall`.
    public var cumulativeSnowfallBandMembers: [Int]
    /// Likewise for `bands.cumulative_snowfall_10to1`.
    public var cumulativeSnowfall10to1BandMembers: [Int]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        validTime: [Date], temperature: [[Double?]], precipitation: [[Double?]],
        precipitationHours:
            [[Int?]], cumulativePrecipitation: [[Double?]], snowLevel: [[Double?]],
        snowLevelWetBulb:
            [[Double?]], snowfall: [[Double?]], cumulativeSnowfall: [[Double?]],
        snowToLiquidRatio:
            [[Double?]], cumulativePrecipitationBandMembers: [Int],
        cumulativeSnowfallBandMembers:
            [Int], cumulativeSnowfall10to1BandMembers: [Int]
    ) {
        self.validTime = validTime
        self.temperature = temperature
        self.precipitation = precipitation
        self.precipitationHours = precipitationHours
        self.cumulativePrecipitation = cumulativePrecipitation
        self.snowLevel = snowLevel
        self.snowLevelWetBulb = snowLevelWetBulb
        self.snowfall = snowfall
        self.cumulativeSnowfall = cumulativeSnowfall
        self.snowToLiquidRatio = snowToLiquidRatio
        self.cumulativePrecipitationBandMembers = cumulativePrecipitationBandMembers
        self.cumulativeSnowfallBandMembers = cumulativeSnowfallBandMembers
        self.cumulativeSnowfall10to1BandMembers = cumulativeSnowfall10to1BandMembers
    }

    enum CodingKeys: String, CodingKey {
        case validTime = "valid_time"
        case temperature
        case precipitation
        case precipitationHours = "precipitation_hours"
        case cumulativePrecipitation = "cumulative_precipitation"
        case snowLevel = "snow_level"
        case snowLevelWetBulb = "snow_level_wet_bulb"
        case snowfall
        case cumulativeSnowfall = "cumulative_snowfall"
        case snowToLiquidRatio = "slr"
        case cumulativePrecipitationBandMembers = "cumulative_precipitation_band_members"
        case cumulativeSnowfallBandMembers = "cumulative_snowfall_band_members"
        case cumulativeSnowfall10to1BandMembers = "cumulative_snowfall_10to1_band_members"
    }
}

/// One model's members over its NATIVE steps inside the served window (`valid_time`: the hours at which a member of the model carries a value -- every hour for RRFS, every sixth for the global ensembles; never padded to the hourly series).
public struct ModelColumns: Sendable, Hashable, Codable {
    /// ID.
    public var id: String
    /// Valid time.
    public var validTime: [Date]
    /// The members, ascending (`MemberForecast.member_id`).
    public var memberIDs: [Int]
    /// Temperature.
    public var temperature: [[Double?]]
    /// Precipitation.
    public var precipitation: [[Double?]]
    /// `[member][step]`: the hours each `precipitation` value covers; `null` where it is absent or its span unknown.
    public var precipitationHours: [[Int?]]
    /// Cumulative precipitation.
    public var cumulativePrecipitation: [[Double?]]
    /// Snow level.
    public var snowLevel: [[Double?]]
    /// `[Member][step]`, each member's `MemberForecast.snow_level_wet_bulb` (the snow level on the NWS scale); `null` exactly where its `snow_level` is.
    public var snowLevelWetBulb: [[Double?]]
    /// Snowfall.
    public var snowfall: [[Double?]]
    /// Cumulative snowfall.
    public var cumulativeSnowfall: [[Double?]]
    /// One value per `valid_time` step (not per member): the median of the model's members' `cumulative_snowfall` there (Hyndman-Fan type 7, as `bands`: the middle value, or the midpoint of the two middle ones; a single-member model's own total), ...
    public var cumulativeSnowfallP50: [Double?]
    /// As `cumulative_snowfall_p50`, over the members' running snowfall at 10:1 (see `PlumeBands.cumulative_snowfall_10to1`).
    public var cumulativeSnowfall10to1P50: [Double?]
    /// The model's mean lines.
    public var temperatureMean: [Double?]
    /// The mean of `precipitation` (see `temperature_mean`).
    public var precipitationMean: [Double?]
    /// The mean of `cumulative_precipitation` (see `temperature_mean`).
    public var cumulativePrecipitationMean: [Double?]
    /// The mean of `snow_level` (see `temperature_mean`).
    public var snowLevelMean: [Double?]
    /// The mean of `snow_level_wet_bulb` (see `temperature_mean`).
    public var snowLevelWetBulbMean: [Double?]
    /// The mean of `snowfall` (see `temperature_mean`).
    public var snowfallMean: [Double?]
    /// The mean of `cumulative_snowfall` (see `temperature_mean`), beside its median `cumulative_snowfall_p50`.
    public var cumulativeSnowfallMean: [Double?]
    /// The mean of the members' running snowfall at 10:1, beside `cumulative_snowfall_10to1_p50` (the members' 10:1 column itself is not served).
    public var cumulativeSnowfall10to1Mean: [Double?]
    /// The mean of `wind_speed` (see `temperature_mean`).
    public var windSpeedMean: [Double?]?
    /// Which of this model's `member_ids` are in `bands.cumulative_precipitation`, ascending.
    public var cumulativePrecipitationBandMemberIDs: [Int]
    /// As `cumulative_precipitation_band_member_ids`, for `bands.cumulative_snowfall`.
    public var cumulativeSnowfallBandMemberIDs: [Int]
    /// As `cumulative_precipitation_band_member_ids`, for `bands.cumulative_snowfall_10to1`.
    public var cumulativeSnowfall10to1BandMemberIDs: [Int]
    /// Pro (`members_view: full`) only; absent in the plume view.
    public var windSpeed: [[Double?]]?
    /// Pro only; absent in the plume view.
    public var windDirection: [[Double?]]?
    /// In both views.
    public var snowToLiquidRatio: [[Double?]]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, validTime: [Date], memberIDs: [Int], temperature: [[Double?]],
        precipitation:
            [[Double?]], precipitationHours: [[Int?]], cumulativePrecipitation: [[Double?]],
        snowLevel:
            [[Double?]], snowLevelWetBulb: [[Double?]], snowfall: [[Double?]],
        cumulativeSnowfall:
            [[Double?]], cumulativeSnowfallP50: [Double?], cumulativeSnowfall10to1P50: [Double?],
        temperatureMean: [Double?], precipitationMean: [Double?],
        cumulativePrecipitationMean:
            [Double?], snowLevelMean: [Double?], snowLevelWetBulbMean: [Double?],
        snowfallMean:
            [Double?], cumulativeSnowfallMean: [Double?], cumulativeSnowfall10to1Mean: [Double?],
        windSpeedMean: [Double?]? = nil, cumulativePrecipitationBandMemberIDs: [Int],
        cumulativeSnowfallBandMemberIDs: [Int], cumulativeSnowfall10to1BandMemberIDs: [Int],
        windSpeed: [[Double?]]? = nil, windDirection: [[Double?]]? = nil,
        snowToLiquidRatio:
            [[Double?]]? = nil
    ) {
        self.id = id
        self.validTime = validTime
        self.memberIDs = memberIDs
        self.temperature = temperature
        self.precipitation = precipitation
        self.precipitationHours = precipitationHours
        self.cumulativePrecipitation = cumulativePrecipitation
        self.snowLevel = snowLevel
        self.snowLevelWetBulb = snowLevelWetBulb
        self.snowfall = snowfall
        self.cumulativeSnowfall = cumulativeSnowfall
        self.cumulativeSnowfallP50 = cumulativeSnowfallP50
        self.cumulativeSnowfall10to1P50 = cumulativeSnowfall10to1P50
        self.temperatureMean = temperatureMean
        self.precipitationMean = precipitationMean
        self.cumulativePrecipitationMean = cumulativePrecipitationMean
        self.snowLevelMean = snowLevelMean
        self.snowLevelWetBulbMean = snowLevelWetBulbMean
        self.snowfallMean = snowfallMean
        self.cumulativeSnowfallMean = cumulativeSnowfallMean
        self.cumulativeSnowfall10to1Mean = cumulativeSnowfall10to1Mean
        self.windSpeedMean = windSpeedMean
        self.cumulativePrecipitationBandMemberIDs = cumulativePrecipitationBandMemberIDs
        self.cumulativeSnowfallBandMemberIDs = cumulativeSnowfallBandMemberIDs
        self.cumulativeSnowfall10to1BandMemberIDs = cumulativeSnowfall10to1BandMemberIDs
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.snowToLiquidRatio = snowToLiquidRatio
    }

    enum CodingKeys: String, CodingKey {
        case id
        case validTime = "valid_time"
        case memberIDs = "member_ids"
        case temperature
        case precipitation
        case precipitationHours = "precipitation_hours"
        case cumulativePrecipitation = "cumulative_precipitation"
        case snowLevel = "snow_level"
        case snowLevelWetBulb = "snow_level_wet_bulb"
        case snowfall
        case cumulativeSnowfall = "cumulative_snowfall"
        case cumulativeSnowfallP50 = "cumulative_snowfall_p50"
        case cumulativeSnowfall10to1P50 = "cumulative_snowfall_10to1_p50"
        case temperatureMean = "temperature_mean"
        case precipitationMean = "precipitation_mean"
        case cumulativePrecipitationMean = "cumulative_precipitation_mean"
        case snowLevelMean = "snow_level_mean"
        case snowLevelWetBulbMean = "snow_level_wet_bulb_mean"
        case snowfallMean = "snowfall_mean"
        case cumulativeSnowfallMean = "cumulative_snowfall_mean"
        case cumulativeSnowfall10to1Mean = "cumulative_snowfall_10to1_mean"
        case windSpeedMean = "wind_speed_mean"
        case cumulativePrecipitationBandMemberIDs = "cumulative_precipitation_band_member_ids"
        case cumulativeSnowfallBandMemberIDs = "cumulative_snowfall_band_member_ids"
        case cumulativeSnowfall10to1BandMemberIDs = "cumulative_snowfall_10to1_band_member_ids"
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case snowToLiquidRatio = "slr"
    }
}
