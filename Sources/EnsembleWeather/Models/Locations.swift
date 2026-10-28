// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// A location reference, the same shape wherever a place is named: forecasts, lists, search hits.
public struct LocationReference: Sendable, Hashable, Codable {
    /// The location's key: its catalog slug; `nil` on a point (coordinate) forecast, which names
    /// no catalog place.
    public var slug: String?
    /// The lowercase USPS state code.
    public var state: String
    /// The display name.
    public var name: String
    /// Lat.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// Elevation in metres, whatever `units` is (0.1 m).
    public var elevationMeters: Double
    /// The primary location type; `nil` on a point (coordinate) forecast.
    public var type: LocationType?
    /// The IANA zone the location's local days and hours are kept in -- the zone `daily` dates, sunrise and sunset are computed in.
    public var timezone: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String?, state: String, name: String, latitude: Double, longitude: Double,
        elevationMeters: Double, type: LocationType?, timezone: String
    ) {
        self.slug = slug
        self.state = state
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.type = type
        self.timezone = timezone
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case state
        case name
        case latitude = "lat"
        case longitude = "lon"
        case elevationMeters = "elevation_m"
        case type
        case timezone
    }
}

/// A list, `/nearby` or favorite row: the `LocationRef` fields plus the county, the catalog blurb and the location's named elevations.
public struct LocationSummary: Sendable, Hashable, Codable {
    /// The location's key: its catalog slug.
    public var slug: String
    /// The lowercase USPS state code.
    public var state: String
    /// The display name.
    public var name: String
    /// Lat.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// Elevation in metres, whatever `units` is (0.1 m).
    public var elevationMeters: Double
    /// The primary location type, snake_case.
    public var type: LocationType
    /// The IANA zone the location's local days and hours are kept in -- the zone `daily` dates, sunrise and sunset are computed in.
    public var timezone: String
    /// Administrative county.
    public var county: String
    /// Free-text blurb from the catalog (when present).
    public var description: String?
    /// The location's elevation points (e.g., ski area base / mid / summit), the primary first.
    public var elevations: [LocationElevation]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String, state: String, name: String, latitude: Double, longitude: Double,
        elevationMeters: Double, type: LocationType, timezone: String, county: String,
        description: String? = nil, elevations: [LocationElevation]? = nil
    ) {
        self.slug = slug
        self.state = state
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.type = type
        self.timezone = timezone
        self.county = county
        self.description = description
        self.elevations = elevations
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case state
        case name
        case latitude = "lat"
        case longitude = "lon"
        case elevationMeters = "elevation_m"
        case type
        case timezone
        case county
        case description
        case elevations
    }
}

/// The location's elevation points (e.g., ski area base / mid / summit), the primary first.
public struct LocationElevation: Sendable, Hashable, Codable {
    /// Name.
    public var name: String
    /// In the caller's length units (m, ft), to 0.1.
    public var elevation: Double
    /// Present (true) on the primary only.
    public var isDefault: Bool?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(name: String, elevation: Double, isDefault: Bool? = nil) {
        self.name = name
        self.elevation = elevation
        self.isDefault = isDefault
    }

    enum CodingKeys: String, CodingKey {
        case name
        case elevation
        case isDefault = "default"
    }
}

/// One page of forecast locations, nationwide or in one state.
public struct LocationPage: Sendable, Hashable, Codable {
    /// Display label for the scope: `Oregon`, `Washington`, `California` for a single-state query, or `all` when hitting `/api/v1/locations`.
    public var state: String
    /// Count.
    public var count: Int
    /// Locations.
    public var locations: [LocationSummary]
    /// Present only on a paged response (`limit` given) that has more rows after it.
    public var nextCursor: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(state: String, count: Int, locations: [LocationSummary], nextCursor: String? = nil)
    {
        self.state = state
        self.count = count
        self.locations = locations
        self.nextCursor = nextCursor
    }

    enum CodingKeys: String, CodingKey {
        case state
        case count
        case locations
        case nextCursor = "next_cursor"
    }
}

/// A location near another location or point, with its distance.
public struct NearbyLocation: Sendable, Hashable, Codable {
    /// The location's key: its catalog slug.
    public var slug: String
    /// The lowercase USPS state code.
    public var state: String
    /// The display name.
    public var name: String
    /// Lat.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// Elevation in metres, whatever `units` is (0.1 m).
    public var elevationMeters: Double
    /// The primary location type, snake_case.
    public var type: LocationType
    /// The IANA zone the location's local days and hours are kept in -- the zone `daily` dates, sunrise and sunset are computed in.
    public var timezone: String
    /// Administrative county.
    public var county: String
    /// Free-text blurb from the catalog (when present).
    public var description: String?
    /// The location's elevation points (e.g., ski area base / mid / summit), the primary first.
    public var elevations: [LocationElevation]?
    /// Great-circle distance from the location, km.
    public var distanceKilometers: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String, state: String, name: String, latitude: Double, longitude: Double,
        elevationMeters: Double, type: LocationType, timezone: String, county: String,
        description: String? = nil, elevations: [LocationElevation]? = nil,
        distanceKilometers: Double
    ) {
        self.slug = slug
        self.state = state
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.type = type
        self.timezone = timezone
        self.county = county
        self.description = description
        self.elevations = elevations
        self.distanceKilometers = distanceKilometers
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case state
        case name
        case latitude = "lat"
        case longitude = "lon"
        case elevationMeters = "elevation_m"
        case type
        case timezone
        case county
        case description
        case elevations
        case distanceKilometers = "distance_km"
    }
}

/// The locations nearest a named location.
public struct NearbyLocations: Sendable, Hashable, Codable {
    /// Location.
    public var location: LocationSummary
    /// The radius applied, after the cap.
    public var radiusKilometers: Double
    /// Neighbours in this response (the location itself is not counted).
    public var count: Int
    /// Nearest first.
    public var locations: [NearbyLocation]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        location: LocationSummary, radiusKilometers: Double, count: Int, locations: [NearbyLocation]
    ) {
        self.location = location
        self.radiusKilometers = radiusKilometers
        self.count = count
        self.locations = locations
    }

    enum CodingKeys: String, CodingKey {
        case location
        case radiusKilometers = "radius_km"
        case count
        case locations
    }
}

/// The locations nearest a point.
public struct NearbyPointLocations: Sendable, Hashable, Codable {
    /// Lat.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// Radius km.
    public var radiusKilometers: Double
    /// Count.
    public var count: Int
    /// Locations.
    public var locations: [NearbyLocation]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        latitude: Double, longitude: Double, radiusKilometers: Double, count: Int,
        locations: [NearbyLocation]
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.radiusKilometers = radiusKilometers
        self.count = count
        self.locations = locations
    }

    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lon"
        case radiusKilometers = "radius_km"
        case count
        case locations
    }
}

/// One location search result: the `LocationRef` fields, the county and `key`.
public struct SearchHit: Sendable, Hashable, Codable {
    /// State-qualified identity `"<state>-<slug>"` (lowercase state).
    public var key: String
    /// The location's key: its catalog slug.
    public var slug: String
    /// The lowercase USPS state code.
    public var state: String
    /// The display name.
    public var name: String
    /// Lat.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// Elevation in metres, whatever `units` is (0.1 m).
    public var elevationMeters: Double
    /// The primary location type, snake_case.
    public var type: LocationType
    /// The IANA zone the location's local days and hours are kept in -- the zone `daily` dates, sunrise and sunset are computed in.
    public var timezone: String
    /// County.
    public var county: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        key: String, slug: String, state: String, name: String, latitude: Double, longitude: Double,
        elevationMeters: Double, type: LocationType, timezone: String, county: String
    ) {
        self.key = key
        self.slug = slug
        self.state = state
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.type = type
        self.timezone = timezone
        self.county = county
    }

    enum CodingKeys: String, CodingKey {
        case key
        case slug
        case state
        case name
        case latitude = "lat"
        case longitude = "lon"
        case elevationMeters = "elevation_m"
        case type
        case timezone
        case county
    }
}

/// Location search hits, best match first.
public struct LocationSearchResults: Sendable, Hashable, Codable {
    /// Items.
    public var items: [SearchHit]
    /// Count.
    public var count: Int

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(items: [SearchHit], count: Int) {
        self.items = items
        self.count = count
    }

    enum CodingKeys: String, CodingKey {
        case items
        case count
    }
}

/// On a `PRO_REQUIRED` refusal of a coordinate request: the nearest named location whose
/// forecast answers without a key (within 10 km of the point and 300 m of its elevation).
public struct NearestLocation: Sendable, Hashable, Codable {
    /// The location's slug.
    public var slug: String
    /// The location route's path on this API, with the refused route's suffix (`/current`, `/alerts`).
    public var url: String
    /// The distance from the point, kilometres.
    public var distanceKilometers: Double
    /// The location's elevation, metres.
    public var elevationMeters: Double

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(slug: String, url: String, distanceKilometers: Double, elevationMeters: Double) {
        self.slug = slug
        self.url = url
        self.distanceKilometers = distanceKilometers
        self.elevationMeters = elevationMeters
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case url
        case distanceKilometers = "distance_km"
        case elevationMeters = "elevation_m"
    }
}
