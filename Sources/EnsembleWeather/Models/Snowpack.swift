// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The snowpack forecast of a location's spots.
public struct SnowpackResponse: Sendable, Hashable, Codable {
    /// Always `true` while the product is a beta; fields may be added.
    public var isBeta: Bool
    /// Location.
    public var location: LocationReference
    /// Units.
    public var units: UnitSystem
    /// Model run.
    public var modelRun: SnowpackRun?
    /// The newest run's blend cycle is more than 24 h old.
    public var isStale: Bool
    /// The location's own point first, then its named elevations in their display order.
    public var spots: [SnowpackSpot]
    /// Definitions.
    public var definitions: SnowpackDefinitions

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        isBeta: Bool, location: LocationReference, units: UnitSystem, modelRun: SnowpackRun? = nil,
        isStale: Bool, spots: [SnowpackSpot], definitions: SnowpackDefinitions
    ) {
        self.isBeta = isBeta
        self.location = location
        self.units = units
        self.modelRun = modelRun
        self.isStale = isStale
        self.spots = spots
        self.definitions = definitions
    }

    enum CodingKeys: String, CodingKey {
        case isBeta = "beta"
        case location
        case units
        case modelRun = "model_run"
        case isStale = "stale"
        case spots
        case definitions
    }
}

/// The text of each surface class and layer form code a snowpack response uses, keyed by the raw code.
public struct SnowpackDefinitions: Sendable, Hashable, Codable {
    /// Each surface class and what it means.
    public var surface: [String: String]
    /// Each layer form and what it is.
    public var layerForm: [String: String]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        surface: [String: String], layerForm: [String: String]
    ) {
        self.surface = surface
        self.layerForm = layerForm
    }

    enum CodingKeys: String, CodingKey {
        case surface
        case layerForm = "layer_form"
    }
}

/// The newest snowpack run among the spots served.
public struct SnowpackRun: Sendable, Hashable, Codable {
    /// The blend cycle the snowpack model was driven with.
    public var initializedAt: Date
    /// Generated at.
    public var generatedAt: Date
    /// Model.
    public var model: SnowpackModel

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        initializedAt: Date, generatedAt: Date, model: SnowpackModel
    ) {
        self.initializedAt = initializedAt
        self.generatedAt = generatedAt
        self.model = model
    }

    enum CodingKeys: String, CodingKey {
        case initializedAt = "initialized_at"
        case generatedAt = "generated_at"
        case model
    }
}

/// The snowpack model a run was made with.
public struct SnowpackModel: Sendable, Hashable, Codable {
    /// Name.
    public var name: String
    /// By.
    public var by: String
    /// License.
    public var license: String
    /// The build that ran: the commits of Ourea's SNOWPACK and MeteoIO source it was built from, as `snowpack <commit> meteoio <commit>`.
    public var version: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        name: String, by: String, license: String, version: String? = nil
    ) {
        self.name = name
        self.by = by
        self.license = license
        self.version = version
    }

    enum CodingKeys: String, CodingKey {
        case name
        case by
        case license
        case version
    }
}

/// One spot's snowpack forecast: the location's own point or one of its named elevations.
public struct SnowpackSpot: Sendable, Hashable, Codable {
    /// The named elevation (`location.elevations[].name`); `null` is the location's own point.
    public var name: String?
    /// What the named elevation is called, as `ElevationSummary.display_name`; absent for the location's own point and where the catalog has no name for the elevation.
    public var displayName: String?
    /// In the response's units (m or ft).
    public var elevation: Double
    /// Elevation m.
    public var elevationMeters: Double
    /// The blend cycle this spot's forecast was driven with; older than `model_run.initialized_at` when the newest run did not reach the spot.
    public var initializedAt: Date
    /// The snow-depth sensor at the spot.
    public var anchor: SnowpackAnchor?
    /// Depth.
    public var depth: SnowpackDepth
    /// The depth at `depth.start_time` less this spot's modelled depth 24 h before, in the depth's units and rounding (cm or in; a loss is negative): the model's own change, snowfall, settlement and melt together.
    public var depthChange24Hours: Double?
    /// Hourly snow water equivalent (mm or in), parallel to `depth.p50`.
    public var snowWaterEquivalent: [Double]
    /// One entry every six hours.
    public var steps: [SnowpackStep]
    /// Buried layers at `depth.start_time`, at most three.
    public var layers: [SnowpackLayer]
    /// The snow on a 38° slope at the spot facing each way, in the order north, east, south, west.
    public var aspects: [SnowpackAspect]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        name: String? = nil, displayName: String? = nil, elevation: Double, elevationMeters: Double,
        initializedAt: Date, anchor: SnowpackAnchor? = nil, depth: SnowpackDepth,
        depthChange24Hours: Double? = nil, snowWaterEquivalent: [Double], steps: [SnowpackStep],
        layers: [SnowpackLayer], aspects: [SnowpackAspect]? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.elevation = elevation
        self.elevationMeters = elevationMeters
        self.initializedAt = initializedAt
        self.anchor = anchor
        self.depth = depth
        self.depthChange24Hours = depthChange24Hours
        self.snowWaterEquivalent = snowWaterEquivalent
        self.steps = steps
        self.layers = layers
        self.aspects = aspects
    }

    enum CodingKeys: String, CodingKey {
        case name
        case displayName = "display_name"
        case elevation
        case elevationMeters = "elevation_m"
        case initializedAt = "initialized_at"
        case anchor
        case depth
        case depthChange24Hours = "depth_change_24h"
        case snowWaterEquivalent = "swe"
        case steps
        case layers
        case aspects
    }
}

/// The snow-depth sensor at the spot.
public struct SnowpackAnchor: Sendable, Hashable, Codable {
    /// The station's catalog slug.
    public var station: String
    /// Name.
    public var name: String
    /// Network.
    public var network: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        station: String, name: String, network: String
    ) {
        self.station = station
        self.name = name
        self.network = network
    }

    enum CodingKeys: String, CodingKey {
        case station
        case name
        case network
    }
}

/// The snowpack at a spot at one step.
public struct SnowpackStep: Sendable, Hashable, Codable {
    /// Valid time.
    public var validTime: Date
    /// A key of `definitions.surface`: today `none`, `powder`, `wind_affected`, `settled`, `wet`, `crust` or `ice_crust`.
    public var surface: String
    /// New snow of the 24 h to `valid_time`, as it lies (cm or in).
    public var newSnow24Hours: Double
    /// Its density.
    public var newSnowDensityKgM3: Double?
    /// How far the snow on the ground 24 h earlier settled (cm or in).
    public var settlement24Hours: Double?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        validTime: Date, surface: String, newSnow24Hours: Double, newSnowDensityKgM3: Double? = nil,
        settlement24Hours: Double? = nil
    ) {
        self.validTime = validTime
        self.surface = surface
        self.newSnow24Hours = newSnow24Hours
        self.newSnowDensityKgM3 = newSnowDensityKgM3
        self.settlement24Hours = settlement24Hours
    }

    enum CodingKeys: String, CodingKey {
        case validTime = "valid_time"
        case surface
        case newSnow24Hours = "new_snow_24h"
        case newSnowDensityKgM3 = "new_snow_density_kg_m3"
        case settlement24Hours = "settlement_24h"
    }
}

/// One layer of the snowpack.
public struct SnowpackLayer: Sendable, Hashable, Codable {
    /// A key of `definitions.layer_form`: today `faceted_grains`, `depth_hoar`, `buried_surface_hoar`, `melt_freeze_crust`, `ice_layer` or `rounding_facets`.
    public var form: String
    /// cm or in.
    public var thickness: Double
    /// From the surface down to the layer's top (cm or in).
    public var depth: Double
    /// Formed.
    public var formed: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        form: String, thickness: Double, depth: Double, formed: String
    ) {
        self.form = form
        self.thickness = thickness
        self.depth = depth
        self.formed = formed
    }

    enum CodingKeys: String, CodingKey {
        case form
        case thickness
        case depth
        case formed
    }
}

/// The snow on one slope at a spot, described as the spot's flat ground is: the model run on a slope of `slope_angle_deg` facing `aspect`, with the flat ground's snowfall and the slope's own sun.
public struct SnowpackAspect: Sendable, Hashable, Codable {
    /// The way the slope faces: today `north`, `east`, `south` or `west`.
    public var aspect: String
    /// How steep the slope is, degrees from horizontal.
    public var slopeAngleDegrees: Double
    /// Hourly snow depth on the slope, measured vertically as the flat depth is.
    public var depth: SnowpackDepth
    /// As the spot's `depth_change_24h`, this slope's own (open loop on both sides), read from the same earlier run as the spot's and from no other.
    public var depthChange24Hours: Double?
    /// One entry every six hours, at the spot's own `steps[].valid_time`.
    public var steps: [SnowpackStep]
    /// Buried layers on the slope at `depth.start_time`, at most three.
    public var layers: [SnowpackLayer]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        aspect: String, slopeAngleDegrees: Double, depth: SnowpackDepth,
        depthChange24Hours: Double? = nil, steps: [SnowpackStep], layers: [SnowpackLayer]
    ) {
        self.aspect = aspect
        self.slopeAngleDegrees = slopeAngleDegrees
        self.depth = depth
        self.depthChange24Hours = depthChange24Hours
        self.steps = steps
        self.layers = layers
    }

    enum CodingKeys: String, CodingKey {
        case aspect
        case slopeAngleDegrees = "slope_angle_deg"
        case depth
        case depthChange24Hours = "depth_change_24h"
        case steps
        case layers
    }
}

/// Hourly snow depth from `start_time` (cm or in).
public struct SnowpackDepth: Sendable, Hashable, Codable {
    /// Start time.
    public var startTime: Date
    /// Interval hours.
    public var intervalHours: Int
    /// `measured`: started from a sensor reading at the spot.
    public var basis: String
    /// The 10th percentile.
    public var p10: [Double]?
    /// The 50th percentile.
    public var p50: [Double]
    /// The 90th percentile.
    public var p90: [Double]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        startTime: Date, intervalHours: Int, basis: String, p10: [Double]? = nil, p50: [Double],
        p90: [Double]? = nil
    ) {
        self.startTime = startTime
        self.intervalHours = intervalHours
        self.basis = basis
        self.p10 = p10
        self.p50 = p50
        self.p90 = p90
    }

    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case intervalHours = "interval_hours"
        case basis
        case p10
        case p50
        case p90
    }
}

/// A location's snow-depth plume.
public struct SnowpackPlumeResponse: Sendable, Hashable, Codable {
    /// Always `true` while the product is a beta; fields may be added.
    public var isBeta: Bool
    /// Location.
    public var location: LocationReference
    /// Units.
    public var units: UnitSystem
    /// The run the plume is from: the 12Z blend cycle the members were read from.
    public var modelRun: SnowpackRun?
    /// The plume's blend cycle is more than 24 h old.
    public var isStale: Bool
    /// The members' depth at each step.
    public var depth: SnowpackPlumeDepth?
    /// Every member's own series, by model, each model to its own horizon.
    public var models: [SnowpackPlumeModel]?
    /// Every member's depth as ONE unlabelled pool, for Free and anonymous callers (absent for Plus and Pro, who are served `models`).
    public var memberDepths: [[Double]]?
    /// What the bands are, in a sentence a client may show beside them.
    public var spread: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        isBeta: Bool, location: LocationReference, units: UnitSystem, modelRun: SnowpackRun? = nil,
        isStale: Bool, depth: SnowpackPlumeDepth? = nil, models: [SnowpackPlumeModel]? = nil,
        memberDepths: [[Double]]? = nil, spread: String
    ) {
        self.isBeta = isBeta
        self.location = location
        self.units = units
        self.modelRun = modelRun
        self.isStale = isStale
        self.depth = depth
        self.models = models
        self.memberDepths = memberDepths
        self.spread = spread
    }

    enum CodingKeys: String, CodingKey {
        case isBeta = "beta"
        case location
        case units
        case modelRun = "model_run"
        case isStale = "stale"
        case depth
        case models
        case memberDepths = "member_depths"
        case spread
    }
}

/// The members' depth at each step.
public struct SnowpackPlumeDepth: Sendable, Hashable, Codable {
    /// The time of the first value of every series in the body.
    public var startTime: Date
    /// Hours between values (3).
    public var intervalHours: Int
    /// Members that reach each step; it falls where a model's horizon ends.
    public var members: [Int]
    /// The members' median depth, in the response's units.
    public var p50: [Double]?
    /// Served to every caller, as the bands are.
    public var mean: [Double]
    /// Every caller (Plus and Pro only before).
    public var p10: [Double]
    /// Every caller (Plus and Pro only before).
    public var p25: [Double]
    /// Every caller (Plus and Pro only before).
    public var p75: [Double]
    /// Every caller (Plus and Pro only before).
    public var p90: [Double]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        startTime: Date, intervalHours: Int, members: [Int], p50: [Double]? = nil, mean: [Double],
        p10: [Double], p25: [Double], p75: [Double], p90: [Double]
    ) {
        self.startTime = startTime
        self.intervalHours = intervalHours
        self.members = members
        self.p50 = p50
        self.mean = mean
        self.p10 = p10
        self.p25 = p25
        self.p75 = p75
        self.p90 = p90
    }

    enum CodingKeys: String, CodingKey {
        case startTime = "start_time"
        case intervalHours = "interval_hours"
        case members
        case p50
        case mean
        case p10
        case p25
        case p75
        case p90
    }
}

/// One model's members in a snow-depth plume.
public struct SnowpackPlumeModel: Sendable, Hashable, Codable {
    /// `aifs`, `aigefs`, `gefs` or `ifs_ens`; a client must tolerate one it does not know.
    public var id: String
    /// The model's own member numbers, in the order of `depth`.
    public var memberIDs: [Int]
    /// One series per member, from `depth.start_time` every `depth.interval_hours`.
    public var depth: [[Double]]
    /// The equal-weight mean of this model's members' `depth` at each of the model's own steps (from `depth.start_time` every `depth.interval_hours`, to the model's horizon: the length of its members' series), in the response's units.
    public var depthMean: [Double]
    /// Members not run because the ground starts bare and they bring no snow; their series is 0 throughout.
    public var membersSkipped: Int

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, memberIDs: [Int], depth: [[Double]], depthMean: [Double], membersSkipped: Int
    ) {
        self.id = id
        self.memberIDs = memberIDs
        self.depth = depth
        self.depthMean = depthMean
        self.membersSkipped = membersSkipped
    }

    enum CodingKeys: String, CodingKey {
        case id
        case memberIDs = "member_ids"
        case depth
        case depthMean = "depth_mean"
        case membersSkipped = "members_skipped"
    }
}
