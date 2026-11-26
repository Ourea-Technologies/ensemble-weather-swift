// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// -- observed season-to-date precipitation at a location.
public struct SeasonResponse: Sendable, Hashable, Codable {
    /// Location.
    public var location: LocationReference
    /// The water year by its ending year.
    public var waterYear: Int
    /// The first local day of the water year.
    public var starts: String
    /// The last local day with an observed row (the day before `starts` when there is none).
    public var through: String
    /// When the newest day row was computed; null with no rows.
    public var asOf: Date?
    /// Units.
    public var units: UnitSystem
    /// Null until the location has an observed day.
    public var precipitation: SeasonTotal?
    /// Always null for now; season snowfall is not served yet.
    public var snowfall: SeasonTotal?
    /// The nearest SNOTEL or SCAN gauge within 25 km and 300 m with rows this water year, or null.
    public var station: SeasonStation?
    /// Only with `include=daily`.
    public var daily: [SeasonDay]?
    /// Attribution.
    public var attribution: ResponseAttribution

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        location: LocationReference, waterYear: Int, starts: String, through: String,
        asOf: Date? =
            nil, units: UnitSystem, precipitation: SeasonTotal? = nil, snowfall: SeasonTotal? = nil,
        station: SeasonStation? = nil, daily: [SeasonDay]? = nil, attribution: ResponseAttribution
    ) {
        self.location = location
        self.waterYear = waterYear
        self.starts = starts
        self.through = through
        self.asOf = asOf
        self.units = units
        self.precipitation = precipitation
        self.snowfall = snowfall
        self.station = station
        self.daily = daily
        self.attribution = attribution
    }

    enum CodingKeys: String, CodingKey {
        case location
        case waterYear = "water_year"
        case starts
        case through
        case asOf = "as_of"
        case units
        case precipitation
        case snowfall
        case station
        case daily
        case attribution
    }
}

/// A water-year total so far, with its coverage and its normal.
public struct SeasonTotal: Sendable, Hashable, Codable {
    /// (JSON `total`) Sum over the covered days, in `unit`.
    public var amount: Double
    /// Unit.
    public var unit: String
    /// `mrms_multisensor`: the gridded analysis at the location; `station_gauge`: the location is a gauge site and this is the gauge's accumulator.
    public var source: String
    /// Days covered.
    public var daysCovered: Int
    /// Days since `starts` with no complete observation; not counted as dry.
    public var daysMissing: Int
    /// Covered days still inside the 7-day restate window.
    public var provisionalDays: Int
    /// PRISM 1991-2020 over the covered days, in `unit`; null where no normal is loaded.
    public var normalToDate: Double?
    /// Percent of normal.
    public var percentOfNormal: Int?
    /// Normal source.
    public var normalSource: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        amount: Double, unit: String, source: String, daysCovered: Int, daysMissing: Int,
        provisionalDays: Int, normalToDate: Double? = nil, percentOfNormal: Int? = nil,
        normalSource: String? = nil
    ) {
        self.amount = amount
        self.unit = unit
        self.source = source
        self.daysCovered = daysCovered
        self.daysMissing = daysMissing
        self.provisionalDays = provisionalDays
        self.normalToDate = normalToDate
        self.percentOfNormal = percentOfNormal
        self.normalSource = normalSource
    }

    enum CodingKeys: String, CodingKey {
        case amount = "total"
        case unit
        case source
        case daysCovered = "days_covered"
        case daysMissing = "days_missing"
        case provisionalDays = "provisional_days"
        case normalToDate = "normal_to_date"
        case percentOfNormal = "percent_of_normal"
        case normalSource = "normal_source"
    }
}

/// The nearby station whose season totals are reported beside the location's.
public struct SeasonStation: Sendable, Hashable, Codable {
    /// The NRCS station triplet.
    public var id: String
    /// Network.
    public var network: String
    /// Name.
    public var name: String
    /// Distance km.
    public var distanceKilometers: Double
    /// Elevation m.
    public var elevationMeters: Double
    /// The gauge's water-year accumulator on `through` (mm or in).
    public var precipitationTotal: Double?
    /// Precipitation percent of median.
    public var precipitationPercentOfMedian: Int?
    /// Snow water equivalent on `through` (mm or in).
    public var snowWaterEquivalent: Double?
    /// Swe percent of median.
    public var snowWaterEquivalentPercentOfMedian: Int?
    /// Snow depth on `through` (cm or in).
    public var snowDepth: Double?
    /// The gauge's newest day.
    public var through: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, network: String, name: String, distanceKilometers: Double,
        elevationMeters:
            Double, precipitationTotal: Double? = nil, precipitationPercentOfMedian: Int? = nil,
        snowWaterEquivalent: Double? = nil, snowWaterEquivalentPercentOfMedian: Int? = nil,
        snowDepth: Double? = nil, through: String
    ) {
        self.id = id
        self.network = network
        self.name = name
        self.distanceKilometers = distanceKilometers
        self.elevationMeters = elevationMeters
        self.precipitationTotal = precipitationTotal
        self.precipitationPercentOfMedian = precipitationPercentOfMedian
        self.snowWaterEquivalent = snowWaterEquivalent
        self.snowWaterEquivalentPercentOfMedian = snowWaterEquivalentPercentOfMedian
        self.snowDepth = snowDepth
        self.through = through
    }

    enum CodingKeys: String, CodingKey {
        case id
        case network
        case name
        case distanceKilometers = "distance_km"
        case elevationMeters = "elevation_m"
        case precipitationTotal = "precipitation_total"
        case precipitationPercentOfMedian = "precipitation_percent_of_median"
        case snowWaterEquivalent = "swe"
        case snowWaterEquivalentPercentOfMedian = "swe_percent_of_median"
        case snowDepth = "snow_depth"
        case through
    }
}

/// One day of the season.
public struct SeasonDay: Sendable, Hashable, Codable {
    /// Date.
    public var date: String
    /// The day's total; null when an hour was not observed.
    public var precipitation: Double?
    /// Always null for now.
    public var snowfall: Double?
    /// Provisional.
    public var isProvisional: Bool

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        date: String, precipitation: Double? = nil, snowfall: Double? = nil, isProvisional: Bool
    ) {
        self.date = date
        self.precipitation = precipitation
        self.snowfall = snowfall
        self.isProvisional = isProvisional
    }

    enum CodingKeys: String, CodingKey {
        case date
        case precipitation
        case snowfall
        case isProvisional = "provisional"
    }
}
