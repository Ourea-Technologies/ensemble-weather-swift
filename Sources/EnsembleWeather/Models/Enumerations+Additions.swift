// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// A metric places are ranked by: the `metric` of `explore`, and the `sort` of `searchLocations`.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum ExploreMetric: Sendable, Hashable {
    /// `base_depth`.
    case baseDepth
    /// `new_snow_24h`.
    case newSnow24Hours
    /// `snow_today`.
    case snowToday
    /// `snow_5d`.
    case snow5Days
    /// `snow_10d`.
    case snow10Days
    /// `snow_14d`.
    case snow14Days
    /// `precip_today`.
    case precipToday
    /// `precip_5d`.
    case precip5Days
    /// `precip_10d`.
    case precip10Days
    /// `precip_14d`.
    case precip14Days
    /// `season_precip`.
    case seasonPrecip
    /// `season_precip_pct_normal`.
    case seasonPrecipPercentNormal
    /// `season_snow`.
    case seasonSnow
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension ExploreMetric: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "base_depth": self = .baseDepth
        case "new_snow_24h": self = .newSnow24Hours
        case "snow_today": self = .snowToday
        case "snow_5d": self = .snow5Days
        case "snow_10d": self = .snow10Days
        case "snow_14d": self = .snow14Days
        case "precip_today": self = .precipToday
        case "precip_5d": self = .precip5Days
        case "precip_10d": self = .precip10Days
        case "precip_14d": self = .precip14Days
        case "season_precip": self = .seasonPrecip
        case "season_precip_pct_normal": self = .seasonPrecipPercentNormal
        case "season_snow": self = .seasonSnow
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .baseDepth: "base_depth"
        case .newSnow24Hours: "new_snow_24h"
        case .snowToday: "snow_today"
        case .snow5Days: "snow_5d"
        case .snow10Days: "snow_10d"
        case .snow14Days: "snow_14d"
        case .precipToday: "precip_today"
        case .precip5Days: "precip_5d"
        case .precip10Days: "precip_10d"
        case .precip14Days: "precip_14d"
        case .seasonPrecip: "season_precip"
        case .seasonPrecipPercentNormal: "season_precip_pct_normal"
        case .seasonSnow: "season_snow"
        case .unknown(let raw): raw
        }
    }
}

/// The character of the snow an hour or a day brings.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum SnowCharacter: Sendable, Hashable {
    /// `wet`.
    case wet
    /// `average`.
    case average
    /// `dry`.
    case dry
    /// `dense`.
    case dense
    /// `very_dry`.
    case veryDry
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension SnowCharacter: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "wet": self = .wet
        case "average": self = .average
        case "dry": self = .dry
        case "dense": self = .dense
        case "very_dry": self = .veryDry
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .wet: "wet"
        case .average: "average"
        case .dry: "dry"
        case .dense: "dense"
        case .veryDry: "very_dry"
        case .unknown(let raw): raw
        }
    }
}

/// A class of alert outline: the `class` of `getAlertOutlines`.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum AlertClass: Sendable, Hashable {
    /// `wind`.
    case wind
    /// `winter`.
    case winter
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension AlertClass: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "wind": self = .wind
        case "winter": self = .winter
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .wind: "wind"
        case .winter: "winter"
        case .unknown(let raw): raw
        }
    }
}

/// How restrictive a mountain pass's official status is.
///
/// A value this SDK version does not know yet decodes to ``unknown(_:)``, keeping
/// the raw string, so a newer server never breaks decoding.
public enum PassStatusLevel: Sendable, Hashable {
    /// `none`: no restrictions.
    case unrestricted
    /// `advisory`.
    case advisory
    /// `traction`.
    case traction
    /// `r1`.
    case r1
    /// `r2`.
    case r2
    /// `r3`.
    case r3
    /// `chains`.
    case chains
    /// `closed`.
    case closed
    /// A value this SDK version does not know, with its raw string.
    case unknown(String)
}

extension PassStatusLevel: RawRepresentable, Codable {
    /// Creates a value from its wire string; an unrecognised string is ``unknown(_:)``.
    public init(rawValue: String) {
        switch rawValue {
        case "none": self = .unrestricted
        case "advisory": self = .advisory
        case "traction": self = .traction
        case "r1": self = .r1
        case "r2": self = .r2
        case "r3": self = .r3
        case "chains": self = .chains
        case "closed": self = .closed
        default: self = .unknown(rawValue)
        }
    }

    /// The wire string.
    public var rawValue: String {
        switch self {
        case .unrestricted: "none"
        case .advisory: "advisory"
        case .traction: "traction"
        case .r1: "r1"
        case .r2: "r2"
        case .r3: "r3"
        case .chains: "chains"
        case .closed: "closed"
        case .unknown(let raw): raw
        }
    }
}
