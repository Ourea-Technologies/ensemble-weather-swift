// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// Current conditions at a location or point: the blended reading, nearby sensors, active alerts and the nowcast band.
public struct CurrentConditionsResponse: Sendable, Hashable, Codable {
    /// The one location reference (`slug` and `type` are `nil` for a point).
    public var location: LocationReference
    /// Active NWS watches/warnings/advisories for this location (zone- and polygon-matched).
    public var alerts: [ActiveAlert]
    /// Timestamp of the alerts snapshot backing this response (refreshed ~60s; staleness beyond a few minutes means the alerts pipeline is degraded).
    public var alertsAsOf: Date
    /// Sensor count.
    public var sensorCount: Int
    /// Each sensor's latest reading set, in the request's `units`.
    public var sensors: [SensorObservation]
    /// "Right now" flattened: the `nowcast_hours` hour nearest the request time, read field by field (see the schema).
    public var current: CurrentConditions?
    /// When this overlay was assembled (the request time); the `nowcast_hours` window is relative to it.
    public var asOf: Date
    /// The reference init of the cycle the band was read from (null when no cycle is servable).
    public var modelRunInitializedAt: Date?
    /// The obs-blended forecast hours with valid times in [as_of − 1 h, as_of + 10 h], shaped like the forecast's `timeseries` points; null when no cycle is servable.
    public var nowcastHours: [TimeSeriesPoint]?
    /// Units.
    public var units: UnitSystem
    /// Attribution.
    public var attribution: ResponseAttribution
    /// The live nowcast sources `nowcast_hours` and `current` were built without because their read did not answer in time (or failed).
    public var nowcastUnavailable: [NowcastSource]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        location: LocationReference, alerts: [ActiveAlert], alertsAsOf: Date, sensorCount: Int,
        sensors: [SensorObservation], current: CurrentConditions? = nil, asOf: Date,
        modelRunInitializedAt: Date? = nil, nowcastHours: [TimeSeriesPoint]? = nil,
        units: UnitSystem, attribution: ResponseAttribution,
        nowcastUnavailable: [NowcastSource]? = nil
    ) {
        self.location = location
        self.alerts = alerts
        self.alertsAsOf = alertsAsOf
        self.sensorCount = sensorCount
        self.sensors = sensors
        self.current = current
        self.asOf = asOf
        self.modelRunInitializedAt = modelRunInitializedAt
        self.nowcastHours = nowcastHours
        self.units = units
        self.attribution = attribution
        self.nowcastUnavailable = nowcastUnavailable
    }

    enum CodingKeys: String, CodingKey {
        case location
        case alerts
        case alertsAsOf = "alerts_as_of"
        case sensorCount = "sensor_count"
        case sensors
        case current
        case asOf = "as_of"
        case modelRunInitializedAt = "model_run_initialized_at"
        case nowcastHours = "nowcast_hours"
        case units
        case attribution
        case nowcastUnavailable = "nowcast_unavailable"
    }
}

/// "Right now" as one flat object: a view of ONE served hourly point, never a second forecast.
public struct CurrentConditions: Sendable, Hashable, Codable {
    /// `valid_time` of the hour the block is read from.
    public var time: Date
    /// °C (metric), °F (imperial), K (kelvin).
    public var temperature: Double
    /// Same unit as `temperature`.
    public var feelsLike: Double?
    /// The hour's stable condition code, as `TimeSeriesPoint.condition` (`partly_cloudy`).
    public var condition: String
    /// The display text for `condition`, as `TimeSeriesPoint.condition_text`.
    public var conditionText: String
    /// The hour's icon hint, as `TimeSeriesPoint.condition_icon`.
    public var conditionIcon: ConditionIcon
    /// M/s (metric, kelvin) or mph (imperial).
    public var windSpeed: Double
    /// Same unit as `wind_speed`.
    public var windGust: Double?
    /// Degrees clockwise from north, direction the wind blows FROM.
    public var windDirection: Double
    /// Relative humidity, percent (0–100).
    public var relativeHumidity: Double?
    /// Same unit as `temperature`.
    public var dewpoint: Double?
    /// The hour's `ensemble.precipitation.probability` (0–1).
    public var precipitationProbability: Double?
    /// `nowcast` — at least one live observation (surface station, MRMS radar, GOES cloud mask) carried weight at this hour.
    public var source: ConditionsSource
    /// The surface station whose reading anchored temperature, dewpoint and wind at this hour.
    public var station: ConditionsStation?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        time: Date, temperature: Double, feelsLike: Double? = nil, condition: String,
        conditionText: String, conditionIcon: ConditionIcon, windSpeed: Double,
        windGust: Double? = nil,
        windDirection: Double, relativeHumidity: Double? = nil, dewpoint: Double? = nil,
        precipitationProbability: Double? = nil, source: ConditionsSource,
        station: ConditionsStation? = nil
    ) {
        self.time = time
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.condition = condition
        self.conditionText = conditionText
        self.conditionIcon = conditionIcon
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.windDirection = windDirection
        self.relativeHumidity = relativeHumidity
        self.dewpoint = dewpoint
        self.precipitationProbability = precipitationProbability
        self.source = source
        self.station = station
    }

    enum CodingKeys: String, CodingKey {
        case time
        case temperature
        case feelsLike = "feels_like"
        case condition
        case conditionText = "condition_text"
        case conditionIcon = "condition_icon"
        case windSpeed = "wind_speed"
        case windGust = "wind_gust"
        case windDirection = "wind_direction"
        case relativeHumidity = "relative_humidity"
        case dewpoint
        case precipitationProbability = "precipitation_probability"
        case source
        case station
    }
}

/// The surface station whose reading anchored temperature, dewpoint and wind at this hour.
public struct ConditionsStation: Sendable, Hashable, Codable {
    /// The station's id in its network, as `nearest_sensors[].station_id`.
    public var stationID: String
    /// The station's registry name, else its id.
    public var name: String
    /// Observation time.
    public var observationTime: Date

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(stationID: String, name: String, observationTime: Date) {
        self.stationID = stationID
        self.name = name
        self.observationTime = observationTime
    }

    enum CodingKeys: String, CodingKey {
        case stationID = "station_id"
        case name
        case observationTime = "observation_time"
    }
}

/// One `/current` sensor -- its latest readings, in the request's `units` (the Cap'n Proto `SensorObservation` carries the same values).
public struct SensorObservation: Sendable, Hashable, Codable {
    /// The station's id in its network.
    public var stationID: String
    /// The station's registry name, else its id.
    public var name: String
    /// Source.
    public var source: String
    /// Observation time.
    public var observationTime: Date
    /// °C, °F (imperial) or K (kelvin).
    public var temperature: Double?
    /// As `temperature`.
    public var dewpoint: Double?
    /// Percent.
    public var relativeHumidity: Double?
    /// M/s or mph (imperial).
    public var windSpeed: Double?
    /// As `wind_speed`.
    public var windGust: Double?
    /// Degrees clockwise from north.
    public var windDirection: Double?
    /// Station pressure: hPa, or inHg (imperial).
    public var pressure: Double?
    /// The last reporting period's precipitation: mm, or in (imperial).
    public var precipitation: Double?
    /// Radar precipitation rate: mm/h, or in/h (imperial).
    public var precipitationRate: Double?
    /// Radar reflectivity, dBZ.
    public var reflectivity: Double?
    /// As `temperature`.
    public var pavementTemp: Double?
    /// As `temperature`.
    public var subsurfaceTemp: Double?
    /// M, or statute miles (imperial).
    public var visibility: Double?
    /// Percent.
    public var cloudCover: Double?
    /// M, or ft (imperial).
    public var ceilingHeight: Double?
    /// Cm, or in (imperial).
    public var snowDepth: Double?
    /// Snow water equivalent: mm, or in (imperial).
    public var snowWaterEquivalent: Double?
    /// SWE as a percent of the station's median for the date.
    public var snowWaterEquivalentPercentOfMedian: Double?
    /// Mm, or in (imperial).
    public var snowfall: Double?
    /// W/m².
    public var solarRadiation: Double?
    /// Road-weather pavement state as the network reports it.
    public var pavementCondition: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        stationID: String, name: String, source: String, observationTime: Date,
        temperature: Double? = nil, dewpoint: Double? = nil, relativeHumidity: Double? = nil,
        windSpeed: Double? = nil, windGust: Double? = nil, windDirection: Double? = nil,
        pressure: Double? = nil, precipitation: Double? = nil, precipitationRate: Double? = nil,
        reflectivity: Double? = nil, pavementTemp: Double? = nil, subsurfaceTemp: Double? = nil,
        visibility: Double? = nil, cloudCover: Double? = nil, ceilingHeight: Double? = nil,
        snowDepth: Double? = nil, snowWaterEquivalent: Double? = nil,
        snowWaterEquivalentPercentOfMedian: Double? = nil, snowfall: Double? = nil,
        solarRadiation: Double? = nil, pavementCondition: String? = nil
    ) {
        self.stationID = stationID
        self.name = name
        self.source = source
        self.observationTime = observationTime
        self.temperature = temperature
        self.dewpoint = dewpoint
        self.relativeHumidity = relativeHumidity
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.windDirection = windDirection
        self.pressure = pressure
        self.precipitation = precipitation
        self.precipitationRate = precipitationRate
        self.reflectivity = reflectivity
        self.pavementTemp = pavementTemp
        self.subsurfaceTemp = subsurfaceTemp
        self.visibility = visibility
        self.cloudCover = cloudCover
        self.ceilingHeight = ceilingHeight
        self.snowDepth = snowDepth
        self.snowWaterEquivalent = snowWaterEquivalent
        self.snowWaterEquivalentPercentOfMedian = snowWaterEquivalentPercentOfMedian
        self.snowfall = snowfall
        self.solarRadiation = solarRadiation
        self.pavementCondition = pavementCondition
    }

    enum CodingKeys: String, CodingKey {
        case stationID = "station_id"
        case name
        case source
        case observationTime = "observation_time"
        case temperature
        case dewpoint
        case relativeHumidity = "relative_humidity"
        case windSpeed = "wind_speed"
        case windGust = "wind_gust"
        case windDirection = "wind_direction"
        case pressure
        case precipitation
        case precipitationRate = "precipitation_rate"
        case reflectivity
        case pavementTemp = "pavement_temp"
        case subsurfaceTemp = "subsurface_temp"
        case visibility
        case cloudCover = "cloud_cover"
        case ceilingHeight = "ceiling_height"
        case snowDepth = "snow_depth"
        case snowWaterEquivalent = "swe"
        case snowWaterEquivalentPercentOfMedian = "swe_percent_of_median"
        case snowfall
        case solarRadiation = "solar_radiation"
        case pavementCondition = "pavement_condition"
    }
}

/// The active weather alerts for a location or point.
public struct AlertsResponse: Sendable, Hashable, Codable {
    /// The one location reference.
    public var location: LocationReference
    /// Alert count.
    public var alertCount: Int
    /// Snapshot timestamp (see /current alerts_as_of).
    public var asOf: Date
    /// Alerts.
    public var alerts: [ActiveAlert]
    /// Attribution.
    public var attribution: ResponseAttribution

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        location: LocationReference, alertCount: Int, asOf: Date, alerts: [ActiveAlert],
        attribution: ResponseAttribution
    ) {
        self.location = location
        self.alertCount = alertCount
        self.asOf = asOf
        self.alerts = alerts
        self.attribution = attribution
    }

    enum CodingKeys: String, CodingKey {
        case location
        case alertCount = "alert_count"
        case asOf = "as_of"
        case alerts
        case attribution
    }
}

/// Compact active NWS alert (headline carries the user text).
public struct ActiveAlert: Sendable, Hashable, Codable {
    /// NWS alert identifier (urn:oid:…).
    public var id: String
    /// Event.
    public var event: String
    /// The NWS severity, snake_case: `extreme`, `severe`, `moderate`, `minor` or `unknown`
    /// (treat any other value as `unknown`).
    public var severity: String
    /// The NWS urgency, snake_case: `immediate`, `expected`, `future`, `past` or `unknown`.
    public var urgency: String
    /// The NWS certainty, snake_case: `observed`, `likely`, `possible`, `unlikely` or `unknown`.
    public var certainty: String
    /// Headline.
    public var headline: String
    /// Omitted when NWS supplies none.
    public var onset: Date?
    /// Expires.
    public var expires: Date
    /// Omitted when NWS supplies none.
    public var ends: Date?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, event: String, severity: String, urgency: String, certainty: String,
        headline: String,
        onset: Date? = nil, expires: Date, ends: Date? = nil
    ) {
        self.id = id
        self.event = event
        self.severity = severity
        self.urgency = urgency
        self.certainty = certainty
        self.headline = headline
        self.onset = onset
        self.expires = expires
        self.ends = ends
    }

    enum CodingKeys: String, CodingKey {
        case id
        case event
        case severity
        case urgency
        case certainty
        case headline
        case onset
        case expires
        case ends
    }
}
