// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// A client for the Ourea probabilistic weather API (v1).
///
/// ```swift
/// let client = EnsembleWeatherClient()   // anonymous, or OUREA_API_KEY
/// let forecast = try await client.forecast(for: "or/mt-hood-meadows")
/// ```
///
/// The client is `Sendable`: share one instance across tasks. Every call is
/// a `GET` sent at its canonical URL; connection errors, 429, 502, 503 and
/// 504 are retried; responses are revalidated through a local `ETag` cache.
/// Calls throw ``EnsembleWeatherError`` (or `CancellationError`).
///
/// Search, catalog detail and attribution are open routes: they are sent
/// without the API key, even when the client has one, so callers share the
/// edge cache. Set ``Configuration/sendsKeyOnOpenRoutes`` to send it anyway.
public final class EnsembleWeatherClient: Sendable {
    /// The client's configuration.
    public let configuration: Configuration
    private let executor: RequestExecutor

    /// Creates a client.
    ///
    /// - Parameter apiKey: The API key; when `nil`, `OUREA_API_KEY` from the
    ///   environment if set, else anonymous (Free tier).
    public convenience init(apiKey: String? = nil) {
        self.init(configuration: Configuration(apiKey: apiKey))
    }

    /// Creates a client with a full configuration.
    public init(configuration: Configuration) {
        self.configuration = configuration
        executor = RequestExecutor(configuration: configuration, lastRateLimit: Locked(nil))
    }

    /// The rate-limit state of the most recent response that reported one.
    public var rateLimit: RateLimit? { executor.lastRateLimit.withLock { $0 } }

    // MARK: - Forecasts

    /// The forecast for a named location (`getLocationForecast`).
    ///
    /// Works anonymously.
    ///
    /// - Parameters:
    ///   - location: The location, such as `"or/mt-hood-meadows"`.
    ///   - options: What to include, including probability terms and window totals.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func forecast(for location: LocationID, options: ForecastOptions = ForecastOptions())
        async throws -> APIResponse<ForecastResponse>
    {
        var endpoint = Endpoint(
            operation: "getLocationForecast",
            path: ["api", "v1", "locations"] + (try location.pathSegments()))
        return try await forecast(endpoint: &endpoint, options: options)
    }

    /// The forecast at a point (`getPointForecast`).
    ///
    /// Needs a Pro key.
    ///
    /// - Parameters:
    ///   - latitude: Degrees north, sent exactly as given.
    ///   - longitude: Degrees east, sent exactly as given.
    ///   - elevationMeters: The elevation to forecast at; `nil` uses the terrain.
    ///   - options: What to include.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func forecast(
        latitude: Double, longitude: Double, elevationMeters: Double? = nil,
        options: ForecastOptions = ForecastOptions()
    ) async throws -> APIResponse<ForecastResponse> {
        var endpoint = Endpoint(operation: "getPointForecast", path: ["api", "v1", "forecast"])
        try endpoint.query.addCoordinates(latitude, longitude)
        endpoint.query.add("elevation_m", elevationMeters)
        return try await forecast(endpoint: &endpoint, options: options)
    }

    private func forecast(endpoint: inout Endpoint, options: ForecastOptions) async throws
        -> APIResponse<ForecastResponse>
    {
        let units = options.units ?? configuration.units
        let (terms, totals) = try options.apply(to: &endpoint.query, units: units)
        var response = try await get(ForecastResponse.self, endpoint)
        response.value.probabilities = Self.inCallerOrder(
            response.value.probabilities, terms: terms, units: response.value.units)
        response.value.windowTotals = Self.inCallerOrder(
            response.value.windowTotals, totals: totals)
        return response
    }

    /// Maps the server's answers (in canonical order) back to the caller's terms.
    ///
    /// A term the response does not answer is left out (it is absent, never
    /// a substituted value); ``ForecastResponse/probability(for:)`` returns
    /// `nil` for it.
    static func inCallerOrder(
        _ results: [ProbabilityResult], terms: [ResolvedProbabilityTerm], units: UnitSystem
    ) -> [ProbabilityResult] {
        guard !terms.isEmpty else { return results }
        var byKey: [ResolvedProbabilityTerm: ProbabilityResult] = [:]
        for result in results {
            if let key = ResolvedProbabilityTerm(result, units: units) { byKey[key] = result }
        }
        return terms.compactMap { byKey[$0] }
    }

    static func inCallerOrder(_ results: [WindowTotal], totals: [ResolvedWindowTotal])
        -> [WindowTotal]
    {
        guard !totals.isEmpty else { return results }
        var byKey: [ResolvedWindowTotal: WindowTotal] = [:]
        for result in results { byKey[ResolvedWindowTotal(result)] = result }
        return totals.compactMap { byKey[$0] }
    }

    // MARK: - Current conditions and alerts

    /// Current conditions at a named location (`getCurrentConditions`).
    ///
    /// - Parameters:
    ///   - location: The location.
    ///   - units: The unit system; `nil` uses the client's.
    ///   - sources: An allowlist of observation sources.
    ///   - excludedSources: A denylist of observation sources.
    ///   - includesNowcastHours: Adds the obs-blended `nowcastHours` band.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func currentConditions(
        for location: LocationID, units: UnitSystem? = nil, sources: [String]? = nil,
        excludedSources: [String]? = nil, includesNowcastHours: Bool = false
    ) async throws -> APIResponse<CurrentConditionsResponse> {
        var endpoint = Endpoint(
            operation: "getCurrentConditions",
            path: ["api", "v1", "locations"] + (try location.pathSegments()) + ["current"])
        addCurrentParameters(
            to: &endpoint.query, units: units, sources: sources, excludedSources: excludedSources,
            includesNowcastHours: includesNowcastHours)
        return try await get(CurrentConditionsResponse.self, endpoint)
    }

    /// Current conditions at a point (`getCurrentByCoordinates`).
    ///
    /// Needs a Pro key.
    public func currentConditions(
        latitude: Double, longitude: Double, elevationMeters: Double? = nil,
        units: UnitSystem? = nil,
        sources: [String]? = nil, excludedSources: [String]? = nil,
        includesNowcastHours: Bool = false
    ) async throws -> APIResponse<CurrentConditionsResponse> {
        var endpoint = Endpoint(
            operation: "getCurrentByCoordinates", path: ["api", "v1", "current"])
        try endpoint.query.addCoordinates(latitude, longitude)
        endpoint.query.add("elevation_m", elevationMeters)
        addCurrentParameters(
            to: &endpoint.query, units: units, sources: sources, excludedSources: excludedSources,
            includesNowcastHours: includesNowcastHours)
        return try await get(CurrentConditionsResponse.self, endpoint)
    }

    private func addCurrentParameters(
        to query: inout QueryString, units: UnitSystem?, sources: [String]?,
        excludedSources: [String]?,
        includesNowcastHours: Bool
    ) {
        query.add(
            "units", (units ?? configuration.units).rawValue, default: UnitSystem.metric.rawValue)
        query.addList("sources", sources)
        query.addList("exclude_sources", excludedSources)
        if includesNowcastHours { query.add("include", "nowcast_hours") }
    }

    /// The active alerts for a named location (`getLocationAlerts`).
    public func alerts(for location: LocationID) async throws -> APIResponse<AlertsResponse> {
        let endpoint = Endpoint(
            operation: "getLocationAlerts",
            path: ["api", "v1", "locations"] + (try location.pathSegments()) + ["alerts"])
        return try await get(AlertsResponse.self, endpoint)
    }

    /// The active alerts at a point (`getAlertsByCoordinates`).
    ///
    /// Needs a Pro key.
    public func alerts(latitude: Double, longitude: Double) async throws -> APIResponse<
        AlertsResponse
    > {
        var endpoint = Endpoint(operation: "getAlertsByCoordinates", path: ["api", "v1", "alerts"])
        try endpoint.query.addCoordinates(latitude, longitude)
        return try await get(AlertsResponse.self, endpoint)
    }

    // MARK: - Locations

    /// The locations nearest a named location (`getNearbyLocations`).
    ///
    /// - Parameters:
    ///   - location: The location.
    ///   - limit: The most locations (1...20); default 3.
    ///   - radiusKilometers: The search radius (at most 100); default 50.
    ///   - units: The unit system; `nil` uses the client's.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func nearbyLocations(
        to location: LocationID, limit: Int = 3, radiusKilometers: Double = 50,
        units: UnitSystem? = nil
    ) async throws -> APIResponse<NearbyLocations> {
        var endpoint = Endpoint(
            operation: "getNearbyLocations",
            path: ["api", "v1", "locations"] + (try location.pathSegments()) + ["nearby"])
        addNearbyParameters(
            to: &endpoint.query, limit: limit, radius: radiusKilometers, units: units)
        return try await get(NearbyLocations.self, endpoint)
    }

    /// The locations nearest a point (`getNearbyByCoordinates`).
    public func nearbyLocations(
        latitude: Double, longitude: Double, limit: Int = 3, radiusKilometers: Double = 50,
        units: UnitSystem? = nil
    ) async throws -> APIResponse<NearbyPointLocations> {
        var endpoint = Endpoint(operation: "getNearbyByCoordinates", path: ["api", "v1", "nearby"])
        try endpoint.query.addCoordinates(latitude, longitude)
        addNearbyParameters(
            to: &endpoint.query, limit: limit, radius: radiusKilometers, units: units)
        return try await get(NearbyPointLocations.self, endpoint)
    }

    private func addNearbyParameters(
        to query: inout QueryString, limit: Int, radius: Double, units: UnitSystem?
    ) {
        query.add("limit", limit, default: 3)
        query.add("radius_km", radius, default: 50)
        query.add(
            "units", (units ?? configuration.units).rawValue, default: UnitSystem.metric.rawValue)
    }

    /// Searches locations by name (`searchLocations`).
    ///
    /// An open route: sent without the API key.
    ///
    /// - Parameters:
    ///   - query: The search text, such as `"hood meadows"`.
    ///   - state: Restricts to a state (code or name).
    ///   - county: Restricts to a county.
    ///   - type: Restricts to a location type.
    ///   - limit: The most hits (1...100); default 20.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func searchLocations(
        _ query: String, state: String? = nil, county: String? = nil, type: LocationType? = nil,
        limit: Int = 20
    ) async throws -> APIResponse<LocationSearchResults> {
        var endpoint = Endpoint(
            operation: "searchLocations", path: ["api", "v1", "search", "locations"],
            isOpenRoute: true)
        endpoint.query.add("q", query)
        endpoint.query.add("state", state)
        endpoint.query.add("county", county)
        endpoint.query.add("type", type?.rawValue)
        endpoint.query.add("limit", limit, default: 20)
        return try await get(LocationSearchResults.self, endpoint)
    }

    /// One page of forecast locations, nationwide (`getAllLocations`) or in
    /// one state (`getLocations`).
    ///
    /// - Parameters:
    ///   - state: A state code or name; `nil` lists every state.
    ///   - type: Restricts to a location type.
    ///   - units: The unit system; `nil` uses the client's.
    ///   - limit: The page size (1...5000).
    ///   - cursor: The previous page's ``LocationPage/nextCursor``.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func locationPage(
        state: String? = nil, type: LocationType? = nil, units: UnitSystem? = nil,
        limit: Int? = nil,
        cursor: String? = nil
    ) async throws -> APIResponse<LocationPage> {
        var endpoint: Endpoint
        if let state {
            let isCode = state.count == 2 && state.allSatisfy { $0.isASCII && $0.isLetter }
            endpoint = Endpoint(
                operation: "getLocations",
                path: ["api", "v1", "locations", isCode ? state.lowercased() : state])
        } else {
            endpoint = Endpoint(operation: "getAllLocations", path: ["api", "v1", "locations"])
        }
        endpoint.query.add("type", type?.rawValue)
        endpoint.query.add(
            "units", (units ?? configuration.units).rawValue, default: UnitSystem.metric.rawValue)
        endpoint.query.add("limit", limit)
        endpoint.query.add("cursor", cursor)
        return try await get(LocationPage.self, endpoint)
    }

    /// Every forecast location, nationwide or in one state, fetched page by page.
    public func locations(
        state: String? = nil, type: LocationType? = nil, units: UnitSystem? = nil,
        pageSize: Int? = nil
    ) -> PageSequence<LocationSummary> {
        PageSequence { cursor in
            let page = try await self.locationPage(
                state: state, type: type, units: units, limit: pageSize, cursor: cursor)
            return (page.locations, page.nextCursor)
        }
    }

    // MARK: - Catalog

    /// One page of catalog locations (`listCatalogLocations`).
    ///
    /// Sent with the key when the client has one: anonymous catalog walks
    /// are capped and slowed per address.
    ///
    /// - Parameters:
    ///   - country: An ISO country code, such as `US`.
    ///   - admin1: A first-level region, such as `US-OR`.
    ///   - type: Restricts to a location type.
    ///   - template: Restricts to a page template.
    ///   - limit: The page size (1...100); default 20.
    ///   - cursor: The previous page's ``CatalogLocationPage/nextCursor``.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func catalogLocationPage(
        country: String? = nil, admin1: String? = nil, type: LocationType? = nil,
        template: String? = nil,
        limit: Int = 20, cursor: String? = nil
    ) async throws -> APIResponse<CatalogLocationPage> {
        var endpoint = Endpoint(
            operation: "listCatalogLocations", path: ["api", "v1", "catalog", "locations"])
        endpoint.query.add("country", country)
        endpoint.query.add("admin1", admin1)
        endpoint.query.add("type", type?.rawValue)
        endpoint.query.add("template", template)
        endpoint.query.add("limit", limit, default: 20)
        endpoint.query.add("cursor", cursor)
        return try await get(CatalogLocationPage.self, endpoint)
    }

    /// Every catalog location, fetched page by page.
    public func catalogLocations(
        country: String? = nil, admin1: String? = nil, type: LocationType? = nil,
        template: String? = nil,
        pageSize: Int = 20
    ) -> PageSequence<CatalogLocation> {
        PageSequence { cursor in
            let page = try await self.catalogLocationPage(
                country: country, admin1: admin1, type: type, template: template, limit: pageSize,
                cursor: cursor)
            return (page.items, page.nextCursor)
        }
    }

    /// A catalog location in detail (`getCatalogLocation`).
    ///
    /// An open route: sent without the API key.
    ///
    /// - Parameters:
    ///   - slug: The location's slug.
    ///   - extras: Optional extras to include.
    ///   - locale: The content locale; default `en`.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func catalogLocation(slug: String, extras: Set<CatalogExtra> = [], locale: String = "en")
        async throws -> APIResponse<CatalogLocationDetail>
    {
        var endpoint = Endpoint(
            operation: "getCatalogLocation", path: ["api", "v1", "catalog", "locations", slug],
            isOpenRoute: true)
        endpoint.query.addList("include", extras.map(\.rawValue).sorted())
        endpoint.query.add("locale", locale, default: "en")
        return try await get(CatalogLocationDetail.self, endpoint)
    }

    /// One page of catalog stations (`listCatalogStations`).
    ///
    /// - Parameters:
    ///   - country: An ISO country code.
    ///   - admin1: A first-level region, such as `US-OR`.
    ///   - networks: Restricts to networks, such as `["Snotel"]`.
    ///   - capabilities: Requires every listed sensor capability.
    ///   - status: Restricts to a station status.
    ///   - limit: The page size (1...100); default 20.
    ///   - cursor: The previous page's ``CatalogStationPage/nextCursor``.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func catalogStationPage(
        country: String? = nil, admin1: String? = nil, networks: [String]? = nil,
        capabilities: [String]? = nil, status: String? = nil, limit: Int = 20, cursor: String? = nil
    ) async throws -> APIResponse<CatalogStationPage> {
        var endpoint = Endpoint(
            operation: "listCatalogStations", path: ["api", "v1", "catalog", "stations"])
        endpoint.query.add("country", country)
        endpoint.query.add("admin1", admin1)
        endpoint.query.addList("network", networks)
        endpoint.query.addRepeated("capability", capabilities)
        endpoint.query.add("status", status)
        endpoint.query.add("limit", limit, default: 20)
        endpoint.query.add("cursor", cursor)
        return try await get(CatalogStationPage.self, endpoint)
    }

    /// Every catalog station, fetched page by page.
    public func catalogStations(
        country: String? = nil, admin1: String? = nil, networks: [String]? = nil,
        capabilities: [String]? = nil, status: String? = nil, pageSize: Int = 20
    ) -> PageSequence<CatalogStation> {
        PageSequence { cursor in
            let page = try await self.catalogStationPage(
                country: country, admin1: admin1, networks: networks, capabilities: capabilities,
                status: status, limit: pageSize, cursor: cursor)
            return (page.items, page.nextCursor)
        }
    }

    /// A catalog station in detail (`getCatalogStation`).
    ///
    /// An open route: sent without the API key.
    public func catalogStation(slug: String, extras: Set<CatalogExtra> = [], locale: String = "en")
        async throws -> APIResponse<CatalogStationDetail>
    {
        var endpoint = Endpoint(
            operation: "getCatalogStation", path: ["api", "v1", "catalog", "stations", slug],
            isOpenRoute: true)
        endpoint.query.addList("include", extras.map(\.rawValue).sorted())
        endpoint.query.add("locale", locale, default: "en")
        return try await get(CatalogStationDetail.self, endpoint)
    }

    // MARK: - Runs, storm reports, attribution

    /// The model runs the API can serve (`getAvailableRuns`).
    ///
    /// - Parameter limit: The most runs (at most 100); default 10.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func availableRuns(limit: Int = 10) async throws -> APIResponse<AvailableRuns> {
        var endpoint = Endpoint(operation: "getAvailableRuns", path: ["api", "v1", "runs"])
        endpoint.query.add("limit", limit, default: 10)
        return try await get(AvailableRuns.self, endpoint)
    }

    /// Recent storm reports (`getStormReports`).
    ///
    /// - Parameter limit: The most reports (at most 100); default 20.
    /// - Returns: The decoded response with its metadata.
    /// - Throws: ``EnsembleWeatherError`` (or `CancellationError`).
    public func stormReports(limit: Int = 20) async throws -> APIResponse<StormReportList> {
        var endpoint = Endpoint(operation: "getStormReports", path: ["api", "v1", "storm-reports"])
        endpoint.query.add("limit", limit, default: 20)
        return try await get(StormReportList.self, endpoint)
    }

    /// One storm report (`getStormReport`).
    public func stormReport(id: Int64) async throws -> APIResponse<StormReport> {
        let endpoint = Endpoint(
            operation: "getStormReport", path: ["api", "v1", "storm-reports", String(id)])
        return try await get(StormReport.self, endpoint)
    }

    /// Every data provider and source with its credit, licence and notices (`getAttribution`).
    ///
    /// An open route: sent without the API key.
    public func attribution() async throws -> APIResponse<Attribution> {
        let endpoint = Endpoint(
            operation: "getAttribution", path: ["api", "v1", "attribution"], isOpenRoute: true)
        return try await get(Attribution.self, endpoint)
    }

    // MARK: - Plumbing

    private func get<Value: Decodable & Sendable>(_ type: Value.Type, _ endpoint: Endpoint)
        async throws
        -> APIResponse<Value>
    {
        let (body, metadata) = try await executor.send(endpoint)
        return APIResponse(
            value: try JSONCoding.decode(type, from: body, status: metadata.status),
            metadata: metadata)
    }
}

extension EnsembleWeatherClient: CustomStringConvertible {
    /// A summary that never includes the API key.
    public var description: String { "EnsembleWeatherClient(\(configuration))" }
}

extension QueryString {
    /// Adds `lat` and `lon`, sent exactly as given.
    mutating func addCoordinates(_ latitude: Double, _ longitude: Double)
        throws(EnsembleWeatherError)
    {
        guard latitude.isFinite, longitude.isFinite else {
            throw .usage("Latitude and longitude must be finite numbers.")
        }
        add("lat", latitude)
        add("lon", longitude)
    }
}
