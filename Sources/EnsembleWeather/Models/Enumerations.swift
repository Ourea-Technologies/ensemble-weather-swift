// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The kind of place a location is.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum LocationType: Sendable, Hashable {
    /// `airport`.
    case airport
    /// `backcountry`.
    case backcountry
    /// `beach_coast`.
    case beachCoast
    /// `campground`.
    case campground
    /// `city_town`.
    case cityTown
    /// `climbing_area`.
    case climbingArea
    /// `coastal_point`.
    case coastalPoint
    /// `event_venue`.
    case eventVenue
    /// `fire_lookout`.
    case fireLookout
    /// `fishing_river_access`.
    case fishingRiverAccess
    /// `golf_course`.
    case golfCourse
    /// `hot_spring`.
    case hotSpring
    /// `lake`.
    case lake
    /// `mountain_pass`.
    case mountainPass
    /// `national_park`.
    case nationalPark
    /// `observation_station`.
    case observationStation
    /// `other`.
    case other
    /// `park`.
    case park
    /// `recreation_area`.
    case recreationArea
    /// `reservoir_lake`.
    case reservoirLake
    /// `scenic_tourist`.
    case scenicTourist
    /// `ski_area`.
    case skiArea
    /// `state_park`.
    case statePark
    /// `summit`.
    case summit
    /// `trailhead`.
    case trailhead
    /// `volcano`.
    case volcano
    /// `waterfall`.
    case waterfall
    /// `wine_agritourism`.
    case wineAgritourism
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension LocationType: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "airport": self = .airport
        case "backcountry": self = .backcountry
        case "beach_coast": self = .beachCoast
        case "campground": self = .campground
        case "city_town": self = .cityTown
        case "climbing_area": self = .climbingArea
        case "coastal_point": self = .coastalPoint
        case "event_venue": self = .eventVenue
        case "fire_lookout": self = .fireLookout
        case "fishing_river_access": self = .fishingRiverAccess
        case "golf_course": self = .golfCourse
        case "hot_spring": self = .hotSpring
        case "lake": self = .lake
        case "mountain_pass": self = .mountainPass
        case "national_park": self = .nationalPark
        case "observation_station": self = .observationStation
        case "other": self = .other
        case "park": self = .park
        case "recreation_area": self = .recreationArea
        case "reservoir_lake": self = .reservoirLake
        case "scenic_tourist": self = .scenicTourist
        case "ski_area": self = .skiArea
        case "state_park": self = .statePark
        case "summit": self = .summit
        case "trailhead": self = .trailhead
        case "volcano": self = .volcano
        case "waterfall": self = .waterfall
        case "wine_agritourism": self = .wineAgritourism
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .airport: "airport"
        case .backcountry: "backcountry"
        case .beachCoast: "beach_coast"
        case .campground: "campground"
        case .cityTown: "city_town"
        case .climbingArea: "climbing_area"
        case .coastalPoint: "coastal_point"
        case .eventVenue: "event_venue"
        case .fireLookout: "fire_lookout"
        case .fishingRiverAccess: "fishing_river_access"
        case .golfCourse: "golf_course"
        case .hotSpring: "hot_spring"
        case .lake: "lake"
        case .mountainPass: "mountain_pass"
        case .nationalPark: "national_park"
        case .observationStation: "observation_station"
        case .other: "other"
        case .park: "park"
        case .recreationArea: "recreation_area"
        case .reservoirLake: "reservoir_lake"
        case .scenicTourist: "scenic_tourist"
        case .skiArea: "ski_area"
        case .statePark: "state_park"
        case .summit: "summit"
        case .trailhead: "trailhead"
        case .volcano: "volcano"
        case .waterfall: "waterfall"
        case .wineAgritourism: "wine_agritourism"
        case .unknown(let raw): raw
        }
    }
}

/// The unit system of a request and of every value in its response.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum UnitSystem: Sendable, Hashable {
    /// `metric`.
    case metric
    /// `imperial`.
    case imperial
    /// `kelvin`.
    case kelvin
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension UnitSystem: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "metric": self = .metric
        case "imperial": self = .imperial
        case "kelvin": self = .kelvin
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .metric: "metric"
        case .imperial: "imperial"
        case .kelvin: "kelvin"
        case .unknown(let raw): raw
        }
    }
}

/// A forecast variable that a probability or window-total query can ask about.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum ForecastVariable: Sendable, Hashable {
    /// `temperature`.
    case temperature
    /// `wind_speed`.
    case windSpeed
    /// `snow_level`.
    case snowLevel
    /// `precipitation`.
    case precipitation
    /// `snowfall`.
    case snowfall
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension ForecastVariable: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "temperature": self = .temperature
        case "wind_speed": self = .windSpeed
        case "snow_level": self = .snowLevel
        case "precipitation": self = .precipitation
        case "snowfall": self = .snowfall
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .temperature: "temperature"
        case .windSpeed: "wind_speed"
        case .snowLevel: "snow_level"
        case .precipitation: "precipitation"
        case .snowfall: "snowfall"
        case .unknown(let raw): raw
        }
    }
}

/// How a probability term compares the forecast with its threshold.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum ProbabilityComparison: Sendable, Hashable {
    /// `ge`.
    case atLeast
    /// `le`.
    case atMost
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension ProbabilityComparison: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "ge": self = .atLeast
        case "le": self = .atMost
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .atLeast: "ge"
        case .atMost: "le"
        case .unknown(let raw): raw
        }
    }
}

/// How a probability term combines the hours of its window.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum ProbabilityAggregation: Sendable, Hashable {
    /// `total`.
    case total
    /// `any`.
    case any
    /// `all`.
    case all
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension ProbabilityAggregation: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "total": self = .total
        case "any": self = .any
        case "all": self = .all
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .total: "total"
        case .any: "any"
        case .all: "all"
        case .unknown(let raw): raw
        }
    }
}

/// A stable machine code for an hour's or a day's weather.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum WeatherCondition: Sendable, Hashable {
    /// `sunny`.
    case sunny
    /// `mostly_sunny`.
    case mostlySunny
    /// `partly_cloudy`.
    case partlyCloudy
    /// `mostly_cloudy`.
    case mostlyCloudy
    /// `cloudy`.
    case cloudy
    /// `clear`.
    case clear
    /// `mostly_clear`.
    case mostlyClear
    /// `slight_chance_showers`.
    case slightChanceShowers
    /// `chance_showers`.
    case chanceShowers
    /// `chance_rain`.
    case chanceRain
    /// `showers_likely`.
    case showersLikely
    /// `rain_likely`.
    case rainLikely
    /// `showers`.
    case showers
    /// `rain`.
    case rain
    /// `light_rain`.
    case lightRain
    /// `heavy_rain`.
    case heavyRain
    /// `slight_chance_rain_snow_mix`.
    case slightChanceRainSnowMix
    /// `chance_rain_snow_mix`.
    case chanceRainSnowMix
    /// `rain_snow_mix_likely`.
    case rainSnowMixLikely
    /// `rain_snow_mix`.
    case rainSnowMix
    /// `slight_chance_snow`.
    case slightChanceSnow
    /// `chance_snow`.
    case chanceSnow
    /// `snow_likely`.
    case snowLikely
    /// `snow`.
    case snow
    /// `slight_chance_freezing_rain`.
    case slightChanceFreezingRain
    /// `chance_freezing_rain`.
    case chanceFreezingRain
    /// `freezing_rain_likely`.
    case freezingRainLikely
    /// `freezing_rain`.
    case freezingRain
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension WeatherCondition: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "sunny": self = .sunny
        case "mostly_sunny": self = .mostlySunny
        case "partly_cloudy": self = .partlyCloudy
        case "mostly_cloudy": self = .mostlyCloudy
        case "cloudy": self = .cloudy
        case "clear": self = .clear
        case "mostly_clear": self = .mostlyClear
        case "slight_chance_showers": self = .slightChanceShowers
        case "chance_showers": self = .chanceShowers
        case "chance_rain": self = .chanceRain
        case "showers_likely": self = .showersLikely
        case "rain_likely": self = .rainLikely
        case "showers": self = .showers
        case "rain": self = .rain
        case "light_rain": self = .lightRain
        case "heavy_rain": self = .heavyRain
        case "slight_chance_rain_snow_mix": self = .slightChanceRainSnowMix
        case "chance_rain_snow_mix": self = .chanceRainSnowMix
        case "rain_snow_mix_likely": self = .rainSnowMixLikely
        case "rain_snow_mix": self = .rainSnowMix
        case "slight_chance_snow": self = .slightChanceSnow
        case "chance_snow": self = .chanceSnow
        case "snow_likely": self = .snowLikely
        case "snow": self = .snow
        case "slight_chance_freezing_rain": self = .slightChanceFreezingRain
        case "chance_freezing_rain": self = .chanceFreezingRain
        case "freezing_rain_likely": self = .freezingRainLikely
        case "freezing_rain": self = .freezingRain
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .sunny: "sunny"
        case .mostlySunny: "mostly_sunny"
        case .partlyCloudy: "partly_cloudy"
        case .mostlyCloudy: "mostly_cloudy"
        case .cloudy: "cloudy"
        case .clear: "clear"
        case .mostlyClear: "mostly_clear"
        case .slightChanceShowers: "slight_chance_showers"
        case .chanceShowers: "chance_showers"
        case .chanceRain: "chance_rain"
        case .showersLikely: "showers_likely"
        case .rainLikely: "rain_likely"
        case .showers: "showers"
        case .rain: "rain"
        case .lightRain: "light_rain"
        case .heavyRain: "heavy_rain"
        case .slightChanceRainSnowMix: "slight_chance_rain_snow_mix"
        case .chanceRainSnowMix: "chance_rain_snow_mix"
        case .rainSnowMixLikely: "rain_snow_mix_likely"
        case .rainSnowMix: "rain_snow_mix"
        case .slightChanceSnow: "slight_chance_snow"
        case .chanceSnow: "chance_snow"
        case .snowLikely: "snow_likely"
        case .snow: "snow"
        case .slightChanceFreezingRain: "slight_chance_freezing_rain"
        case .chanceFreezingRain: "chance_freezing_rain"
        case .freezingRainLikely: "freezing_rain_likely"
        case .freezingRain: "freezing_rain"
        case .unknown(let raw): raw
        }
    }
}

/// An icon hint for an hour or a day; night hints carry a `night` prefix.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum ConditionIcon: Sendable, Hashable {
    /// `sunny`.
    case sunny
    /// `mostly_sunny`.
    case mostlySunny
    /// `partly_cloudy`.
    case partlyCloudy
    /// `mostly_cloudy`.
    case mostlyCloudy
    /// `cloudy`.
    case cloudy
    /// `sun_chance_showers`.
    case sunChanceShowers
    /// `sun_showers_likely`.
    case sunShowersLikely
    /// `sun_showers`.
    case sunShowers
    /// `chance_showers`.
    case chanceShowers
    /// `chance_rain`.
    case chanceRain
    /// `showers_likely`.
    case showersLikely
    /// `rain_likely`.
    case rainLikely
    /// `showers`.
    case showers
    /// `rain`.
    case rain
    /// `light_rain`.
    case lightRain
    /// `heavy_rain`.
    case heavyRain
    /// `rain_snow_mix`.
    case rainSnowMix
    /// `snow`.
    case snow
    /// `freezing_rain`.
    case freezingRain
    /// `night_clear`.
    case nightClear
    /// `night_mostly_clear`.
    case nightMostlyClear
    /// `night_partly_cloudy`.
    case nightPartlyCloudy
    /// `night_mostly_cloudy`.
    case nightMostlyCloudy
    /// `night_cloudy`.
    case nightCloudy
    /// `night_moon_chance_showers`.
    case nightMoonChanceShowers
    /// `night_moon_showers_likely`.
    case nightMoonShowersLikely
    /// `night_chance_showers`.
    case nightChanceShowers
    /// `night_showers_likely`.
    case nightShowersLikely
    /// `night_rain`.
    case nightRain
    /// `night_light_rain`.
    case nightLightRain
    /// `night_heavy_rain`.
    case nightHeavyRain
    /// `night_rain_snow_mix`.
    case nightRainSnowMix
    /// `night_snow`.
    case nightSnow
    /// `night_freezing_rain`.
    case nightFreezingRain
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension ConditionIcon: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "sunny": self = .sunny
        case "mostly_sunny": self = .mostlySunny
        case "partly_cloudy": self = .partlyCloudy
        case "mostly_cloudy": self = .mostlyCloudy
        case "cloudy": self = .cloudy
        case "sun_chance_showers": self = .sunChanceShowers
        case "sun_showers_likely": self = .sunShowersLikely
        case "sun_showers": self = .sunShowers
        case "chance_showers": self = .chanceShowers
        case "chance_rain": self = .chanceRain
        case "showers_likely": self = .showersLikely
        case "rain_likely": self = .rainLikely
        case "showers": self = .showers
        case "rain": self = .rain
        case "light_rain": self = .lightRain
        case "heavy_rain": self = .heavyRain
        case "rain_snow_mix": self = .rainSnowMix
        case "snow": self = .snow
        case "freezing_rain": self = .freezingRain
        case "night_clear": self = .nightClear
        case "night_mostly_clear": self = .nightMostlyClear
        case "night_partly_cloudy": self = .nightPartlyCloudy
        case "night_mostly_cloudy": self = .nightMostlyCloudy
        case "night_cloudy": self = .nightCloudy
        case "night_moon_chance_showers": self = .nightMoonChanceShowers
        case "night_moon_showers_likely": self = .nightMoonShowersLikely
        case "night_chance_showers": self = .nightChanceShowers
        case "night_showers_likely": self = .nightShowersLikely
        case "night_rain": self = .nightRain
        case "night_light_rain": self = .nightLightRain
        case "night_heavy_rain": self = .nightHeavyRain
        case "night_rain_snow_mix": self = .nightRainSnowMix
        case "night_snow": self = .nightSnow
        case "night_freezing_rain": self = .nightFreezingRain
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .sunny: "sunny"
        case .mostlySunny: "mostly_sunny"
        case .partlyCloudy: "partly_cloudy"
        case .mostlyCloudy: "mostly_cloudy"
        case .cloudy: "cloudy"
        case .sunChanceShowers: "sun_chance_showers"
        case .sunShowersLikely: "sun_showers_likely"
        case .sunShowers: "sun_showers"
        case .chanceShowers: "chance_showers"
        case .chanceRain: "chance_rain"
        case .showersLikely: "showers_likely"
        case .rainLikely: "rain_likely"
        case .showers: "showers"
        case .rain: "rain"
        case .lightRain: "light_rain"
        case .heavyRain: "heavy_rain"
        case .rainSnowMix: "rain_snow_mix"
        case .snow: "snow"
        case .freezingRain: "freezing_rain"
        case .nightClear: "night_clear"
        case .nightMostlyClear: "night_mostly_clear"
        case .nightPartlyCloudy: "night_partly_cloudy"
        case .nightMostlyCloudy: "night_mostly_cloudy"
        case .nightCloudy: "night_cloudy"
        case .nightMoonChanceShowers: "night_moon_chance_showers"
        case .nightMoonShowersLikely: "night_moon_showers_likely"
        case .nightChanceShowers: "night_chance_showers"
        case .nightShowersLikely: "night_showers_likely"
        case .nightRain: "night_rain"
        case .nightLightRain: "night_light_rain"
        case .nightHeavyRain: "night_heavy_rain"
        case .nightRainSnowMix: "night_rain_snow_mix"
        case .nightSnow: "night_snow"
        case .nightFreezingRain: "night_freezing_rain"
        case .unknown(let raw): raw
        }
    }
}

/// The type of precipitation expected.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum PrecipitationType: Sendable, Hashable {
    /// `rain`.
    case rain
    /// `snow`.
    case snow
    /// `rain_snow_mix`.
    case rainSnowMix
    /// `freezing_rain`.
    case freezingRain
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension PrecipitationType: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "rain": self = .rain
        case "snow": self = .snow
        case "rain_snow_mix": self = .rainSnowMix
        case "freezing_rain": self = .freezingRain
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .rain: "rain"
        case .snow: "snow"
        case .rainSnowMix: "rain_snow_mix"
        case .freezingRain: "freezing_rain"
        case .unknown(let raw): raw
        }
    }
}

/// What a day's precipitation display shows.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum PrecipitationDisplayKind: Sendable, Hashable {
    /// `none`.
    case noPrecipitation
    /// `rain`.
    case rain
    /// `snow`.
    case snow
    /// `rain_snow_mix`.
    case rainSnowMix
    /// `freezing_rain`.
    case freezingRain
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension PrecipitationDisplayKind: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "none": self = .noPrecipitation
        case "rain": self = .rain
        case "snow": self = .snow
        case "rain_snow_mix": self = .rainSnowMix
        case "freezing_rain": self = .freezingRain
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .noPrecipitation: "none"
        case .rain: "rain"
        case .snow: "snow"
        case .rainSnowMix: "rain_snow_mix"
        case .freezingRain: "freezing_rain"
        case .unknown(let raw): raw
        }
    }
}

/// A live nowcast source a response may have been built without.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum NowcastSource: Sendable, Hashable {
    /// `observation`.
    case observation
    /// `radar`.
    case radar
    /// `cloud`.
    case cloud
    /// `nearest_sensors`.
    case nearestSensors
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension NowcastSource: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "observation": self = .observation
        case "radar": self = .radar
        case "cloud": self = .cloud
        case "nearest_sensors": self = .nearestSensors
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .observation: "observation"
        case .radar: "radar"
        case .cloud: "cloud"
        case .nearestSensors: "nearest_sensors"
        case .unknown(let raw): raw
        }
    }
}

/// Which member view a forecast carries.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum MembersView: Sendable, Hashable {
    /// `plume`.
    case plume
    /// `full`.
    case full
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension MembersView: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "plume": self = .plume
        case "full": self = .full
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .plume: "plume"
        case .full: "full"
        case .unknown(let raw): raw
        }
    }
}

/// The strength of Columbia Gorge gap flow.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum GapFlowStatus: Sendable, Hashable {
    /// `none`.
    case noGapFlow
    /// `moderate`.
    case moderate
    /// `strong`.
    case strong
    /// `extreme`.
    case extreme
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension GapFlowStatus: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "none": self = .noGapFlow
        case "moderate": self = .moderate
        case "strong": self = .strong
        case "extreme": self = .extreme
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .noGapFlow: "none"
        case .moderate: "moderate"
        case .strong: "strong"
        case .extreme: "extreme"
        case .unknown(let raw): raw
        }
    }
}

/// A day's wind class.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum WindStatus: Sendable, Hashable {
    /// `calm`.
    case calm
    /// `light`.
    case light
    /// `moderate`.
    case moderate
    /// `strong`.
    case strong
    /// `very_strong`.
    case veryStrong
    /// `extreme`.
    case extreme
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension WindStatus: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "calm": self = .calm
        case "light": self = .light
        case "moderate": self = .moderate
        case "strong": self = .strong
        case "very_strong": self = .veryStrong
        case "extreme": self = .extreme
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .calm: "calm"
        case .light: "light"
        case .moderate: "moderate"
        case .strong: "strong"
        case .veryStrong: "very_strong"
        case .extreme: "extreme"
        case .unknown(let raw): raw
        }
    }
}

/// Whether a day's snow fell light on dense or dense on light.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum StormOrientation: Sendable, Hashable {
    /// `right_side_up`.
    case rightSideUp
    /// `upside_down`.
    case upsideDown
    /// `mixed`.
    case mixed
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension StormOrientation: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "right_side_up": self = .rightSideUp
        case "upside_down": self = .upsideDown
        case "mixed": self = .mixed
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .rightSideUp: "right_side_up"
        case .upsideDown: "upside_down"
        case .mixed: "mixed"
        case .unknown(let raw): raw
        }
    }
}

/// The phase of the moon.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum MoonPhase: Sendable, Hashable {
    /// `new_moon`.
    case newMoon
    /// `waxing_crescent`.
    case waxingCrescent
    /// `first_quarter`.
    case firstQuarter
    /// `waxing_gibbous`.
    case waxingGibbous
    /// `full_moon`.
    case fullMoon
    /// `waning_gibbous`.
    case waningGibbous
    /// `last_quarter`.
    case lastQuarter
    /// `waning_crescent`.
    case waningCrescent
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension MoonPhase: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "new_moon": self = .newMoon
        case "waxing_crescent": self = .waxingCrescent
        case "first_quarter": self = .firstQuarter
        case "waxing_gibbous": self = .waxingGibbous
        case "full_moon": self = .fullMoon
        case "waning_gibbous": self = .waningGibbous
        case "last_quarter": self = .lastQuarter
        case "waning_crescent": self = .waningCrescent
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .newMoon: "new_moon"
        case .waxingCrescent: "waxing_crescent"
        case .firstQuarter: "first_quarter"
        case .waxingGibbous: "waxing_gibbous"
        case .fullMoon: "full_moon"
        case .waningGibbous: "waning_gibbous"
        case .lastQuarter: "last_quarter"
        case .waningCrescent: "waning_crescent"
        case .unknown(let raw): raw
        }
    }
}

/// The astronomical season.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum AstronomicalSeason: Sendable, Hashable {
    /// `spring`.
    case spring
    /// `summer`.
    case summer
    /// `autumn`.
    case autumn
    /// `winter`.
    case winter
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension AstronomicalSeason: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "spring": self = .spring
        case "summer": self = .summer
        case "autumn": self = .autumn
        case "winter": self = .winter
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .spring: "spring"
        case .summer: "summer"
        case .autumn: "autumn"
        case .winter: "winter"
        case .unknown(let raw): raw
        }
    }
}

/// Where a point forecast's elevation came from.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum ElevationSource: Sendable, Hashable {
    /// `request`.
    case request
    /// `dem_3dep_10m`.
    case digitalElevationModel
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension ElevationSource: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "request": self = .request
        case "dem_3dep_10m": self = .digitalElevationModel
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .request: "request"
        case .digitalElevationModel: "dem_3dep_10m"
        case .unknown(let raw): raw
        }
    }
}

/// What current conditions were read from.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum ConditionsSource: Sendable, Hashable {
    /// `nowcast`.
    case nowcast
    /// `model`.
    case model
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension ConditionsSource: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "nowcast": self = .nowcast
        case "model": self = .model
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .nowcast: "nowcast"
        case .model: "model"
        case .unknown(let raw): raw
        }
    }
}

/// The kind of temperature inversion detected.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum InversionKind: Sendable, Hashable {
    /// `surface_shallow`.
    case surfaceShallow
    /// `cold_pool`.
    case coldPool
    /// `elevated`.
    case elevated
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension InversionKind: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "surface_shallow": self = .surfaceShallow
        case "cold_pool": self = .coldPool
        case "elevated": self = .elevated
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .surfaceShallow: "surface_shallow"
        case .coldPool: "cold_pool"
        case .elevated: "elevated"
        case .unknown(let raw): raw
        }
    }
}

/// The kind of data an attribution source provides.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum AttributionSourceKind: Sendable, Hashable {
    /// `model`.
    case model
    /// `peer`.
    case peer
    /// `observation`.
    case observation
    /// `alerts`.
    case alerts
    /// `climatology`.
    case climatology
    /// `terrain`.
    case terrain
    /// `places`.
    case places
    /// `basemap`.
    case basemap
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension AttributionSourceKind: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "model": self = .model
        case "peer": self = .peer
        case "observation": self = .observation
        case "alerts": self = .alerts
        case "climatology": self = .climatology
        case "terrain": self = .terrain
        case "places": self = .places
        case "basemap": self = .basemap
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .model: "model"
        case .peer: "peer"
        case .observation: "observation"
        case .alerts: "alerts"
        case .climatology: "climatology"
        case .terrain: "terrain"
        case .places: "places"
        case .basemap: "basemap"
        case .unknown(let raw): raw
        }
    }
}

/// A variable named in an hour's provenance tags.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum ProvenanceVariable: Sendable, Hashable {
    /// `temperature`.
    case temperature
    /// `dewpoint`.
    case dewpoint
    /// `precipitation`.
    case precipitation
    /// `snowfall`.
    case snowfall
    /// `wind_speed`.
    case windSpeed
    /// `wind_gust`.
    case windGust
    /// `snow_level`.
    case snowLevel
    /// `cloud_cover`.
    case cloudCover
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension ProvenanceVariable: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "temperature": self = .temperature
        case "dewpoint": self = .dewpoint
        case "precipitation": self = .precipitation
        case "snowfall": self = .snowfall
        case "wind_speed": self = .windSpeed
        case "wind_gust": self = .windGust
        case "snow_level": self = .snowLevel
        case "cloud_cover": self = .cloudCover
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .temperature: "temperature"
        case .dewpoint: "dewpoint"
        case .precipitation: "precipitation"
        case .snowfall: "snowfall"
        case .windSpeed: "wind_speed"
        case .windGust: "wind_gust"
        case .snowLevel: "snow_level"
        case .cloudCover: "cloud_cover"
        case .unknown(let raw): raw
        }
    }
}

/// A request option the server clamped to the caller's tier.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum ClampedOption: Sendable, Hashable {
    /// `max_hours`.
    case maxHours
    /// `max_days`.
    case maxDays
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension ClampedOption: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "max_hours": self = .maxHours
        case "max_days": self = .maxDays
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .maxHours: "max_hours"
        case .maxDays: "max_days"
        case .unknown(let raw): raw
        }
    }
}

/// The kind of a catalog page template section.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum CatalogTemplateSectionKind: Sendable, Hashable {
    /// `weather_panel`.
    case weatherPanel
    /// `content_slot`.
    case contentSlot
    /// `ad_slot`.
    case adSlot
    /// `media`.
    case media
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension CatalogTemplateSectionKind: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "weather_panel": self = .weatherPanel
        case "content_slot": self = .contentSlot
        case "ad_slot": self = .adSlot
        case "media": self = .media
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .weatherPanel: "weather_panel"
        case .contentSlot: "content_slot"
        case .adSlot: "ad_slot"
        case .media: "media"
        case .unknown(let raw): raw
        }
    }
}

/// The kind of an ad slot placement.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum CatalogAdSlotKind: Sendable, Hashable {
    /// `house`.
    case house
    /// `third_party`.
    case thirdParty
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension CatalogAdSlotKind: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "house": self = .house
        case "third_party": self = .thirdParty
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .house: "house"
        case .thirdParty: "third_party"
        case .unknown(let raw): raw
        }
    }
}

/// A third-party ad provider.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum CatalogAdProvider: Sendable, Hashable {
    /// `adsense`.
    case adsense
    /// `gam`.
    case gam
    /// `custom`.
    case custom
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension CatalogAdProvider: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "adsense": self = .adsense
        case "gam": self = .gam
        case "custom": self = .custom
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .adsense: "adsense"
        case .gam: "gam"
        case .custom: "custom"
        case .unknown(let raw): raw
        }
    }
}
