// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// One forecast hour: its condition and the full ensemble distribution of every variable.
public struct TimeSeriesPoint: Sendable, Hashable, Codable {
    /// Valid time.
    public var validTime: Date
    /// Lead time hours.
    public var leadTimeHours: Int
    /// Whether this hour is nighttime at the forecast location.
    public var isNight: Bool
    /// A stable machine code to switch on -- the display text (`condition_text`) lowercased, each run of other characters one `_` (`partly_cloudy`, `rain_snow_mix_likely`).
    public var condition: WeatherCondition
    /// Human-readable weather condition for the hour, day/night aware.
    public var conditionText: String
    /// Icon hint (prefixed with night_ for nighttime).
    public var conditionIcon: ConditionIcon
    /// Whether the hour's gust is worth showing beside the wind -- its median at least 1.3 times the wind's median and at least 5 mph (2.2 m/s) above it.
    public var isGustNotable: Bool?
    /// Present only when precipitation > 0.
    public var precipitationType: PrecipType?
    /// Present only when a temperature inversion or cold pool is detected for this hour.
    public var inversion: InversionInfo?
    /// The hour's freezing level.
    public var freezingLevel: FreezingLevel?
    /// Ensemble.
    public var ensemble: EnsembleStats
    /// Present only with `?diagnostics=provenance` -- which post-processing rule shaped each variable this hour.
    public var provenance: HourProvenance?
    /// Model means.
    public var modelMeans: [ModelMean]?
    /// Per-member ensemble values, one `{id, members}` per model with members at this hour, in `model_run.models` order (D-8: it was an object keyed by model).
    public var members: [ModelMembers]?
    /// Members cumulative.
    public var membersCumulative: MembersCumulative?
    /// The HEADLINE's running precipitation total -- the sum of `ensemble.precipitation.mean` from the first served hour ("now") through this one, in the request's units.
    public var cumulativePrecipitation: Double?
    /// The headline's running snowfall total, as `cumulative_precipitation` over `ensemble.snowfall.mean`; present exactly when the hour serves `ensemble.snowfall`.
    public var cumulativeSnowfall: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        validTime: Date, leadTimeHours: Int, isNight: Bool, condition: WeatherCondition,
        conditionText: String, conditionIcon: ConditionIcon, isGustNotable: Bool? = nil,
        precipitationType: PrecipType? = nil, inversion: InversionInfo? = nil,
        freezingLevel: FreezingLevel? = nil, ensemble: EnsembleStats,
        provenance: HourProvenance? = nil, modelMeans: [ModelMean]? = nil,
        members: [ModelMembers]? = nil, membersCumulative: MembersCumulative? = nil,
        cumulativePrecipitation: Double? = nil, cumulativeSnowfall: Double? = nil
    ) {
        self.validTime = validTime
        self.leadTimeHours = leadTimeHours
        self.isNight = isNight
        self.condition = condition
        self.conditionText = conditionText
        self.conditionIcon = conditionIcon
        self.isGustNotable = isGustNotable
        self.precipitationType = precipitationType
        self.inversion = inversion
        self.freezingLevel = freezingLevel
        self.ensemble = ensemble
        self.provenance = provenance
        self.modelMeans = modelMeans
        self.members = members
        self.membersCumulative = membersCumulative
        self.cumulativePrecipitation = cumulativePrecipitation
        self.cumulativeSnowfall = cumulativeSnowfall
    }

    enum CodingKeys: String, CodingKey {
        case validTime = "valid_time"
        case leadTimeHours = "lead_time_hours"
        case isNight = "is_night"
        case condition
        case conditionText = "condition_text"
        case conditionIcon = "condition_icon"
        case isGustNotable = "gust_notable"
        case precipitationType = "precipitation_type"
        case inversion
        case freezingLevel = "freezing_level"
        case ensemble
        case provenance
        case modelMeans = "model_means"
        case members
        case membersCumulative = "members_cumulative"
        case cumulativePrecipitation = "cumulative_precipitation"
        case cumulativeSnowfall = "cumulative_snowfall"
    }
}

/// Per-member ensemble values, one `{id, members}` per model with members at this hour, in `model_run.models` order (D-8: it was an object keyed by model).
public struct ModelMembers: Sendable, Hashable, Codable {
    /// Id.
    public var id: String
    /// Members.
    public var members: [MemberForecast]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(id: String, members: [MemberForecast]) {
        self.id = id
        self.members = members
    }

    enum CodingKeys: String, CodingKey {
        case id
        case members
    }
}

/// One ensemble member's values at a single forecast hour.
public struct MemberForecast: Sendable, Hashable, Codable {
    /// The member's position on its model's ensemble axis, from 0.
    public var memberID: Int
    /// `null` when this member published nothing at this hour.
    public var temperature: Double?
    /// `null` when this member published nothing at this hour.
    public var precipitation: Double?
    /// How many hours `precipitation` (and `snowfall`) covers, ending at this hour.
    public var precipitationHours: Int?
    /// `null` when this member published nothing at this hour.
    public var windSpeed: Double?
    /// Wind direction.
    public var windDirection: Double?
    /// Snow level.
    public var snowLevel: Double?
    /// Snow-to-liquid ratio for this member (unitless).
    public var snowToLiquidRatio: Double?
    /// Per-member snowfall depth at the location's elevation, computed as `precipitation × effective_slr(slr, elevation, snow_level)`.
    public var snowfall: Double?
    /// This member's running precipitation total (mm / in) from the start of the served window through this hour.
    public var cumulativePrecipitation: Double?
    /// This member's running snowfall total (mm / in), by the same window and share rule as `cumulative_precipitation` over its `snowfall`.
    public var cumulativeSnowfall: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        memberID: Int, temperature: Double? = nil, precipitation: Double? = nil,
        precipitationHours: Int? = nil, windSpeed: Double? = nil, windDirection: Double? = nil,
        snowLevel: Double? = nil, snowToLiquidRatio: Double? = nil, snowfall: Double? = nil,
        cumulativePrecipitation: Double? = nil, cumulativeSnowfall: Double? = nil
    ) {
        self.memberID = memberID
        self.temperature = temperature
        self.precipitation = precipitation
        self.precipitationHours = precipitationHours
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.snowLevel = snowLevel
        self.snowToLiquidRatio = snowToLiquidRatio
        self.snowfall = snowfall
        self.cumulativePrecipitation = cumulativePrecipitation
        self.cumulativeSnowfall = cumulativeSnowfall
    }

    enum CodingKeys: String, CodingKey {
        case memberID = "member_id"
        case temperature
        case precipitation
        case precipitationHours = "precipitation_hours"
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case snowLevel = "snow_level"
        case snowToLiquidRatio = "slr"
        case snowfall
        case cumulativePrecipitation = "cumulative_precipitation"
        case cumulativeSnowfall = "cumulative_snowfall"
    }
}

/// The ensemble distribution of every variable for one hour, in the request's units.
public struct EnsembleStats: Sendable, Hashable, Codable {
    /// Temperature.
    public var temperature: Quantiles
    /// Apparent temperature, the NWS convention: the wind chill (NWS 2001.
    public var feelsLike: Quantiles?
    /// Dewpoint.
    public var dewpoint: Quantiles?
    /// Precipitation.
    public var precipitation: Quantiles
    /// Wind speed.
    public var windSpeed: Quantiles
    /// Peak gust (same unit as `wind_speed`).
    public var windGust: Quantiles?
    /// The wind direction as a CIRCULAR distribution: the resultant mean bearing, an offset-frame
    /// standard deviation, and the central 50 % and 90 % of the members as clockwise arcs.
    ///
    /// A sector's `to` may be numerically less than its `from` (an arc through north).
    public var windDirection: CircularStats
    /// Snow level.
    public var snowLevel: Quantiles?
    /// Snow-to-liquid ratio.
    public var snowToLiquidRatio: Quantiles?
    /// Hourly snowfall depth at the location's elevation (mm, or inches for imperial callers).
    public var snowfall: Quantiles?
    /// Cloud cover percentage (0-100%).
    public var cloudCover: Quantiles?
    /// Skin / ground surface temperature in the caller's temperature units.
    ///
    /// Served only when ``ForecastOptions/extraVariables`` includes ``ForecastExtraVariable/skinTemperature``.
    public var skinTemperature: Quantiles?
    /// Mean sea-level pressure: hPa for `metric` and `kelvin`, inHg for `imperial`.
    ///
    /// Served only when ``ForecastOptions/extraVariables`` includes ``ForecastExtraVariable/meanSeaLevelPressure``.
    public var meanSeaLevelPressure: Quantiles?
    /// Convective available potential energy, J/kg in every unit system.
    public var cape: Quantiles?
    /// Relative humidity, percent 0–100 in every unit system, computed like `feels_like`.
    public var relativeHumidity: Quantiles?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        temperature: Quantiles, feelsLike: Quantiles? = nil, dewpoint: Quantiles? = nil,
        precipitation: Quantiles, windSpeed: Quantiles, windGust: Quantiles? = nil,
        windDirection: CircularStats, snowLevel: Quantiles? = nil,
        snowToLiquidRatio: Quantiles? = nil, snowfall: Quantiles? = nil,
        cloudCover: Quantiles? = nil, skinTemperature: Quantiles? = nil,
        meanSeaLevelPressure: Quantiles? = nil, cape: Quantiles? = nil,
        relativeHumidity: Quantiles? = nil
    ) {
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.dewpoint = dewpoint
        self.precipitation = precipitation
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.windDirection = windDirection
        self.snowLevel = snowLevel
        self.snowToLiquidRatio = snowToLiquidRatio
        self.snowfall = snowfall
        self.cloudCover = cloudCover
        self.skinTemperature = skinTemperature
        self.meanSeaLevelPressure = meanSeaLevelPressure
        self.cape = cape
        self.relativeHumidity = relativeHumidity
    }

    enum CodingKeys: String, CodingKey {
        case temperature
        case feelsLike = "feels_like"
        case dewpoint
        case precipitation
        case windSpeed = "wind_speed"
        case windGust = "wind_gust"
        case windDirection = "wind_direction"
        case snowLevel = "snow_level"
        case snowToLiquidRatio = "slr"
        case snowfall
        case cloudCover = "cloud_cover"
        case skinTemperature = "skin_temperature"
        case meanSeaLevelPressure = "mslp"
        case cape
        case relativeHumidity = "relative_humidity"
    }
}

/// One model's own distribution for an hour (served with `models=true`, Pro).
public struct ModelMean: Sendable, Hashable, Codable {
    /// The model (`gefs`, `ifs_ens`, ...).
    public var id: String
    /// Absent when this model published nothing for the hour; never 0.
    public var temperature: Quantiles?
    /// Always absent for `aigefs`, which publishes no 2 m humidity and no surface pressure.
    public var dewpoint: Quantiles?
    /// Absent when this model published nothing for the hour; never 0.
    public var precipitation: Quantiles?
    /// Absent when this model published nothing for the hour; never 0.
    public var windSpeed: Quantiles?
    /// The model's own wind direction as a circular distribution; absent when this model
    /// published nothing for the hour.
    public var windDirection: CircularStats?
    /// Snow level.
    public var snowLevel: Quantiles?
    /// Snow-to-liquid ratio.
    public var snowToLiquidRatio: Quantiles?
    /// Snowfall.
    public var snowfall: Quantiles?
    /// `true` when this model did not publish at this lead and the stats above were interpolated from its two bracketing native steps.
    public var isInterpolated: Bool?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, temperature: Quantiles? = nil, dewpoint: Quantiles? = nil,
        precipitation: Quantiles? = nil, windSpeed: Quantiles? = nil,
        windDirection: CircularStats? = nil, snowLevel: Quantiles? = nil,
        snowToLiquidRatio: Quantiles? = nil, snowfall: Quantiles? = nil, isInterpolated: Bool? = nil
    ) {
        self.id = id
        self.temperature = temperature
        self.dewpoint = dewpoint
        self.precipitation = precipitation
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.snowLevel = snowLevel
        self.snowToLiquidRatio = snowToLiquidRatio
        self.snowfall = snowfall
        self.isInterpolated = isInterpolated
    }

    enum CodingKeys: String, CodingKey {
        case id
        case temperature
        case dewpoint
        case precipitation
        case windSpeed = "wind_speed"
        case windDirection = "wind_direction"
        case snowLevel = "snow_level"
        case snowToLiquidRatio = "slr"
        case snowfall
        case isInterpolated = "interpolated"
    }
}

/// Which serve-path branch produced this hour.
public struct HourProvenance: Sendable, Hashable, Codable {
    /// This hour sits strictly between two native model steps: its instantaneous values were linearly interpolated (plus a diurnal bulge), not read from a model step.
    public var isDensified: Bool?
    /// Variables corrected by a fitted NGR / truncated-NGR / censored-gamma model for this location, variable and lead-time bin.
    public var ngr: [ProvenanceVariable]?
    /// Variables served through the `inflate_around_mean` fallback because no fitted model was available for that lead-time bin.
    public var fallback: [ProvenanceVariable]?
    /// Variables at a point no fitted station reaches (none within 75 km), served from the fits of climatologically similar supplemental stations (same terrain class.
    public var borrowed: [ProvenanceVariable]?
    /// Variables whose percentile ladder was rebuilt as `N(mean, min_serve_sigma)` by the serve-time spread floor.
    public var spreadFloored: [ProvenanceVariable]?
    /// Variables whose low tail was truncated by the zero floor.
    public var floorClamped: [ProvenanceVariable]?
    /// Accumulation variables whose value at this hour is an even share of a wider accumulation, not an independently modelled hourly rate.
    public var bucketSplit: [ProvenanceVariable]?
    /// Variables whose blend included a contributor that supplied a two-parameter predictive distribution (a location and a scale) instead of ensemble members.
    public var distributionParameters: [ProvenanceVariable]?
    /// Variables whose spread was not measured by ANY contributor at this hour and was interpolated from the bracketing hours that did measure it.
    public var spreadInterpolated: [ProvenanceVariable]?
    /// Variables whose pool at this hour contains at least one contributor that did NOT publish at this lead.
    public var interpolatedContributor: [ProvenanceVariable]?
    /// Variables whose served `probability` was computed from a distribution recovered by METHOD OF MOMENTS from the hour's mean and standard deviation.
    public var momentMatchedFamily: [ProvenanceVariable]?
    /// Variables carried from the location's primary elevation to this point's elevation by the hour's OWN upper-air lapse rate (the profile bracketed the layer).
    public var lapseProfile: [ProvenanceVariable]?
    /// Variables carried from the location's primary elevation to this point's elevation by a CLIMATOLOGICAL lapse rate.
    public var lapseClimatology: [ProvenanceVariable]?
    /// Variables carried from the location's primary elevation to this point's elevation by the local PRISM precipitation–elevation regression.
    public var lapsePrism: [ProvenanceVariable]?
    /// Variables whose calibration fit was accepted and served, but whose fitted spread fell BELOW the serve-time spread band and was re-inflated to the band's low edge.
    public var spreadClampedLow: [ProvenanceVariable]?
    /// Variables whose calibration fit was accepted and served, but whose fitted spread rose ABOVE the serve-time spread band and was cut back to the band's high edge.
    public var spreadClampedHigh: [ProvenanceVariable]?
    /// Variables whose pool at this hour included a contributor that publishes a 10 m wind but no gust (the AI ensembles) and was dressed from its mean wind by the WMO in-land gust factor of 1.75 (Harper, Kepert & Ginger.
    public var gustDressed: [ProvenanceVariable]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        isDensified: Bool? = nil, ngr: [ProvenanceVariable]? = nil,
        fallback: [ProvenanceVariable]? = nil, borrowed: [ProvenanceVariable]? = nil,
        spreadFloored: [ProvenanceVariable]? = nil, floorClamped: [ProvenanceVariable]? = nil,
        bucketSplit: [ProvenanceVariable]? = nil,
        distributionParameters: [ProvenanceVariable]? = nil,
        spreadInterpolated: [ProvenanceVariable]? = nil,
        interpolatedContributor: [ProvenanceVariable]? = nil,
        momentMatchedFamily: [ProvenanceVariable]? = nil, lapseProfile: [ProvenanceVariable]? = nil,
        lapseClimatology: [ProvenanceVariable]? = nil, lapsePrism: [ProvenanceVariable]? = nil,
        spreadClampedLow: [ProvenanceVariable]? = nil,
        spreadClampedHigh: [ProvenanceVariable]? = nil, gustDressed: [ProvenanceVariable]? = nil
    ) {
        self.isDensified = isDensified
        self.ngr = ngr
        self.fallback = fallback
        self.borrowed = borrowed
        self.spreadFloored = spreadFloored
        self.floorClamped = floorClamped
        self.bucketSplit = bucketSplit
        self.distributionParameters = distributionParameters
        self.spreadInterpolated = spreadInterpolated
        self.interpolatedContributor = interpolatedContributor
        self.momentMatchedFamily = momentMatchedFamily
        self.lapseProfile = lapseProfile
        self.lapseClimatology = lapseClimatology
        self.lapsePrism = lapsePrism
        self.spreadClampedLow = spreadClampedLow
        self.spreadClampedHigh = spreadClampedHigh
        self.gustDressed = gustDressed
    }

    enum CodingKeys: String, CodingKey {
        case isDensified = "densified"
        case ngr
        case fallback
        case borrowed
        case spreadFloored = "spread_floored"
        case floorClamped = "floor_clamped"
        case bucketSplit = "bucket_split"
        case distributionParameters = "distribution_parameters"
        case spreadInterpolated = "spread_interpolated"
        case interpolatedContributor = "interpolated_contributor"
        case momentMatchedFamily = "moment_matched_family"
        case lapseProfile = "lapse_profile"
        case lapseClimatology = "lapse_climatology"
        case lapsePrism = "lapse_prism"
        case spreadClampedLow = "spread_clamped_low"
        case spreadClampedHigh = "spread_clamped_high"
        case gustDressed = "gust_dressed"
    }
}

/// Surface-based cold pool or elevated inversion detected from the model's vertical temperature profile.
public struct InversionInfo: Sendable, Hashable, Codable {
    /// `surface_shallow`: shallow (<300 m) surface-based inversion, common overnight in calm/clear conditions.
    public var kind: InversionKind
    /// Depth of the inversion layer in the caller's length units (meters for metric, feet for imperial).
    public var depth: Double
    /// Temperature difference driving the inversion in the caller's temperature units.
    public var strength: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(kind: InversionKind, depth: Double, strength: Double) {
        self.kind = kind
        self.depth = depth
        self.strength = strength
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case depth
        case strength
    }
}

/// Predicted precipitation type derived from the mean snow level, station elevation, and the hour's served (corrected) surface temperature and dewpoint, on the same rule.
public struct PrecipType: Sendable, Hashable, Codable {
    /// The categorical reading of `snow_probability`: `snow` only at 1 (and at most 2 °C), `rain_snow_mix` strictly between 0 and 1, `rain` or `freezing_rain` at 0.
    public var type: PrecipitationType
    /// Share of the hour's precipitation that falls as snow (0-1).
    public var snowProbability: Double
    /// `1 - snow_probability` (0-1).
    public var rainProbability: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(type: PrecipitationType, snowProbability: Double, rainProbability: Double) {
        self.type = type
        self.snowProbability = snowProbability
        self.rainProbability = rainProbability
    }

    enum CodingKeys: String, CodingKey {
        case type
        case snowProbability = "snow_probability"
        case rainProbability = "rain_probability"
    }
}
