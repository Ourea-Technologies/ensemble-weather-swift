// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// Daily summary keyed by one local calendar date (the location's own US timezone, not always Pacific).
public struct DailyForecast: Sendable, Hashable, Codable {
    /// Date.
    public var date: String
    /// A stable machine code to switch on -- the display text (`condition_text`) lowercased, each run of other characters one `_` (`partly_cloudy`, `rain_snow_mix_likely`).
    public var condition: WeatherCondition
    /// Human-readable weather condition for the day — a daytime label, on the same rule as the hourly `condition`.
    public var conditionText: String
    /// Machine-readable icon hint for frontends.
    public var conditionIcon: ConditionIcon
    /// The day's precipitation type, `null` when `precip_occurrence_probability` is under 0.15.
    public var precipitationType: PrecipitationType?
    /// Calendar-day maximum: the max over local midnight to midnight on `date` (earlier releases: 06:00-18:00 only).
    public var high: Quantiles
    /// Calendar-day minimum: the min over local midnight to midnight on `date`, the same hours as `high` (earlier releases.
    public var low: Quantiles
    /// Calendar-day maximum of the hourly `feels_like` (the NWS apparent temperature), per member.
    public var feelsLikeHigh: Quantiles?
    /// Calendar-day minimum of the hourly `feels_like` (the NWS apparent temperature), per member.
    public var feelsLikeLow: Quantiles?
    /// The daily UTCI maximum, built like `feels_like_high` from the hourly `feels_like_utci`.
    public var feelsLikeUTCIHigh: Quantiles?
    /// The daily UTCI minimum, built like `feels_like_low` from the hourly `feels_like_utci`.
    public var feelsLikeUTCILow: Quantiles?
    /// Total precip.
    public var totalPrecipitation: Quantiles
    /// Total snowfall.
    public var totalSnowfall: Quantiles?
    /// The chance the day's total is at least 2.5 mm (0-1): the headline number, a tenth of an inch or more.
    public var precipitationProbability: Double
    /// The chance the day's total is at least 1.0 mm (0-1): that it precipitates at all.
    public var precipitationOccurrenceProbability: Double
    /// The chance the day's snowfall is at least 2.5 mm (0-1).
    public var snowProbability: Double
    /// Snow level mean.
    public var snowLevelMean: Double?
    /// The day's snow level -- each rank the mean of the day's hourly ranks (the day-mean's distribution under the rank coherence the day totals assume).
    public var snowLevel: Quantiles?
    /// The day total GIVEN a wet day (total >= the `daily_precip_occurrence_probability` threshold, 1.0 mm): the upper part of the day-total distribution, renormalized.
    public var totalPrecipitationIfWet: Quantiles?
    /// The day's snowfall given a snowy day (>= the `daily_snow_probability` threshold, 2.5 mm), as `total_precip_if_wet`.
    public var totalSnowfallIfWet: Quantiles?
    /// Precip display.
    public var precipitationDisplay: PrecipDisplay
    /// Average cloud cover for the day (0-100%).
    public var cloudCoverMean: Double?
    /// Daily wind summary.
    public var wind: DailyWind?
    /// How SLR changes over a snow storm.
    public var stormOrientation: StormOrientation?
    /// Plain-language companion to `storm_orientation`, suitable for direct display.
    public var stormOrientationDescription: String?
    /// Astro.
    public var astro: DailyAstro
    /// Temperature climatology.
    public var temperatureClimatology: DayClimatology?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        date: String, condition: WeatherCondition, conditionText: String,
        conditionIcon: ConditionIcon, precipitationType: PrecipitationType? = nil, high: Quantiles,
        low: Quantiles, feelsLikeHigh: Quantiles? = nil, feelsLikeLow: Quantiles? = nil,
        feelsLikeUTCIHigh: Quantiles? = nil, feelsLikeUTCILow: Quantiles? = nil,
        totalPrecipitation: Quantiles, totalSnowfall: Quantiles? = nil,
        precipitationProbability: Double, precipitationOccurrenceProbability: Double,
        snowProbability: Double, snowLevelMean: Double? = nil, snowLevel: Quantiles? = nil,
        totalPrecipitationIfWet: Quantiles? = nil, totalSnowfallIfWet: Quantiles? = nil,
        precipitationDisplay: PrecipDisplay, cloudCoverMean: Double? = nil, wind: DailyWind? = nil,
        stormOrientation: StormOrientation? = nil, stormOrientationDescription: String? = nil,
        astro: DailyAstro, temperatureClimatology: DayClimatology? = nil
    ) {
        self.date = date
        self.condition = condition
        self.conditionText = conditionText
        self.conditionIcon = conditionIcon
        self.precipitationType = precipitationType
        self.high = high
        self.low = low
        self.feelsLikeHigh = feelsLikeHigh
        self.feelsLikeLow = feelsLikeLow
        self.feelsLikeUTCIHigh = feelsLikeUTCIHigh
        self.feelsLikeUTCILow = feelsLikeUTCILow
        self.totalPrecipitation = totalPrecipitation
        self.totalSnowfall = totalSnowfall
        self.precipitationProbability = precipitationProbability
        self.precipitationOccurrenceProbability = precipitationOccurrenceProbability
        self.snowProbability = snowProbability
        self.snowLevelMean = snowLevelMean
        self.snowLevel = snowLevel
        self.totalPrecipitationIfWet = totalPrecipitationIfWet
        self.totalSnowfallIfWet = totalSnowfallIfWet
        self.precipitationDisplay = precipitationDisplay
        self.cloudCoverMean = cloudCoverMean
        self.wind = wind
        self.stormOrientation = stormOrientation
        self.stormOrientationDescription = stormOrientationDescription
        self.astro = astro
        self.temperatureClimatology = temperatureClimatology
    }

    enum CodingKeys: String, CodingKey {
        case date
        case condition
        case conditionText = "condition_text"
        case conditionIcon = "condition_icon"
        case precipitationType = "precip_type"
        case high
        case low
        case feelsLikeHigh = "feels_like_high"
        case feelsLikeLow = "feels_like_low"
        case feelsLikeUTCIHigh = "feels_like_utci_high"
        case feelsLikeUTCILow = "feels_like_utci_low"
        case totalPrecipitation = "total_precip"
        case totalSnowfall = "total_snowfall"
        case precipitationProbability = "precip_probability"
        case precipitationOccurrenceProbability = "precip_occurrence_probability"
        case snowProbability = "snow_probability"
        case snowLevelMean = "snow_level_mean"
        case snowLevel = "snow_level"
        case totalPrecipitationIfWet = "total_precip_if_wet"
        case totalSnowfallIfWet = "total_snowfall_if_wet"
        case precipitationDisplay = "precip_display"
        case cloudCoverMean = "cloud_cover_mean"
        case wind
        case stormOrientation = "storm_orientation"
        case stormOrientationDescription = "storm_orientation_description"
        case astro
        case temperatureClimatology = "temperature_climatology"
    }
}

/// Daily wind summary.
public struct DailyWind: Sendable, Hashable, Codable {
    /// Wind severity classification based on peak gust/speed.
    public var status: WindStatus?
    /// Peak wind for the day (mph imperial, m/s metric): the expected peak.
    public var peakSpeed: Double?
    /// The 90th-percentile counterpart of peak_speed (the maximum over the day's hours of the hourly gust p90), a "gusts could reach" upper band.
    public var peakSpeedP90: Double?
    /// Whether peak_speed is from gust data (true) or sustained wind (false).
    public var isGust: Bool?
    /// Peak sustained wind for the day (mph imperial, m/s metric), independent of gust.
    public var sustainedSpeed: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        status: WindStatus? = nil, peakSpeed: Double? = nil, peakSpeedP90: Double? = nil,
        isGust: Bool? = nil, sustainedSpeed: Double? = nil
    ) {
        self.status = status
        self.peakSpeed = peakSpeed
        self.peakSpeedP90 = peakSpeedP90
        self.isGust = isGust
        self.sustainedSpeed = sustainedSpeed
    }

    enum CodingKeys: String, CodingKey {
        case status
        case peakSpeed = "peak_speed"
        case peakSpeedP90 = "peak_speed_p90"
        case isGust = "is_gust"
        case sustainedSpeed = "sustained_speed"
    }
}

/// A day's precipitation headline, chosen by the server so every client says the same thing.
public struct PrecipDisplay: Sendable, Hashable, Codable {
    /// Kind.
    public var kind: PrecipitationDisplayKind
    /// Chance.
    public var chance: Double
    /// Amount.
    public var amount: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(kind: PrecipitationDisplayKind, chance: Double, amount: Double? = nil) {
        self.kind = kind
        self.chance = chance
        self.amount = amount
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case chance
        case amount
    }
}

/// The day's sun and moon, grouped (they were flat keys on the daily row, beside a zodiac sign that is no longer served).
public struct DailyAstro: Sendable, Hashable, Codable {
    /// Sunrise time at the forecast location, ISO-8601 UTC.
    public var sunrise: Date?
    /// Sunset time at the forecast location, ISO-8601 UTC.
    public var sunset: Date?
    /// Eight-way moon phase for the date.
    public var moonPhase: MoonPhase
    /// Fraction of the moon's disc that's illuminated (0.0 = new, 1.0 = full).
    public var moonIllumination: Double
    /// Astronomical season by equinox/solstice (not meteorological).
    public var astronomicalSeason: AstronomicalSeason

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        sunrise: Date? = nil, sunset: Date? = nil, moonPhase: MoonPhase, moonIllumination: Double,
        astronomicalSeason: AstronomicalSeason
    ) {
        self.sunrise = sunrise
        self.sunset = sunset
        self.moonPhase = moonPhase
        self.moonIllumination = moonIllumination
        self.astronomicalSeason = astronomicalSeason
    }

    enum CodingKeys: String, CodingKey {
        case sunrise
        case sunset
        case moonPhase = "moon_phase"
        case moonIllumination = "moon_illumination"
        case astronomicalSeason = "astronomical_season"
    }
}

/// Served as a daily row's `temperature_climatology` (it was `climatology`, which did not name its variable).
public struct DayClimatology: Sendable, Hashable, Codable {
    /// All-hours seasonal mean temperature.
    public var mean: Double
    /// Seasonal standard deviation (includes the diurnal range).
    public var standardDeviation: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(mean: Double, standardDeviation: Double) {
        self.mean = mean
        self.standardDeviation = standardDeviation
    }

    enum CodingKeys: String, CodingKey {
        case mean
        case standardDeviation = "std"
    }
}

/// Forecast at one of a location's additional elevations (ski-area base / mid / summit).
public struct ElevationForecast: Sendable, Hashable, Codable {
    /// Name.
    public var name: String
    /// Elevation.
    public var elevation: Double
    /// Whether this is the default elevation to show in the UI.
    public var isDefault: Bool?
    /// Where this elevation was forecast — its own coordinates when the catalog has them, else the location's.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// LEGACY compact hourly points, derived from `hourly` (kept for clients that read only these; new clients should read `hourly`).
    public var timeseries: [ElevationHour]?
    /// The full hourly series at this elevation — the same shape and the same code as `forecast.timeseries` (never with `model_means`).
    public var hourly: [TimeSeriesPoint]?
    /// Daily summaries at this elevation — the same daily build as `forecast.daily` (omitted when empty).
    public var daily: [DailyForecast]?
    /// Rolling snow totals at this elevation, as `forecast.snow_outlook` (omitted when there are no dailies).
    public var snowOutlook: SnowOutlook?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        name: String, elevation: Double, isDefault: Bool? = nil, latitude: Double,
        longitude: Double, timeseries: [ElevationHour]? = nil, hourly: [TimeSeriesPoint]? = nil,
        daily: [DailyForecast]? = nil, snowOutlook: SnowOutlook? = nil
    ) {
        self.name = name
        self.elevation = elevation
        self.isDefault = isDefault
        self.latitude = latitude
        self.longitude = longitude
        self.timeseries = timeseries
        self.hourly = hourly
        self.daily = daily
        self.snowOutlook = snowOutlook
    }

    enum CodingKeys: String, CodingKey {
        case name
        case elevation
        case isDefault = "default"
        case latitude = "lat"
        case longitude = "lon"
        case timeseries
        case hourly
        case daily
        case snowOutlook = "snow_outlook"
    }
}

/// LEGACY compact hourly points, derived from `hourly` (kept for clients that read only these; new clients should read `hourly`).
public struct ElevationHour: Sendable, Hashable, Codable {
    /// Valid time.
    public var validTime: Date
    /// Lead time hours.
    public var leadTimeHours: Int
    /// Temperature.
    public var temperature: Quantiles
    /// Elevation minus snow level (positive = above the snow level = snow expected; negative = below it = rain).
    public var snowLevelDelta: Quantiles?
    /// The variant's served wind speed (`hourly[].ensemble.wind_speed`).
    public var windSpeed: Quantiles?
    /// The variant's served gust (`hourly[].ensemble.wind_gust`); absent at lead 0, as on the primary.
    public var windGust: Quantiles?
    /// The variant's served hourly precipitation (`hourly[].ensemble.precipitation`), the same shape as the primary's, including the occurrence `probability`.
    public var precipitation: Quantiles
    /// The machine code, as `TimeSeriesPoint.condition`.
    public var condition: String
    /// The variant's served condition (`hourly[].condition`), derived as for the primary's hour (see `TimeSeriesPoint.condition`).
    public var conditionText: String
    /// The variant's served icon hint (`hourly[].condition_icon`; see `TimeSeriesPoint.condition_icon`).
    public var conditionIcon: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        validTime: Date, leadTimeHours: Int, temperature: Quantiles,
        snowLevelDelta: Quantiles? = nil, windSpeed: Quantiles? = nil, windGust: Quantiles? = nil,
        precipitation: Quantiles, condition: String, conditionText: String, conditionIcon: String
    ) {
        self.validTime = validTime
        self.leadTimeHours = leadTimeHours
        self.temperature = temperature
        self.snowLevelDelta = snowLevelDelta
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.precipitation = precipitation
        self.condition = condition
        self.conditionText = conditionText
        self.conditionIcon = conditionIcon
    }

    enum CodingKeys: String, CodingKey {
        case validTime = "valid_time"
        case leadTimeHours = "lead_time_hours"
        case temperature
        case snowLevelDelta = "snow_level_delta"
        case windSpeed = "wind_speed"
        case windGust = "wind_gust"
        case precipitation
        case condition
        case conditionText = "condition_text"
        case conditionIcon = "condition_icon"
    }
}
