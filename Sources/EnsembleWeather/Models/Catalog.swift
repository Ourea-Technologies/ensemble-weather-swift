// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// One page of catalog locations; follow ``nextCursor`` for the next.
public struct CatalogLocationPage: Sendable, Hashable, Codable {
    /// Items.
    public var items: [CatalogLocation]
    /// Pass as `?cursor=` for the next page; null at the end.
    public var nextCursor: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(items: [CatalogLocation], nextCursor: String? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
    }
}

/// A catalog location's PUBLIC projection -- the one [`LocationRef`] plus the catalog's public content, by an allowlist.
public struct CatalogLocation: Sendable, Hashable, Codable {
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
    /// The primary location type, snake_case (D-5).
    public var type: LocationType
    /// The IANA zone the location's local days and hours are kept in -- the zone `daily` dates, sunrise and sunset are computed in.
    public var timezone: String
    /// County.
    public var county: String?
    /// Country.
    public var country: String?
    /// Aliases.
    public var aliases: [String]?
    /// Description short.
    public var descriptionShort: String?
    /// Description long.
    public var descriptionLong: String?
    /// Microclimate notes.
    public var microclimateNotes: String?
    /// Meta title.
    public var metaTitle: String?
    /// Meta description.
    public var metaDescription: String?
    /// Best seasons.
    public var bestSeasons: [String]?
    /// Key factors.
    public var keyFactors: [String]?
    /// Tags.
    public var tags: [String]?
    /// Free-form JSON of labelled links.
    public var externalLinks: JSONValue?
    /// Is featured.
    public var isFeatured: Bool?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String, state: String, name: String, latitude: Double, longitude: Double,
        elevationMeters: Double, type: LocationType, timezone: String, county: String? = nil,
        country: String? = nil, aliases: [String]? = nil, descriptionShort: String? = nil,
        descriptionLong: String? = nil, microclimateNotes: String? = nil, metaTitle: String? = nil,
        metaDescription: String? = nil, bestSeasons: [String]? = nil, keyFactors: [String]? = nil,
        tags: [String]? = nil, externalLinks: JSONValue? = nil, isFeatured: Bool? = nil
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
        self.country = country
        self.aliases = aliases
        self.descriptionShort = descriptionShort
        self.descriptionLong = descriptionLong
        self.microclimateNotes = microclimateNotes
        self.metaTitle = metaTitle
        self.metaDescription = metaDescription
        self.bestSeasons = bestSeasons
        self.keyFactors = keyFactors
        self.tags = tags
        self.externalLinks = externalLinks
        self.isFeatured = isFeatured
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
        case country
        case aliases
        case descriptionShort = "description_short"
        case descriptionLong = "description_long"
        case microclimateNotes = "microclimate_notes"
        case metaTitle = "meta_title"
        case metaDescription = "meta_description"
        case bestSeasons = "best_seasons"
        case keyFactors = "key_factors"
        case tags
        case externalLinks = "external_links"
        case isFeatured = "is_featured"
    }
}

/// A catalog location with its elevations, photos, webcams, nearby stations and optional content.
public struct CatalogLocationDetail: Sendable, Hashable, Codable {
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
    /// The primary location type, snake_case (D-5).
    public var type: LocationType
    /// The IANA zone the location's local days and hours are kept in -- the zone `daily` dates, sunrise and sunset are computed in.
    public var timezone: String
    /// County.
    public var county: String?
    /// Country.
    public var country: String?
    /// Aliases.
    public var aliases: [String]?
    /// Description short.
    public var descriptionShort: String?
    /// Description long.
    public var descriptionLong: String?
    /// Microclimate notes.
    public var microclimateNotes: String?
    /// Meta title.
    public var metaTitle: String?
    /// Meta description.
    public var metaDescription: String?
    /// Best seasons.
    public var bestSeasons: [String]?
    /// Key factors.
    public var keyFactors: [String]?
    /// Tags.
    public var tags: [String]?
    /// Free-form JSON of labelled links.
    public var externalLinks: JSONValue?
    /// Is featured.
    public var isFeatured: Bool?
    /// Elevations.
    public var elevations: [CatalogElevation]
    /// Photos.
    public var photos: [CatalogPhoto]
    /// Webcams.
    public var webcams: [CatalogWebcam]
    /// Nearby stations.
    public var nearbyStations: [CatalogNearbyStation]
    /// Template.
    public var template: CatalogTemplateSummary?
    /// Content.
    public var content: [CatalogResolvedEntry]?
    /// Ads.
    public var ads: [CatalogResolvedAdSlot]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String, state: String, name: String, latitude: Double, longitude: Double,
        elevationMeters: Double, type: LocationType, timezone: String, county: String? = nil,
        country: String? = nil, aliases: [String]? = nil, descriptionShort: String? = nil,
        descriptionLong: String? = nil, microclimateNotes: String? = nil, metaTitle: String? = nil,
        metaDescription: String? = nil, bestSeasons: [String]? = nil, keyFactors: [String]? = nil,
        tags: [String]? = nil, externalLinks: JSONValue? = nil, isFeatured: Bool? = nil,
        elevations: [CatalogElevation], photos: [CatalogPhoto], webcams: [CatalogWebcam],
        nearbyStations: [CatalogNearbyStation], template: CatalogTemplateSummary? = nil,
        content: [CatalogResolvedEntry]? = nil, ads: [CatalogResolvedAdSlot]? = nil
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
        self.country = country
        self.aliases = aliases
        self.descriptionShort = descriptionShort
        self.descriptionLong = descriptionLong
        self.microclimateNotes = microclimateNotes
        self.metaTitle = metaTitle
        self.metaDescription = metaDescription
        self.bestSeasons = bestSeasons
        self.keyFactors = keyFactors
        self.tags = tags
        self.externalLinks = externalLinks
        self.isFeatured = isFeatured
        self.elevations = elevations
        self.photos = photos
        self.webcams = webcams
        self.nearbyStations = nearbyStations
        self.template = template
        self.content = content
        self.ads = ads
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
        case country
        case aliases
        case descriptionShort = "description_short"
        case descriptionLong = "description_long"
        case microclimateNotes = "microclimate_notes"
        case metaTitle = "meta_title"
        case metaDescription = "meta_description"
        case bestSeasons = "best_seasons"
        case keyFactors = "key_factors"
        case tags
        case externalLinks = "external_links"
        case isFeatured = "is_featured"
        case elevations
        case photos
        case webcams
        case nearbyStations = "nearby_stations"
        case template
        case content
        case ads
    }
}

/// One page of catalog stations; follow ``nextCursor`` for the next.
public struct CatalogStationPage: Sendable, Hashable, Codable {
    /// Items.
    public var items: [CatalogStation]
    /// Next cursor.
    public var nextCursor: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(items: [CatalogStation], nextCursor: String? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
    }
}

/// A catalog station's PUBLIC projection -- the [`LocationRef`] fields (`type` is `observation_station`) plus the station's public facts, by an allowlist.
public struct CatalogStation: Sendable, Hashable, Codable {
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
    /// The primary location type, snake_case (D-5).
    public var type: LocationType
    /// The IANA zone the location's local days and hours are kept in -- the zone `daily` dates, sunrise and sunset are computed in.
    public var timezone: String
    /// County.
    public var county: String?
    /// Country.
    public var country: String?
    /// Aliases.
    public var aliases: [String]?
    /// Network.
    public var network: String?
    /// Source station id.
    public var sourceStationID: String?
    /// Elevation msl m.
    public var elevationMSLMeters: Double?
    /// Sensor height agl m.
    public var sensorHeightAGLMeters: Double?
    /// Sensor capabilities.
    public var sensorCapabilities: [String]?
    /// Station status.
    public var stationStatus: String?
    /// Last report at.
    public var lastReportAt: Date?
    /// Free-form JSON of the last report.
    public var lastReportSummary: JSONValue?
    /// Install date.
    public var installDate: String?
    /// Decommission date.
    public var decommissionDate: String?
    /// Update frequency minutes.
    public var updateFrequencyMinutes: Int?
    /// Station url.
    public var stationURL: String?
    /// Data url.
    public var dataURL: String?
    /// Description short.
    public var descriptionShort: String?
    /// Description long.
    public var descriptionLong: String?
    /// Meta title.
    public var metaTitle: String?
    /// Meta description.
    public var metaDescription: String?
    /// Tags.
    public var tags: [String]?
    /// Is featured.
    public var isFeatured: Bool?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String, state: String, name: String, latitude: Double, longitude: Double,
        elevationMeters: Double, type: LocationType, timezone: String, county: String? = nil,
        country: String? = nil, aliases: [String]? = nil, network: String? = nil,
        sourceStationID: String? = nil, elevationMSLMeters: Double? = nil,
        sensorHeightAGLMeters: Double? = nil, sensorCapabilities: [String]? = nil,
        stationStatus: String? = nil, lastReportAt: Date? = nil,
        lastReportSummary: JSONValue? = nil, installDate: String? = nil,
        decommissionDate: String? = nil, updateFrequencyMinutes: Int? = nil,
        stationURL: String? = nil, dataURL: String? = nil, descriptionShort: String? = nil,
        descriptionLong: String? = nil, metaTitle: String? = nil, metaDescription: String? = nil,
        tags: [String]? = nil, isFeatured: Bool? = nil
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
        self.country = country
        self.aliases = aliases
        self.network = network
        self.sourceStationID = sourceStationID
        self.elevationMSLMeters = elevationMSLMeters
        self.sensorHeightAGLMeters = sensorHeightAGLMeters
        self.sensorCapabilities = sensorCapabilities
        self.stationStatus = stationStatus
        self.lastReportAt = lastReportAt
        self.lastReportSummary = lastReportSummary
        self.installDate = installDate
        self.decommissionDate = decommissionDate
        self.updateFrequencyMinutes = updateFrequencyMinutes
        self.stationURL = stationURL
        self.dataURL = dataURL
        self.descriptionShort = descriptionShort
        self.descriptionLong = descriptionLong
        self.metaTitle = metaTitle
        self.metaDescription = metaDescription
        self.tags = tags
        self.isFeatured = isFeatured
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
        case country
        case aliases
        case network
        case sourceStationID = "source_station_id"
        case elevationMSLMeters = "elevation_msl_m"
        case sensorHeightAGLMeters = "sensor_height_agl_m"
        case sensorCapabilities = "sensor_capabilities"
        case stationStatus = "station_status"
        case lastReportAt = "last_report_at"
        case lastReportSummary = "last_report_summary"
        case installDate = "install_date"
        case decommissionDate = "decommission_date"
        case updateFrequencyMinutes = "update_frequency_minutes"
        case stationURL = "station_url"
        case dataURL = "data_url"
        case descriptionShort = "description_short"
        case descriptionLong = "description_long"
        case metaTitle = "meta_title"
        case metaDescription = "meta_description"
        case tags
        case isFeatured = "is_featured"
    }
}

/// A catalog station with its photos, webcams, primary location and optional content.
public struct CatalogStationDetail: Sendable, Hashable, Codable {
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
    /// The primary location type, snake_case (D-5).
    public var type: LocationType
    /// The IANA zone the location's local days and hours are kept in -- the zone `daily` dates, sunrise and sunset are computed in.
    public var timezone: String
    /// County.
    public var county: String?
    /// Country.
    public var country: String?
    /// Aliases.
    public var aliases: [String]?
    /// Network.
    public var network: String?
    /// Source station id.
    public var sourceStationID: String?
    /// Elevation msl m.
    public var elevationMSLMeters: Double?
    /// Sensor height agl m.
    public var sensorHeightAGLMeters: Double?
    /// Sensor capabilities.
    public var sensorCapabilities: [String]?
    /// Station status.
    public var stationStatus: String?
    /// Last report at.
    public var lastReportAt: Date?
    /// Free-form JSON of the last report.
    public var lastReportSummary: JSONValue?
    /// Install date.
    public var installDate: String?
    /// Decommission date.
    public var decommissionDate: String?
    /// Update frequency minutes.
    public var updateFrequencyMinutes: Int?
    /// Station url.
    public var stationURL: String?
    /// Data url.
    public var dataURL: String?
    /// Description short.
    public var descriptionShort: String?
    /// Description long.
    public var descriptionLong: String?
    /// Meta title.
    public var metaTitle: String?
    /// Meta description.
    public var metaDescription: String?
    /// Tags.
    public var tags: [String]?
    /// Is featured.
    public var isFeatured: Bool?
    /// Photos.
    public var photos: [CatalogPhoto]
    /// Webcams.
    public var webcams: [CatalogWebcam]
    /// Primary location.
    public var primaryLocation: CatalogPrimaryLocation?
    /// Template.
    public var template: CatalogTemplateSummary?
    /// Content.
    public var content: [CatalogResolvedEntry]?
    /// Ads.
    public var ads: [CatalogResolvedAdSlot]?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String, state: String, name: String, latitude: Double, longitude: Double,
        elevationMeters: Double, type: LocationType, timezone: String, county: String? = nil,
        country: String? = nil, aliases: [String]? = nil, network: String? = nil,
        sourceStationID: String? = nil, elevationMSLMeters: Double? = nil,
        sensorHeightAGLMeters: Double? = nil, sensorCapabilities: [String]? = nil,
        stationStatus: String? = nil, lastReportAt: Date? = nil,
        lastReportSummary: JSONValue? = nil, installDate: String? = nil,
        decommissionDate: String? = nil, updateFrequencyMinutes: Int? = nil,
        stationURL: String? = nil, dataURL: String? = nil, descriptionShort: String? = nil,
        descriptionLong: String? = nil, metaTitle: String? = nil, metaDescription: String? = nil,
        tags: [String]? = nil, isFeatured: Bool? = nil, photos: [CatalogPhoto],
        webcams: [CatalogWebcam], primaryLocation: CatalogPrimaryLocation? = nil,
        template: CatalogTemplateSummary? = nil, content: [CatalogResolvedEntry]? = nil,
        ads: [CatalogResolvedAdSlot]? = nil
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
        self.country = country
        self.aliases = aliases
        self.network = network
        self.sourceStationID = sourceStationID
        self.elevationMSLMeters = elevationMSLMeters
        self.sensorHeightAGLMeters = sensorHeightAGLMeters
        self.sensorCapabilities = sensorCapabilities
        self.stationStatus = stationStatus
        self.lastReportAt = lastReportAt
        self.lastReportSummary = lastReportSummary
        self.installDate = installDate
        self.decommissionDate = decommissionDate
        self.updateFrequencyMinutes = updateFrequencyMinutes
        self.stationURL = stationURL
        self.dataURL = dataURL
        self.descriptionShort = descriptionShort
        self.descriptionLong = descriptionLong
        self.metaTitle = metaTitle
        self.metaDescription = metaDescription
        self.tags = tags
        self.isFeatured = isFeatured
        self.photos = photos
        self.webcams = webcams
        self.primaryLocation = primaryLocation
        self.template = template
        self.content = content
        self.ads = ads
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
        case country
        case aliases
        case network
        case sourceStationID = "source_station_id"
        case elevationMSLMeters = "elevation_msl_m"
        case sensorHeightAGLMeters = "sensor_height_agl_m"
        case sensorCapabilities = "sensor_capabilities"
        case stationStatus = "station_status"
        case lastReportAt = "last_report_at"
        case lastReportSummary = "last_report_summary"
        case installDate = "install_date"
        case decommissionDate = "decommission_date"
        case updateFrequencyMinutes = "update_frequency_minutes"
        case stationURL = "station_url"
        case dataURL = "data_url"
        case descriptionShort = "description_short"
        case descriptionLong = "description_long"
        case metaTitle = "meta_title"
        case metaDescription = "meta_description"
        case tags
        case isFeatured = "is_featured"
        case photos
        case webcams
        case primaryLocation = "primary_location"
        case template
        case content
        case ads
    }
}

/// A station's parent location, by reference.
public struct CatalogPrimaryLocation: Sendable, Hashable, Codable {
    /// Slug.
    public var slug: String
    /// Name.
    public var name: String
    /// Lat.
    public var latitude: Double
    /// Lon.
    public var longitude: Double
    /// Elevation m.
    public var elevationMeters: Double
    /// Type.
    public var type: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String, name: String, latitude: Double, longitude: Double, elevationMeters: Double,
        type: String
    ) {
        self.slug = slug
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevationMeters = elevationMeters
        self.type = type
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case name
        case latitude = "lat"
        case longitude = "lon"
        case elevationMeters = "elevation_m"
        case type
    }
}

/// A named elevation of a catalog location (base, mid-mountain, summit).
public struct CatalogElevation: Sendable, Hashable, Codable {
    /// Label.
    public var label: String
    /// Elevation m.
    public var elevationMeters: Double
    /// Lat override.
    public var latitudeOverride: Double?
    /// Lon override.
    public var longitudeOverride: Double?
    /// Whether this is the default elevation to show in the UI.
    public var isDefault: Bool

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        label: String, elevationMeters: Double, latitudeOverride: Double? = nil,
        longitudeOverride: Double? = nil, isDefault: Bool
    ) {
        self.label = label
        self.elevationMeters = elevationMeters
        self.latitudeOverride = latitudeOverride
        self.longitudeOverride = longitudeOverride
        self.isDefault = isDefault
    }

    enum CodingKeys: String, CodingKey {
        case label
        case elevationMeters = "elevation_m"
        case latitudeOverride = "lat_override"
        case longitudeOverride = "lon_override"
        case isDefault = "is_default"
    }
}

/// Photo with the storage backend already resolved to a single public `url` (GCS object or external link).
public struct CatalogPhoto: Sendable, Hashable, Codable {
    /// Url.
    public var url: URL
    /// Caption.
    public var caption: String?
    /// Credit.
    public var credit: String?
    /// Alt text.
    public var altText: String?
    /// License.
    public var license: String?
    /// License url.
    public var licenseURL: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        url: URL, caption: String? = nil, credit: String? = nil, altText: String? = nil,
        license: String? = nil, licenseURL: String? = nil
    ) {
        self.url = url
        self.caption = caption
        self.credit = credit
        self.altText = altText
        self.license = license
        self.licenseURL = licenseURL
    }

    enum CodingKeys: String, CodingKey {
        case url
        case caption
        case credit
        case altText = "alt_text"
        case license
        case licenseURL = "license_url"
    }
}

/// A webcam at a catalog location or station.
public struct CatalogWebcam: Sendable, Hashable, Codable {
    /// Name.
    public var name: String
    /// Url.
    public var url: URL
    /// Embed type.
    public var embedType: String?
    /// Provider.
    public var provider: String?
    /// Refresh interval seconds.
    public var refreshIntervalSeconds: Int?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        name: String, url: URL, embedType: String? = nil, provider: String? = nil,
        refreshIntervalSeconds: Int? = nil
    ) {
        self.name = name
        self.url = url
        self.embedType = embedType
        self.provider = provider
        self.refreshIntervalSeconds = refreshIntervalSeconds
    }

    enum CodingKeys: String, CodingKey {
        case name
        case url
        case embedType = "embed_type"
        case provider
        case refreshIntervalSeconds = "refresh_interval_seconds"
    }
}

/// Inlined summary of a station near a catalog location — enough to render a list; full detail requires a follow-up GET against `/api/v1/catalog/stations/{slug}`.
public struct CatalogNearbyStation: Sendable, Hashable, Codable {
    /// Slug.
    public var slug: String
    /// Name.
    public var name: String
    /// Network.
    public var network: String
    /// Station status.
    public var stationStatus: String
    /// Distance km.
    public var distanceKilometers: Double?
    /// Elevation diff m.
    public var elevationDifferenceMeters: Double?
    /// Is primary.
    public var isPrimary: Bool

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slug: String, name: String, network: String, stationStatus: String,
        distanceKilometers: Double? = nil, elevationDifferenceMeters: Double? = nil, isPrimary: Bool
    ) {
        self.slug = slug
        self.name = name
        self.network = network
        self.stationStatus = stationStatus
        self.distanceKilometers = distanceKilometers
        self.elevationDifferenceMeters = elevationDifferenceMeters
        self.isPrimary = isPrimary
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case name
        case network
        case stationStatus = "station_status"
        case distanceKilometers = "distance_km"
        case elevationDifferenceMeters = "elevation_diff_m"
        case isPrimary = "is_primary"
    }
}

/// One element of a page template's `spec`.
public struct CatalogTemplateSection: Sendable, Hashable, Codable {
    /// Closed vocabulary — unknown kinds fail deserialization (`400`).
    public var kind: CatalogTemplateSectionKind
    /// Kebab-case section key.
    public var key: String
    /// Client-defined render hints (`hours`, `by_elevation_band`, media `source`/`limit`, …) — not backend contract.
    public var config: JSONValue?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(kind: CatalogTemplateSectionKind, key: String, config: JSONValue? = nil) {
        self.kind = kind
        self.key = key
        self.config = config
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case key
        case config
    }
}

/// Closed key set — unknown keys are a `400`.
public struct CatalogAdCreative: Sendable, Hashable, Codable {
    /// Headline.
    public var headline: String?
    /// Body.
    public var body: String?
    /// Call-to-action label.
    public var callToAction: String?
    /// Must be http(s).
    public var clickURL: URL?
    /// Must reference an existing photo row.
    public var photoID: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        headline: String? = nil, body: String? = nil, callToAction: String? = nil,
        clickURL: URL? = nil, photoID: String? = nil
    ) {
        self.headline = headline
        self.body = body
        self.callToAction = callToAction
        self.clickURL = clickURL
        self.photoID = photoID
    }

    enum CodingKeys: String, CodingKey {
        case headline
        case body
        case callToAction = "cta"
        case clickURL = "click_url"
        case photoID = "photo_id"
    }
}

/// The resolved page template as the public API serves it — identity + scope + spec; editorial audit fields stay internal.
public struct CatalogTemplateSummary: Sendable, Hashable, Codable {
    /// Id.
    public var id: String
    /// Null = wildcard scope.
    public var locationType: String?
    /// Null = wildcard scope.
    public var templateVariant: String?
    /// Spec.
    public var spec: [CatalogTemplateSection]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, locationType: String? = nil, templateVariant: String? = nil,
        spec: [CatalogTemplateSection]
    ) {
        self.id = id
        self.locationType = locationType
        self.templateVariant = templateVariant
        self.spec = spec
    }

    enum CodingKeys: String, CodingKey {
        case id
        case locationType = "location_type"
        case templateVariant = "template_variant"
        case spec
    }
}

/// One published content entry as the public catalog detail serves it: entry fields + the attachment's slot/order + which locale the read path actually resolved.
public struct CatalogResolvedEntry: Sendable, Hashable, Codable {
    /// Id.
    public var id: String
    /// Content type key.
    public var contentTypeKey: String
    /// Title.
    public var title: String
    /// Shaped by the content type's `field_schema`.
    public var body: JSONValue
    /// The template `content_slot` key this entry fills.
    public var slot: String
    /// Display order.
    public var displayOrder: Int
    /// The requested locale if ANY field of this entry carried a translation, else the entry's base locale.
    public var resolvedLocale: String
    /// Updated at.
    public var updatedAt: Date

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, contentTypeKey: String, title: String, body: JSONValue, slot: String,
        displayOrder: Int, resolvedLocale: String, updatedAt: Date
    ) {
        self.id = id
        self.contentTypeKey = contentTypeKey
        self.title = title
        self.body = body
        self.slot = slot
        self.displayOrder = displayOrder
        self.resolvedLocale = resolvedLocale
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case contentTypeKey = "content_type_key"
        case title
        case body
        case slot
        case displayOrder = "display_order"
        case resolvedLocale = "resolved_locale"
        case updatedAt = "updated_at"
    }
}

/// A resolved house placement (campaign + creative content).
public struct CatalogHousePlacement: Sendable, Hashable, Codable {
    /// Campaign id.
    public var campaignID: String
    /// Creative id.
    public var creativeID: String
    /// Content.
    public var content: CatalogAdCreative

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(campaignID: String, creativeID: String, content: CatalogAdCreative) {
        self.campaignID = campaignID
        self.creativeID = creativeID
        self.content = content
    }

    enum CodingKeys: String, CodingKey {
        case campaignID = "campaign_id"
        case creativeID = "creative_id"
        case content
    }
}

/// A resolved third-party placement (network config served verbatim).
public struct CatalogThirdPartyPlacement: Sendable, Hashable, Codable {
    /// Unit id.
    public var unitID: String
    /// Provider.
    public var provider: CatalogAdProvider
    /// Config.
    public var config: JSONValue

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(unitID: String, provider: CatalogAdProvider, config: JSONValue) {
        self.unitID = unitID
        self.provider = provider
        self.config = config
    }

    enum CodingKeys: String, CodingKey {
        case unitID = "unit_id"
        case provider
        case config
    }
}

/// One filled ad slot as the public API serves it.
public struct CatalogResolvedAdSlot: Sendable, Hashable, Codable {
    /// Slot key.
    public var slotKey: String
    /// Kind.
    public var kind: CatalogAdSlotKind
    /// Present iff `kind = house`.
    public var house: CatalogHousePlacement?
    /// Present iff `kind = third_party`.
    public var thirdParty: CatalogThirdPartyPlacement?
    /// The slot's client rendering hints (`default_sizes`).
    public var sizes: [[Int]]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        slotKey: String, kind: CatalogAdSlotKind, house: CatalogHousePlacement? = nil,
        thirdParty: CatalogThirdPartyPlacement? = nil, sizes: [[Int]]
    ) {
        self.slotKey = slotKey
        self.kind = kind
        self.house = house
        self.thirdParty = thirdParty
        self.sizes = sizes
    }

    enum CodingKeys: String, CodingKey {
        case slotKey = "slot_key"
        case kind
        case house
        case thirdParty = "third_party"
        case sizes
    }
}
