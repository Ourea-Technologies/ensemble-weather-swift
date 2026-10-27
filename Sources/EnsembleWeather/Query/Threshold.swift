// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// The threshold of a probability term: a number, optionally with a unit.
///
/// A threshold with a unit is converted to the request's unit system with
/// exact factors (1 in = 25.4 mm, 1 ft = 0.3048 m, 1 mph = 0.44704 m/s,
/// °F = °C × 9/5 + 32, K = °C + 273.15) before it is sent. That converts
/// your input; the SDK never converts response values. A threshold without
/// a unit (a plain number literal) is already in the request's units.
///
/// ```swift
/// .snowfall(atLeast: .inches(6))         // 152.40 on a metric request
/// .temperature(atMost: .fahrenheit(32))  // 0.0 on a metric request
/// .windSpeed(atLeast: 15)                // m/s on metric, mph on imperial
/// ```
public struct Threshold: Sendable, Hashable {
    /// A unit a threshold can be given in.
    public enum Unit: String, Sendable, Hashable, CaseIterable {
        /// Millimetres (precipitation, snowfall).
        case millimeters = "mm"
        /// Inches (precipitation, snowfall).
        case inches = "in"
        /// Degrees Celsius (temperature).
        case celsius = "degC"
        /// Degrees Fahrenheit (temperature).
        case fahrenheit = "degF"
        /// Kelvin (temperature).
        case kelvin = "K"
        /// Metres (snow level).
        case meters = "m"
        /// Feet (snow level).
        case feet = "ft"
        /// Metres per second (wind speed).
        case metersPerSecond = "m/s"
        /// Miles per hour (wind speed).
        case milesPerHour = "mph"
    }

    /// The number, in ``unit`` (or in the request's units when `unit` is `nil`).
    public var value: Double
    /// The unit of ``value``; `nil` means the request's own units.
    public var unit: Unit?

    /// Creates a threshold.
    ///
    /// - Parameters:
    ///   - value: The number.
    ///   - unit: Its unit, or `nil` for the request's own units.
    public init(_ value: Double, unit: Unit? = nil) {
        self.value = value
        self.unit = unit
    }

    /// A threshold in millimetres.
    public static func millimeters(_ value: Double) -> Self { Self(value, unit: .millimeters) }
    /// A threshold in centimetres (sent as millimetres × 10).
    public static func centimeters(_ value: Double) -> Self {
        Self(value * 10, unit: .millimeters)
    }
    /// A threshold in inches.
    public static func inches(_ value: Double) -> Self { Self(value, unit: .inches) }
    /// A threshold in degrees Celsius.
    public static func celsius(_ value: Double) -> Self { Self(value, unit: .celsius) }
    /// A threshold in degrees Fahrenheit.
    public static func fahrenheit(_ value: Double) -> Self { Self(value, unit: .fahrenheit) }
    /// A threshold in kelvin.
    public static func kelvin(_ value: Double) -> Self { Self(value, unit: .kelvin) }
    /// A threshold in metres.
    public static func meters(_ value: Double) -> Self { Self(value, unit: .meters) }
    /// A threshold in feet.
    public static func feet(_ value: Double) -> Self { Self(value, unit: .feet) }
    /// A threshold in metres per second.
    public static func metersPerSecond(_ value: Double) -> Self {
        Self(value, unit: .metersPerSecond)
    }
    /// A threshold in miles per hour.
    public static func milesPerHour(_ value: Double) -> Self { Self(value, unit: .milesPerHour) }
}

extension Threshold: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    /// A threshold in the request's own units.
    public init(floatLiteral value: Double) { self.init(value) }
    /// A threshold in the request's own units.
    public init(integerLiteral value: Int) { self.init(Double(value)) }
}

extension Threshold {
    /// The quantity a variable measures, which fixes the units it accepts.
    enum Dimension {
        case depth, temperature, height, speed
    }

    /// Converts the value to the unit `system` uses for `variable`; a usage error when the
    /// unit does not measure that variable.
    func value(for variable: ForecastVariable, in system: UnitSystem) throws(EnsembleWeatherError)
        -> Double
    {
        guard let dimension = variable.dimension else {
            throw .usage("Unknown forecast variable '\(variable.rawValue)' in a probability term.")
        }
        guard let unit else { return value }
        guard unit.dimension == dimension else {
            throw .usage(
                "A \(variable.rawValue) threshold cannot be in \(unit.rawValue).")
        }
        switch system {
        case .metric, .imperial, .kelvin: break
        case .unknown(let raw):
            throw .usage("Cannot convert a threshold to the unknown unit system '\(raw)'.")
        }
        switch dimension {
        case .depth:
            let millimeters = unit == .inches ? value * 25.4 : value
            return system == .imperial ? millimeters / 25.4 : millimeters
        case .height:
            let meters = unit == .feet ? value * 0.3048 : value
            return system == .imperial ? meters / 0.3048 : meters
        case .speed:
            let metersPerSecond = unit == .milesPerHour ? value * 0.44704 : value
            return system == .imperial ? metersPerSecond / 0.44704 : metersPerSecond
        case .temperature:
            if unit == .celsius && system == .metric { return value }
            if unit == .fahrenheit && system == .imperial { return value }
            if unit == .kelvin && system == .kelvin { return value }
            let celsius: Double
            switch unit {
            case .fahrenheit: celsius = (value - 32) * 5 / 9
            case .kelvin: celsius = value - 273.15
            default: celsius = value
            }
            switch system {
            case .imperial: return celsius * 9 / 5 + 32
            case .kelvin: return celsius + 273.15
            default: return celsius
            }
        }
    }
}

extension Threshold.Unit {
    var dimension: Threshold.Dimension {
        switch self {
        case .millimeters, .inches: .depth
        case .celsius, .fahrenheit, .kelvin: .temperature
        case .meters, .feet: .height
        case .metersPerSecond, .milesPerHour: .speed
        }
    }
}

extension ForecastVariable {
    var dimension: Threshold.Dimension? {
        switch self {
        case .precipitation, .snowfall: .depth
        case .temperature: .temperature
        case .snowLevel: .height
        case .windSpeed: .speed
        case .unknown: nil
        }
    }

    /// The variable's served precision in `system` (BEHAVIOR 4).
    func decimals(in system: UnitSystem) -> Int {
        switch self {
        case .precipitation, .snowfall: system == .imperial ? 3 : 2
        case .temperature, .windSpeed: 1
        case .snowLevel: 0
        case .unknown: 0
        }
    }

    /// The aggregation the server applies when a term names none.
    var defaultAggregation: ProbabilityAggregation {
        self == .precipitation || self == .snowfall ? .total : .any
    }
}
