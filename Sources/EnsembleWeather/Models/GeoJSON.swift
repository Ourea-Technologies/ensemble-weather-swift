// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

// The GeoJSON bodies (`getAlertOutlines`, `getAvalancheZones`) are passed
// through untouched (BEHAVIOR 3.0): every key of a feature's `properties` is
// the API's own, with no renames and no case conversion, and coordinates are
// kept as the API sends them, with no reprojection or simplification.

/// A GeoJSON `FeatureCollection` (RFC 7946) of the active winter and wind alerts' outlines.
public struct AlertOutlineCollection: Sendable, Hashable, Codable {
    /// Always `FeatureCollection`.
    public var type: String
    /// One feature per alert, ordered by `properties.id`.
    public var features: [AlertOutlineFeature]
    /// The data sources this response drew on and the credit to carry with it.
    public var attribution: ResponseAttribution?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        type: String = "FeatureCollection", features: [AlertOutlineFeature],
        attribution: ResponseAttribution? = nil
    ) {
        self.type = type
        self.features = features
        self.attribution = attribution
    }

    enum CodingKeys: String, CodingKey {
        case type
        case features
        case attribution
    }
}

/// One alert's outline, a GeoJSON `Feature`.
public struct AlertOutlineFeature: Sendable, Hashable, Codable {
    /// Always `Feature`.
    public var type: String
    /// The outline: a `Polygon` or `MultiPolygon`.
    public var geometry: GeoJSONGeometry
    /// The alert's properties, keyed by their wire names (`event`, `class`, `sender_name`, ...).
    public var properties: [String: JSONValue]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        type: String = "Feature", geometry: GeoJSONGeometry, properties: [String: JSONValue]
    ) {
        self.type = type
        self.geometry = geometry
        self.properties = properties
    }

    enum CodingKeys: String, CodingKey {
        case type
        case geometry
        case properties
    }
}

/// A GeoJSON FeatureCollection of the avalanche forecast zones, with each zone's current rating.
public struct AvalancheZoneCollection: Sendable, Hashable, Codable {
    /// Always `FeatureCollection`.
    public var type: String
    /// One feature per forecast zone.
    public var features: [AvalancheZoneFeature]
    /// The data sources this response drew on and the credit to carry with it.
    public var attribution: ResponseAttribution?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        type: String = "FeatureCollection", features: [AvalancheZoneFeature],
        attribution: ResponseAttribution? = nil
    ) {
        self.type = type
        self.features = features
        self.attribution = attribution
    }

    enum CodingKeys: String, CodingKey {
        case type
        case features
        case attribution
    }
}

/// One avalanche forecast zone, a GeoJSON `Feature`.
public struct AvalancheZoneFeature: Sendable, Hashable, Codable {
    /// Always `Feature`.
    public var type: String
    /// The zone's id, as `properties.zone_id`.
    public var id: Int?
    /// The zone's outline: a `Polygon` or `MultiPolygon`.
    public var geometry: GeoJSONGeometry
    /// The zone's forecast, keyed by its wire names (`danger_level`, `forecast_url`, ...).
    public var properties: [String: JSONValue]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        type: String = "Feature", id: Int? = nil, geometry: GeoJSONGeometry,
        properties: [String: JSONValue]
    ) {
        self.type = type
        self.id = id
        self.geometry = geometry
        self.properties = properties
    }

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case geometry
        case properties
    }
}

/// A GeoJSON geometry: a `Polygon` or a `MultiPolygon`, its positions `[longitude, latitude]` in degrees (WGS84).
public struct GeoJSONGeometry: Sendable, Hashable, Codable {
    /// `Polygon` or `MultiPolygon`.
    public var type: String
    /// The nested position arrays, exactly as sent: the rings of a `Polygon`, or the polygons of a `MultiPolygon`.
    public var coordinates: JSONValue

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(type: String, coordinates: JSONValue) {
        self.type = type
        self.coordinates = coordinates
    }

    enum CodingKeys: String, CodingKey {
        case type
        case coordinates
    }
}
