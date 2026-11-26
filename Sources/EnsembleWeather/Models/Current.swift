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
    /// (JSON `current`) "Right now" flattened: the `nowcast_hours` hour nearest the request time, read field by field (see the schema).
    public var now: CurrentConditions?
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
    /// The place summary, written by the server from served values only, so every client shows the same words.
    public var summary: PlaceSummary?
    /// The mountain pass forecast at the pass's own point and elevation.
    public var pass: PassForecast?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        location: LocationReference, alerts: [ActiveAlert], alertsAsOf: Date, sensorCount: Int,
        sensors: [SensorObservation], now: CurrentConditions? = nil, asOf: Date,
        modelRunInitializedAt: Date? = nil, nowcastHours: [TimeSeriesPoint]? = nil,
        units: UnitSystem, attribution: ResponseAttribution,
        nowcastUnavailable: [NowcastSource]? = nil,
        summary: PlaceSummary? = nil,
        pass: PassForecast? = nil
    ) {
        self.location = location
        self.alerts = alerts
        self.alertsAsOf = alertsAsOf
        self.sensorCount = sensorCount
        self.sensors = sensors
        self.now = now
        self.asOf = asOf
        self.modelRunInitializedAt = modelRunInitializedAt
        self.nowcastHours = nowcastHours
        self.units = units
        self.attribution = attribution
        self.nowcastUnavailable = nowcastUnavailable
        self.summary = summary
        self.pass = pass
    }

    enum CodingKeys: String, CodingKey {
        case location
        case alerts
        case alertsAsOf = "alerts_as_of"
        case sensorCount = "sensor_count"
        case sensors
        case now = "current"
        case asOf = "as_of"
        case modelRunInitializedAt = "model_run_initialized_at"
        case nowcastHours = "nowcast_hours"
        case units
        case attribution
        case nowcastUnavailable = "nowcast_unavailable"
        case summary
        case pass
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
    /// (JSON `condition`) The hour's stable condition code, as `TimeSeriesPoint.condition` (`partly_cloudy`).
    public var code: String
    /// (JSON `condition_text`) The display text for `condition`, as `TimeSeriesPoint.condition_text`.
    public var text: String
    /// (JSON `condition_icon`) The hour's icon hint, as `TimeSeriesPoint.condition_icon`.
    public var icon: ConditionIcon
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
    /// The hour in progress's `measured`, the hour `condition` and `precipitation_probability` are read from: the radar's published accumulation for that clock hour so far is served above 0 (above 0.00 mm and 0.000 in), so `condition` states the ...
    public var isMeasured: Bool?
    /// Cloud cover, percent (0-100), the mean of the hour in progress's `ensemble.cloud_cover`: the hour `condition` is read from, so the number and the label describe one hour.
    public var cloudCover: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        time: Date, temperature: Double, feelsLike: Double? = nil, code: String,
        text: String, icon: ConditionIcon, windSpeed: Double,
        windGust: Double? = nil,
        windDirection: Double, relativeHumidity: Double? = nil, dewpoint: Double? = nil,
        precipitationProbability: Double? = nil, source: ConditionsSource,
        station: ConditionsStation? = nil,
        isMeasured: Bool? = nil,
        cloudCover: Double? = nil
    ) {
        self.time = time
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.code = code
        self.text = text
        self.icon = icon
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.windDirection = windDirection
        self.relativeHumidity = relativeHumidity
        self.dewpoint = dewpoint
        self.precipitationProbability = precipitationProbability
        self.source = source
        self.station = station
        self.isMeasured = isMeasured
        self.cloudCover = cloudCover
    }

    enum CodingKeys: String, CodingKey {
        case time
        case temperature
        case feelsLike = "feels_like"
        case code = "condition"
        case text = "condition_text"
        case icon = "condition_icon"
        case windSpeed = "wind_speed"
        case windGust = "wind_gust"
        case windDirection = "wind_direction"
        case relativeHumidity = "relative_humidity"
        case dewpoint
        case precipitationProbability = "precipitation_probability"
        case source
        case station
        case isMeasured = "measured"
        case cloudCover = "cloud_cover"
    }
}

/// The surface station whose reading anchored temperature, dewpoint and wind at this hour.
public struct ConditionsStation: Sendable, Hashable, Codable {
    /// (JSON `station_id`) The station's id in its network, as `nearest_sensors[].station_id`.
    public var id: String
    /// The station's registry name, else its id.
    public var name: String
    /// Observation time.
    public var observationTime: Date
    /// `True` when the station's reading was calm (0 wind speed; a METAR's `00000KT`).
    public var isCalm: Bool?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(id: String, name: String, observationTime: Date, isCalm: Bool? = nil) {
        self.id = id
        self.name = name
        self.observationTime = observationTime
        self.isCalm = isCalm
    }

    enum CodingKeys: String, CodingKey {
        case id = "station_id"
        case name
        case observationTime = "observation_time"
        case isCalm = "calm"
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
    /// (JSON `observation_time`) Observation time.
    public var observedAt: Date
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
    /// Straight-line surface distance from the location to the sensor, in km (at most 25), as `nearest_sensors[].distance_km`.
    public var distanceKilometers: Double?
    /// The sensor's registry elevation minus the location's, in the caller's length units (m metric, ft imperial), as `nearest_sensors[].elevation_diff`.
    public var elevationDifference: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        stationID: String, name: String, source: String, observedAt: Date,
        temperature: Double? = nil, dewpoint: Double? = nil, relativeHumidity: Double? = nil,
        windSpeed: Double? = nil, windGust: Double? = nil, windDirection: Double? = nil,
        pressure: Double? = nil, precipitation: Double? = nil, precipitationRate: Double? = nil,
        reflectivity: Double? = nil, pavementTemp: Double? = nil, subsurfaceTemp: Double? = nil,
        visibility: Double? = nil, cloudCover: Double? = nil, ceilingHeight: Double? = nil,
        snowDepth: Double? = nil, snowWaterEquivalent: Double? = nil,
        snowWaterEquivalentPercentOfMedian: Double? = nil, snowfall: Double? = nil,
        solarRadiation: Double? = nil, pavementCondition: String? = nil,
        distanceKilometers: Double? = nil,
        elevationDifference: Double? = nil
    ) {
        self.stationID = stationID
        self.name = name
        self.source = source
        self.observedAt = observedAt
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
        self.distanceKilometers = distanceKilometers
        self.elevationDifference = elevationDifference
    }

    enum CodingKeys: String, CodingKey {
        case stationID = "station_id"
        case name
        case source
        case observedAt = "observation_time"
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
        case distanceKilometers = "distance_km"
        case elevationDifference = "elevation_diff"
    }
}

/// The active weather alerts for a location or point.
public struct AlertsResponse: Sendable, Hashable, Codable {
    /// The one location reference.
    public var location: LocationReference
    /// (JSON `alert_count`) Alert count.
    public var count: Int
    /// Snapshot timestamp (see /current alerts_as_of).
    public var asOf: Date
    /// (JSON `alerts`) Alerts.
    public var items: [ActiveAlert]
    /// Attribution.
    public var attribution: ResponseAttribution

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        location: LocationReference, count: Int, asOf: Date, items: [ActiveAlert],
        attribution: ResponseAttribution
    ) {
        self.location = location
        self.count = count
        self.asOf = asOf
        self.items = items
        self.attribution = attribution
    }

    enum CodingKeys: String, CodingKey {
        case location
        case count = "alert_count"
        case asOf = "as_of"
        case items = "alerts"
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
    /// When NWS issued this message.
    public var sent: Date?
    /// The CAP message type, snake_case.
    public var messageType: String?
    /// The ids of the messages this one replaces.
    public var references: [String]?
    /// SenderName.
    public var senderName: String?
    /// The places this message covers, as NWS words them.
    public var areaDesc: String?
    /// The full NWS text, unedited.
    public var description: String?
    /// What NWS says to do, unedited.
    public var instruction: String?
    /// The NWS forecast page for this location.
    public var sourceURL: String?
    /// The stable identity of this event.
    public var eventKey: String?
    /// The VTEC action of this message, lower case.
    public var vtecAction: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, event: String, severity: String, urgency: String, certainty: String,
        headline: String,
        onset: Date? = nil, expires: Date, ends: Date? = nil,
        sent: Date? = nil,
        messageType: String? = nil,
        references: [String]? = nil,
        senderName: String? = nil,
        areaDesc: String? = nil,
        description: String? = nil,
        instruction: String? = nil,
        sourceURL: String? = nil,
        eventKey: String? = nil,
        vtecAction: String? = nil
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
        self.sent = sent
        self.messageType = messageType
        self.references = references
        self.senderName = senderName
        self.areaDesc = areaDesc
        self.description = description
        self.instruction = instruction
        self.sourceURL = sourceURL
        self.eventKey = eventKey
        self.vtecAction = vtecAction
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
        case sent
        case messageType = "message_type"
        case references
        case senderName = "sender_name"
        case areaDesc = "area_desc"
        case description
        case instruction
        case sourceURL = "source_url"
        case eventKey = "event_key"
        case vtecAction = "vtec_action"
    }
}
