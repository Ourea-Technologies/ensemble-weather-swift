// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// Daily summary keyed by one local calendar date (the location's own US timezone, not always Pacific).
public struct DailyForecast: Sendable, Hashable, Codable {
    /// Date.
    public var date: String
    /// A stable machine code to switch on -- the display text (`condition_text`) lowercased, each run of other characters one `_` (`partly_cloudy`, `rain_snow_mix_likely`).
    public var condition: Condition
    /// Human-readable weather condition for the day — a daytime label, on the same rule as the hourly `condition`.
    public var conditionText: String
    /// Machine-readable icon hint for frontends.
    public var conditionIcon: ConditionIcon
    /// The day's precipitation type, `nil` when `precipitation_occurrence_probability` is under 0.15.
    public var precipitationType: PrecipitationType?
    /// Calendar-day maximum: the max over local midnight to midnight on `date` (earlier releases: 06:00-18:00 only).
    public var high: Quantiles
    /// Calendar-day minimum: the min over local midnight to midnight on `date`, the same hours as `high` (earlier releases.
    public var low: Quantiles
    /// Calendar-day maximum of the hourly `feels_like` (the NWS apparent temperature), per member.
    public var feelsLikeHigh: Quantiles?
    /// Calendar-day minimum of the hourly `feels_like` (the NWS apparent temperature), per member.
    public var feelsLikeLow: Quantiles?
    /// The day's total precipitation.
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
    /// The day total GIVEN a wet day (total >= the `daily_precipitation_occurrence_probability` threshold, 1.0 mm): the upper part of the day-total distribution, renormalized.
    public var totalPrecipitationIfWet: Quantiles?
    /// The day's snowfall given a snowy day (>= the `daily_snow_probability` threshold, 2.5 mm), as `total_precipitation_if_wet`.
    public var totalSnowfallIfWet: Quantiles?
    /// How to display the day's precipitation.
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
    /// Present only on a part day -- the leading date of a run whose reference init falls after its local midnight (today, for most cycles) -- and absent on a whole day.
    public var coveredFrom: Date?
    /// Present only on a day part of which is a measurement -- the leading date, when the radar (MRMS radar-only) measured hours between its local midnight and the reference init -- and absent otherwise.
    public var measuredPrecipitation: MeasuredPrecipitation?
    /// The day's snow character.
    public var snowCharacter: SnowCharacter?
    /// The day's snow-to-liquid ratio, to one decimal: the ratio `snow_character` classifies on a day that is not `wet`.
    public var snowToLiquidRatio: Double?
    /// The snow level over the day's wet hours -- the hours the day's `precipitation_type` reads (the hours that serve a precipitation type): the lowest and highest hourly `ensemble.snow_level.mean` and their precipitation-weighted mean.
    public var snowLevelRange: SnowLevelRange?
    /// The day's snow level on the NWS scale -- the height of the 0.5 C wet-bulb.
    public var snowLevelWetBulb: Quantiles?
    /// `Snow_level_range` on the NWS scale -- over the same wet hours, the lowest and highest hourly `ensemble.snow_level_wet_bulb.mean` and their precipitation-weighted mean (which is `snow_level_wet_bulb.mean`).
    public var snowLevelWetBulbRange: SnowLevelRange?
    /// Normal.
    public var normal: DayNormal?
    /// Departure.
    public var departure: DayDeparture?
    /// Percentile.
    public var percentile: DayPercentile?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        date: String, condition: Condition, conditionText: String,
        conditionIcon: ConditionIcon, precipitationType: PrecipitationType? = nil, high: Quantiles,
        low: Quantiles, feelsLikeHigh: Quantiles? = nil, feelsLikeLow: Quantiles? = nil,
        totalPrecipitation: Quantiles, totalSnowfall: Quantiles? = nil,
        precipitationProbability: Double, precipitationOccurrenceProbability: Double,
        snowProbability: Double, snowLevelMean: Double? = nil, snowLevel: Quantiles? = nil,
        totalPrecipitationIfWet: Quantiles? = nil, totalSnowfallIfWet: Quantiles? = nil,
        precipitationDisplay: PrecipDisplay, cloudCoverMean: Double? = nil, wind: DailyWind? = nil,
        stormOrientation: StormOrientation? = nil, stormOrientationDescription: String? = nil,
        astro: DailyAstro, temperatureClimatology: DayClimatology? = nil,
        coveredFrom: Date? = nil,
        measuredPrecipitation: MeasuredPrecipitation? = nil,
        snowCharacter: SnowCharacter? = nil,
        snowToLiquidRatio: Double? = nil,
        snowLevelRange: SnowLevelRange? = nil,
        snowLevelWetBulb: Quantiles? = nil,
        snowLevelWetBulbRange: SnowLevelRange? = nil,
        normal: DayNormal? = nil,
        departure: DayDeparture? = nil,
        percentile: DayPercentile? = nil
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
        self.coveredFrom = coveredFrom
        self.measuredPrecipitation = measuredPrecipitation
        self.snowCharacter = snowCharacter
        self.snowToLiquidRatio = snowToLiquidRatio
        self.snowLevelRange = snowLevelRange
        self.snowLevelWetBulb = snowLevelWetBulb
        self.snowLevelWetBulbRange = snowLevelWetBulbRange
        self.normal = normal
        self.departure = departure
        self.percentile = percentile
    }

    enum CodingKeys: String, CodingKey {
        case date
        case condition
        case conditionText = "condition_text"
        case conditionIcon = "condition_icon"
        case precipitationType = "precipitation_type"
        case high
        case low
        case feelsLikeHigh = "feels_like_high"
        case feelsLikeLow = "feels_like_low"
        case totalPrecipitation = "total_precipitation"
        case totalSnowfall = "total_snowfall"
        case precipitationProbability = "precipitation_probability"
        case precipitationOccurrenceProbability = "precipitation_occurrence_probability"
        case snowProbability = "snow_probability"
        case snowLevelMean = "snow_level_mean"
        case snowLevel = "snow_level"
        case totalPrecipitationIfWet = "total_precipitation_if_wet"
        case totalSnowfallIfWet = "total_snowfall_if_wet"
        case precipitationDisplay = "precipitation_display"
        case cloudCoverMean = "cloud_cover_mean"
        case wind
        case stormOrientation = "storm_orientation"
        case stormOrientationDescription = "storm_orientation_description"
        case astro
        case temperatureClimatology = "temperature_climatology"
        case coveredFrom = "covered_from"
        case measuredPrecipitation = "measured_precipitation"
        case snowCharacter = "snow_character"
        case snowToLiquidRatio = "slr"
        case snowLevelRange = "snow_level_range"
        case snowLevelWetBulb = "snow_level_wet_bulb"
        case snowLevelWetBulbRange = "snow_level_wet_bulb_range"
        case normal
        case departure
        case percentile
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
    /// The day's mean snowfall, the served `total_snowfall.mean`, in the request's snow units.
    public var snowAmount: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        kind: PrecipitationDisplayKind, chance: Double, amount: Double? = nil,
        snowAmount: Double? = nil
    ) {
        self.kind = kind
        self.chance = chance
        self.amount = amount
        self.snowAmount = snowAmount
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case chance
        case amount
        case snowAmount = "snow_amount"
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
    /// (JSON `elevation`) Elevation.
    public var height: Double
    /// Where this elevation was forecast — its own coordinates when the catalog has them, else the location's.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// The full hourly series at this elevation — the same shape and the same code as `forecast.timeseries` (never with `model_means`).
    public var hourly: [TimeSeriesPoint]?
    /// Daily summaries at this elevation — the same daily build as `forecast.daily` (omitted when empty).
    public var daily: [DailyForecast]?
    /// Rolling snow totals at this elevation, as `forecast.snow_outlook` (omitted when there are no dailies).
    public var snowOutlook: SnowOutlook?
    /// What the place is called, as `location.elevations[].display_name`; absent where the catalog has no name for it.
    public var displayName: String?
    /// A named spot's own nearby observation sensors, ranked around ITS point and elevation as the location's `nearest_sensors` are around the location's.
    public var nearestSensors: [NearestSensor]?
    /// -- rolling liquid totals at this elevation, as `forecast.precipitation_outlook`.
    public var precipitationOutlook: PrecipOutlook?
    /// This elevation's members in columns, as `forecast.plume` -- present only with `members=plume`, instead of `hourly`, `daily`, `snow_outlook` and `precipitation_outlook`.
    public var plume: MemberPlume?
    /// The snow on the ground at this elevation, as the response's own `snow_on_ground`; absent where no snowpack column runs for it.
    public var snowOnGround: SnowOnGround?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        name: String, height: Double, latitude: Double, longitude: Double,
        hourly: [TimeSeriesPoint]? = nil,
        daily: [DailyForecast]? = nil, snowOutlook: SnowOutlook? = nil,
        displayName: String? = nil,
        nearestSensors: [NearestSensor]? = nil,
        precipitationOutlook: PrecipOutlook? = nil,
        plume: MemberPlume? = nil,
        snowOnGround: SnowOnGround? = nil
    ) {
        self.name = name
        self.height = height
        self.latitude = latitude
        self.longitude = longitude
        self.hourly = hourly
        self.daily = daily
        self.snowOutlook = snowOutlook
        self.displayName = displayName
        self.nearestSensors = nearestSensors
        self.precipitationOutlook = precipitationOutlook
        self.plume = plume
        self.snowOnGround = snowOnGround
    }

    enum CodingKeys: String, CodingKey {
        case name
        case height = "elevation"
        case latitude = "lat"
        case longitude = "lon"
        case hourly
        case daily
        case snowOutlook = "snow_outlook"
        case displayName = "display_name"
        case nearestSensors = "nearest_sensors"
        case precipitationOutlook = "precipitation_outlook"
        case plume
        case snowOnGround = "snow_on_ground"
    }
}
