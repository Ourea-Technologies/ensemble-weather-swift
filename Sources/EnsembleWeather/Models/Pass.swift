// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// A short plain-language summary of what is coming at a place, written by the server from templates filled with served values (never free text from a model).
public struct PlaceSummary: Sendable, Hashable, Codable {
    /// One sentence: the most important thing at the place, by priority (an NWS alert, precipitation starting or stopping soon, snow coming, wind or a large temperature change, then the day's headline).
    public var short: String
    /// One to three sentences for the location page, each from a different kind of event.
    public var long: [String]
    /// The event behind each sentence of `long`, in the same order (`events[i]` wrote `long[i]`), so a client can style a sentence (an alert chip, a snow icon) without parsing text.
    public var events: [SummaryEvent]
    /// The served elevation the sentences describe: its display name where the catalog has one, else its name.
    public var elevationName: String?
    /// The height the sentences describe, in the response's length units (m, ft).
    public var elevation: Double
    /// The init of the forecast run the sentences were written from.
    public var run: Date
    /// When the sentences were written (the request's now); the "updated" stamp.
    public var generatedAt: Date

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        short: String, long: [String], events: [SummaryEvent], elevationName: String? = nil,
        elevation: Double, run: Date, generatedAt: Date
    ) {
        self.short = short
        self.long = long
        self.events = events
        self.elevationName = elevationName
        self.elevation = elevation
        self.run = run
        self.generatedAt = generatedAt
    }

    enum CodingKeys: String, CodingKey {
        case short
        case long
        case events
        case elevationName = "elevation_name"
        case elevation
        case run
        case generatedAt = "generated_at"
    }
}

/// The event behind one sentence of a place summary.
public struct SummaryEvent: Sendable, Hashable, Codable {
    /// What the sentence is about.
    public var kind: String
    /// The phrasing used, `<template>.<variant>` (`snow_coming.v1.3`), stable across releases so sentences can be counted, reviewed and later translated.
    public var template: String
    /// The hour the event begins (precipitation starting or stopping, an alert's onset, a pass event).
    public var at: Date?
    /// When the event ends, where the sentence says so (an alert's end, a snow window's end).
    public var until: Date?
    /// The `alerts[].id` an `alert` event states.
    public var alertID: String?
    /// The served numbers the sentence states, unrounded, in the response's units.
    public var values: SummaryValues?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        kind: String, template: String, at: Date? = nil, until: Date? = nil, alertID: String? = nil,
        values: SummaryValues? = nil
    ) {
        self.kind = kind
        self.template = template
        self.at = at
        self.until = until
        self.alertID = alertID
        self.values = values
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case template
        case at
        case until
        case alertID = "alert_id"
        case values
    }
}

/// Each number a summary sentence states, as served.
public struct SummaryValues: Sendable, Hashable, Codable {
    /// The window's headline snowfall total (mm, in): for `snow_coming` the forecast's `snow_outlook.<snowfall_window>`; for `pass_snow_starts` the window's `pass.snow_windows[].total`.
    public var snowfall: Double?
    /// The window's served p10 (`snow_outlook.quantiles.<window>.p10`, or the pass window's `p10`).
    public var snowfallP10: Double?
    /// The window's served p90.
    public var snowfallP90: Double?
    /// Which window `snowfall` totals.
    public var snowfallWindow: String?
    /// A day's served high (`daily[].high.mean`) a `day_headline` or `temperature_change` states.
    public var temperature: Double?
    /// The served hourly gust mean (`ensemble.wind_gust.mean`) a `wind` sentence states.
    public var windGust: Double?
    /// The served chance (0-1) behind the sentence's likelihood word.
    public var precipitationProbability: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        snowfall: Double? = nil, snowfallP10: Double? = nil, snowfallP90: Double? = nil,
        snowfallWindow: String? = nil, temperature: Double? = nil, windGust: Double? = nil,
        precipitationProbability: Double? = nil
    ) {
        self.snowfall = snowfall
        self.snowfallP10 = snowfallP10
        self.snowfallP90 = snowfallP90
        self.snowfallWindow = snowfallWindow
        self.temperature = temperature
        self.windGust = windGust
        self.precipitationProbability = precipitationProbability
    }

    enum CodingKeys: String, CodingKey {
        case snowfall
        case snowfallP10 = "snowfall_p10"
        case snowfallP90 = "snowfall_p90"
        case snowfallWindow = "snowfall_window"
        case temperature
        case windGust = "wind_gust"
        case precipitationProbability = "precipitation_probability"
    }
}

/// "Is the pass getting weather?" at the pass's own point and elevation: forecast quantities only, in the response's units.
public struct PassForecast: Sendable, Hashable, Codable {
    /// The pass's elevation, in the response's length units (m, ft).
    public var elevation: Double
    /// The pass's elevation in metres, whatever `units` is.
    public var elevationMeters: Double
    /// The first hour of `hours` (the hour containing now); the 24 h and 48 h windows open here.
    public var from: Date
    /// Snow 24h.
    public var snow24Hours: PassSnow24h
    /// Chances.
    public var chances: PassChances
    /// Each spell of snow at the pass in the next 48 h, in time order; empty when none.
    public var snowWindows: [PassSnowWindow]
    /// The next 48 hours at the pass, from `from`, one per hour.
    public var hours: [PassHour]
    /// Windows.
    public var windows: PassTravelWindows
    /// Official status.
    public var officialStatus: PassOfficialStatus?
    /// The state DOT road-weather stations nearest the pass, nearest first: at most 3, within 25 km, each with its newest reading in the last 3 h.
    public var roadSensors: [PassRoadSensor]?
    /// The DOT's own cameras at the pass, in the order the pass's curation lists them.
    public var cameras: [PassCamera]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        elevation: Double, elevationMeters: Double, from: Date, snow24Hours: PassSnow24h,
        chances:
            PassChances, snowWindows: [PassSnowWindow], hours: [PassHour],
        windows: PassTravelWindows,
        officialStatus: PassOfficialStatus? = nil, roadSensors: [PassRoadSensor]? = nil,
        cameras:
            [PassCamera]? = nil
    ) {
        self.elevation = elevation
        self.elevationMeters = elevationMeters
        self.from = from
        self.snow24Hours = snow24Hours
        self.chances = chances
        self.snowWindows = snowWindows
        self.hours = hours
        self.windows = windows
        self.officialStatus = officialStatus
        self.roadSensors = roadSensors
        self.cameras = cameras
    }

    enum CodingKeys: String, CodingKey {
        case elevation
        case elevationMeters = "elevation_m"
        case from
        case snow24Hours = "snow_24h"
        case chances
        case snowWindows = "snow_windows"
        case hours
        case windows
        case officialStatus = "official_status"
        case roadSensors = "road_sensors"
        case cameras
    }
}

/// The next 24 h of snow at the pass: exactly the default forecast's own `snow_outlook.next_24h` and `snow_outlook.quantiles.next_24h` (unpinned, the nowcast on, the same cycle), so the pass page, the passes board and search state one number.
public struct PassSnow24h: Sendable, Hashable, Codable {
    /// `snow_outlook.next_24h` (mm, in); null where the forecast does not reach 24 h.
    public var total: Double?
    /// `snow_outlook.quantiles.next_24h.p10`; null without members covering the window.
    public var p10: Double?
    /// `snow_outlook.quantiles.next_24h.p90`.
    public var p90: Double?
    /// The start of the first snow spell (`snow_windows[0].start`) when it begins inside the 24 h; null otherwise.
    public var startsAt: Date?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        total: Double? = nil, p10: Double? = nil, p90: Double? = nil, startsAt: Date? = nil
    ) {
        self.total = total
        self.p10 = p10
        self.p90 = p90
        self.startsAt = startsAt
    }

    enum CodingKeys: String, CodingKey {
        case total
        case p10
        case p90
        case startsAt = "starts_at"
    }
}

/// Chances at the pass over the next `window_hours` hours, each the share of the forecast's members meeting the event (the `?prob=` machinery), except the gust chance (see its `method`).
public struct PassChances: Sendable, Hashable, Codable {
    /// The window's length, 24.
    public var windowHours: Int
    /// From.
    public var from: Date
    /// To.
    public var to: Date
    /// Snowfall total over the window of 1 in (25.4 mm) or more: `prob=snowfall:ge:<1 in>:24h`.
    public var pSnowGe1in: PassChance
    /// Snowfall total over the window of 6 in (152.4 mm) or more.
    public var pSnowGe6in: PassChance
    /// Some hour of the window in which the member is at or below freezing (`threshold`: 0 C, 32 F) with precipitation of at least `precipitation_threshold` (0.254 mm, 0.01 in) in the member's value ending at that hour: a wet road at or below ...
    public var pWetBelowFreezing: PassChance
    /// A gust over 40 mph (17.9 m/s; threshold fixed, does not change with units) in the window.
    public var pGustGt40mph: PassChance

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        windowHours: Int, from: Date, to: Date, pSnowGe1in: PassChance, pSnowGe6in: PassChance,
        pWetBelowFreezing: PassChance, pGustGt40mph: PassChance
    ) {
        self.windowHours = windowHours
        self.from = from
        self.to = to
        self.pSnowGe1in = pSnowGe1in
        self.pSnowGe6in = pSnowGe6in
        self.pWetBelowFreezing = pWetBelowFreezing
        self.pGustGt40mph = pGustGt40mph
    }

    enum CodingKeys: String, CodingKey {
        case windowHours = "window_hours"
        case from
        case to
        case pSnowGe1in = "p_snow_ge_1in"
        case pSnowGe6in = "p_snow_ge_6in"
        case pWetBelowFreezing = "p_wet_below_freezing"
        case pGustGt40mph = "p_gust_gt_40mph"
    }
}

/// A mountain pass chance: a probability with the threshold and the members it was counted over.
public struct PassChance: Sendable, Hashable, Codable {
    /// 0-1 (0.001); null when it cannot be answered (`null_reason`).
    public var probability: Double?
    /// The event's threshold, in the response's units.
    public var threshold: Double
    /// For `p_wet_below_freezing`, the precipitation that makes an hour wet, in the response's units.
    public var precipitationThreshold: Double?
    /// The members that voted (0 for `hourly_gust_distribution`).
    public var members: Int
    /// Method.
    public var method: String
    /// Null reason.
    public var nullReason: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        probability: Double? = nil, threshold: Double, precipitationThreshold: Double? = nil,
        members: Int, method: String, nullReason: String? = nil
    ) {
        self.probability = probability
        self.threshold = threshold
        self.precipitationThreshold = precipitationThreshold
        self.members = members
        self.method = method
        self.nullReason = nullReason
    }

    enum CodingKeys: String, CodingKey {
        case probability
        case threshold
        case precipitationThreshold = "precipitation_threshold"
        case members
        case method
        case nullReason = "null_reason"
    }
}

/// A window of snow at a mountain pass, with its total and the chance of at least 1 in.
public struct PassSnowWindow: Sendable, Hashable, Codable {
    /// When the first snowing hour begins (its `valid_time` minus 1 h).
    public var start: Date
    /// When the last snowing hour ends (its `valid_time`).
    public var end: Date
    /// The sum of the hourly snowfall means over the spell (mm, in), as `snow_outlook` sums its windows.
    public var total: Double
    /// The p10 of the members' own totals over the spell (`?totals=` machinery); omitted without enough members.
    public var p10: Double?
    /// The p90 of the members' own totals over the spell.
    public var p90: Double?
    /// The share of members whose own total over the spell is 1 in (25.4 mm) or more; threshold fixed, does not change with units.
    public var pGe1in: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        start: Date, end: Date, total: Double, p10: Double? = nil, p90: Double? = nil,
        pGe1in:
            Double? = nil
    ) {
        self.start = start
        self.end = end
        self.total = total
        self.p10 = p10
        self.p90 = p90
        self.pGe1in = pGe1in
    }

    enum CodingKeys: String, CodingKey {
        case start
        case end
        case total
        case p10
        case p90
        case pGe1in = "p_ge_1in"
    }
}

/// One hour of a mountain pass forecast.
public struct PassHour: Sendable, Hashable, Codable {
    /// The hour's `valid_time`; amounts are over the hour ending then.
    public var time: Date
    /// `ensemble.temperature.mean`.
    public var temperature: Double
    /// `ensemble.precipitation.mean` (mm, in).
    public var precipitation: Double
    /// `ensemble.precipitation.probability`, 0-1.
    public var precipitationProbability: Double?
    /// The hour's served `precipitation_type.type`; omitted on a dry hour.
    public var precipitationType: String?
    /// `ensemble.snowfall.mean` (mm, in); 0 without snow.
    public var snowfall: Double
    /// `ensemble.snow_level.mean` (m, ft); omitted where not served.
    public var snowLevel: Double?
    /// (JSON `snow_level_above_pass`) `snow_level` minus the pass's elevation (m, ft): above 0 the snow level is above the pass (rain at the pass when wet), below 0 it is under it.
    public var snowLevelMargin: Double?
    /// The hour is at or below freezing (temperature mean at or below 0 C, 32 F) and wet: precipitation of at least 0.254 mm (0.01 in) in this hour or one of the two before it.
    public var freezingOnWetRoad: Bool
    /// `ensemble.wind_speed.mean`.
    public var windSpeed: Double
    /// `ensemble.wind_gust.mean`; omitted where not served.
    public var windGust: Double?
    /// `wind_gust` is over 40 mph (17.9 m/s); threshold fixed, does not change with units.
    public var gustOver40mph: Bool
    /// Gusts of 25 mph (11.2 m/s) or more at or below freezing with loose snow to move: snow falling this hour, 1 in (25.4 mm) or more fallen in the 24 served hours before it, or snow on the ground at the pass (`snow_on_ground`).
    public var blowingSnow: Bool

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        time: Date, temperature: Double, precipitation: Double,
        precipitationProbability: Double? =
            nil, precipitationType: String? = nil, snowfall: Double, snowLevel: Double? = nil,
        snowLevelMargin: Double? = nil, freezingOnWetRoad: Bool, windSpeed: Double,
        windGust:
            Double? = nil, gustOver40mph: Bool, blowingSnow: Bool
    ) {
        self.time = time
        self.temperature = temperature
        self.precipitation = precipitation
        self.precipitationProbability = precipitationProbability
        self.precipitationType = precipitationType
        self.snowfall = snowfall
        self.snowLevel = snowLevel
        self.snowLevelMargin = snowLevelMargin
        self.freezingOnWetRoad = freezingOnWetRoad
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.gustOver40mph = gustOver40mph
        self.blowingSnow = blowingSnow
    }

    enum CodingKeys: String, CodingKey {
        case time
        case temperature
        case precipitation
        case precipitationProbability = "precipitation_probability"
        case precipitationType = "precipitation_type"
        case snowfall
        case snowLevel = "snow_level"
        case snowLevelMargin = "snow_level_above_pass"
        case freezingOnWetRoad = "freezing_on_wet_road"
        case windSpeed = "wind_speed"
        case windGust = "wind_gust"
        case gustOver40mph = "gust_over_40mph"
        case blowingSnow = "blowing_snow"
    }
}

/// The quietest and the busiest stretch of weather at the pass in the next `horizon_hours`, by one fixed rule on the hours above: an hour has weather when it is snowing (`snowfall` at least 0.04 in, 1 mm), `freezing_on_wet_road`, or `gust_over_40mph`.
public struct PassTravelWindows: Sendable, Hashable, Codable {
    /// The horizon's length in hours, 24.
    public var horizonHours: Int
    /// Null when every hour has weather.
    public var leastWeather: PassTravelWindow?
    /// Null when no hour has weather.
    public var mostWeather: PassTravelWindow?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        horizonHours: Int, leastWeather: PassTravelWindow? = nil,
        mostWeather: PassTravelWindow? =
            nil
    ) {
        self.horizonHours = horizonHours
        self.leastWeather = leastWeather
        self.mostWeather = mostWeather
    }

    enum CodingKeys: String, CodingKey {
        case horizonHours = "horizon_hours"
        case leastWeather = "least_weather"
        case mostWeather = "most_weather"
    }
}

/// A travel window at a mountain pass: its span, peak gust and hours of freezing on a wet road.
public struct PassTravelWindow: Sendable, Hashable, Codable {
    /// When the run's first hour begins.
    public var start: Date
    /// When its last hour ends.
    public var end: Date
    /// The sum of the hourly snowfall means over the run (mm, in).
    public var snowfall: Double
    /// Freezing on wet road hours.
    public var freezingOnWetRoadHours: Int
    /// The highest hourly gust mean in the run; omitted where no gust is served.
    public var maxWindGust: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        start: Date, end: Date, snowfall: Double, freezingOnWetRoadHours: Int,
        maxWindGust: Double? = nil
    ) {
        self.start = start
        self.end = end
        self.snowfall = snowfall
        self.freezingOnWetRoadHours = freezingOnWetRoadHours
        self.maxWindGust = maxWindGust
    }

    enum CodingKeys: String, CodingKey {
        case start
        case end
        case snowfall
        case freezingOnWetRoadHours = "freezing_on_wet_road_hours"
        case maxWindGust = "max_wind_gust"
    }
}

/// The DOT's own status for the road over the pass -- chain controls and closures as the DOT publishes them, its wording verbatim.
public struct PassOfficialStatus: Sendable, Hashable, Codable {
    /// The DOT feed.
    public var source: String
    /// Who to credit, as the client shows it.
    public var attribution: String
    /// The DOT's own page for this road, to link out to.
    public var url: String
    /// How fresh the DOT's feed behind these segments was at Ourea's last read: the time the DOT wrote the file Ourea last read (Caltrans rewrites it every minute; Ourea reads it every 5), and the older of two when the segments span two DOT ...
    public var checkedAt: Date
    /// `checked_at` is more than 30 minutes before `as_of`.
    public var isStale: Bool
    /// Level.
    public var level: PassStatusLevel
    /// The DOT's chain-control and closure points on the road over the pass, each direction, in the pass's curated order.
    public var segments: [PassStatusSegment]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        source: String, attribution: String, url: String, checkedAt: Date, isStale: Bool,
        level:
            PassStatusLevel, segments: [PassStatusSegment]
    ) {
        self.source = source
        self.attribution = attribution
        self.url = url
        self.checkedAt = checkedAt
        self.isStale = isStale
        self.level = level
        self.segments = segments
    }

    enum CodingKeys: String, CodingKey {
        case source
        case attribution
        case url
        case checkedAt = "checked_at"
        case isStale = "stale"
        case level
        case segments
    }
}

/// One DOT chain-control or closure point, as the DOT publishes it.
public struct PassStatusSegment: Sendable, Hashable, Codable {
    /// The DOT's own id for the point.
    public var id: String
    /// Route.
    public var route: String
    /// The direction the point controls, as the DOT names it.
    public var direction: String
    /// The DOT's name for the point (its trailing field padding removed).
    public var location: String
    /// (JSON `status`) The DOT's status code, verbatim.
    public var state: String
    /// Level.
    public var level: PassStatusLevel
    /// (JSON `status_text`) The DOT's own description of the status, verbatim.
    public var text: String
    /// When the DOT set this status.
    public var updatedAt: Date
    /// Lat.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// The DOT's own report of the road surface there, verbatim, where it gives one beside the restriction (WSDOT, ODOT).
    public var roadCondition: String?
    /// The DOT's own report of the weather there, verbatim (WSDOT, ODOT).
    public var weatherCondition: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, route: String, direction: String, location: String, state: String,
        level:
            PassStatusLevel, text: String, updatedAt: Date, latitude: Double, longitude: Double,
        roadCondition: String? = nil, weatherCondition: String? = nil
    ) {
        self.id = id
        self.route = route
        self.direction = direction
        self.location = location
        self.state = state
        self.level = level
        self.text = text
        self.updatedAt = updatedAt
        self.latitude = latitude
        self.longitude = longitude
        self.roadCondition = roadCondition
        self.weatherCondition = weatherCondition
    }

    enum CodingKeys: String, CodingKey {
        case id
        case route
        case direction
        case location
        case state = "status"
        case level
        case text = "status_text"
        case updatedAt = "updated_at"
        case latitude = "lat"
        case longitude = "lon"
        case roadCondition = "road_condition"
        case weatherCondition = "weather_condition"
    }
}

/// One state DOT road-weather station's newest reading, in the response's units.
public struct PassRoadSensor: Sendable, Hashable, Codable {
    /// The station's id in its network.
    public var stationID: String
    /// The station's registry name, else its id.
    public var name: String
    /// The feed: `rwis` (Caltrans CWWP2 RWIS) or `wsdot`.
    public var source: String
    /// Who measured it, as the client credits it.
    public var attribution: String
    /// Straight-line distance from the pass, km.
    public var distanceKilometers: Double
    /// The station's registry elevation in the response's length units (m, ft).
    public var elevation: Double?
    /// The station's registry elevation in metres.
    public var elevationMeters: Double?
    /// Observed at.
    public var observedAt: Date
    /// `observed_at` is more than 60 minutes before `as_of`.
    public var isStale: Bool
    /// The pavement state the sensor reports (NTCIP 1204 essSurfaceStatus as `/current` sensors serve it: dry, trace_moisture, wet, chemically_wet, ice_warning, ice_watch, snow_warning, snow_watch, absorption, dew, frost, absorption_at_dewpoint).
    public var pavementCondition: String?
    /// Pavement surface temperature: °C, °F (imperial) or K (kelvin).
    public var pavementTemp: Double?
    /// As `pavement_temp`.
    public var subsurfaceTemp: Double?
    /// Air temperature, as `pavement_temp`.
    public var temperature: Double?
    /// m/s or mph (imperial).
    public var windSpeed: Double?
    /// As `wind_speed`.
    public var windGust: Double?
    /// Degrees clockwise from north.
    public var windDirection: Double?
    /// m, or statute miles (imperial).
    public var visibility: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        stationID: String, name: String, source: String, attribution: String,
        distanceKilometers:
            Double, elevation: Double? = nil, elevationMeters: Double? = nil, observedAt: Date,
        isStale:
            Bool, pavementCondition: String? = nil, pavementTemp: Double? = nil,
        subsurfaceTemp: Double? = nil, temperature: Double? = nil, windSpeed: Double? = nil,
        windGust: Double? = nil,
        windDirection: Double? = nil, visibility: Double? = nil
    ) {
        self.stationID = stationID
        self.name = name
        self.source = source
        self.attribution = attribution
        self.distanceKilometers = distanceKilometers
        self.elevation = elevation
        self.elevationMeters = elevationMeters
        self.observedAt = observedAt
        self.isStale = isStale
        self.pavementCondition = pavementCondition
        self.pavementTemp = pavementTemp
        self.subsurfaceTemp = subsurfaceTemp
        self.temperature = temperature
        self.windSpeed = windSpeed
        self.windGust = windGust
        self.windDirection = windDirection
        self.visibility = visibility
    }

    enum CodingKeys: String, CodingKey {
        case stationID = "station_id"
        case name
        case source
        case attribution
        case distanceKilometers = "distance_km"
        case elevation
        case elevationMeters = "elevation_m"
        case observedAt = "observed_at"
        case isStale = "stale"
        case pavementCondition = "pavement_condition"
        case pavementTemp = "pavement_temp"
        case subsurfaceTemp = "subsurface_temp"
        case temperature
        case windSpeed = "wind_speed"
        case windGust = "wind_gust"
        case windDirection = "wind_direction"
        case visibility
    }
}

/// One DOT camera, a still image the DOT refreshes about once a minute.
public struct PassCamera: Sendable, Hashable, Codable {
    /// ID.
    public var id: String
    /// The DOT's name for the camera.
    public var title: String
    /// The DOT's current still image.
    public var imageURL: String
    /// The DOT's own page for the camera, to link out to.
    public var url: String
    /// The image's time (its Last-Modified) when Ourea last checked it, every 15 minutes; the image at `image_url` may be newer.
    public var capturedAt: Date?
    /// `captured_at` is unknown or more than 60 minutes before `as_of`: the camera may be frozen.
    public var isStale: Bool
    /// Source.
    public var source: String
    /// Attribution.
    public var attribution: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, title: String, imageURL: String, url: String, capturedAt: Date? = nil,
        isStale:
            Bool, source: String, attribution: String
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.url = url
        self.capturedAt = capturedAt
        self.isStale = isStale
        self.source = source
        self.attribution = attribution
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageURL = "image_url"
        case url
        case capturedAt = "captured_at"
        case isStale = "stale"
        case source
        case attribution
    }
}
