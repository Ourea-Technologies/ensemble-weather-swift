// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

extension UnitSystem {
    /// The unit of temperatures in this system: `°C`, `°F` or `K`.
    ///
    /// These are labels only: to get values in other units, ask the server
    /// for them (``ForecastOptions/units``). The SDK never converts values.
    public var temperatureUnit: String {
        switch self {
        case .imperial: "°F"
        case .kelvin: "K"
        default: "°C"
        }
    }

    /// The unit of precipitation and snowfall amounts: `mm` or `in`.
    public var amountUnit: String { self == .imperial ? "in" : "mm" }

    /// The unit of wind speeds: `m/s` or `mph`.
    public var speedUnit: String { self == .imperial ? "mph" : "m/s" }

    /// The unit of heights and elevations, such as the snow level: `m` or `ft`.
    public var heightUnit: String { self == .imperial ? "ft" : "m" }
}
