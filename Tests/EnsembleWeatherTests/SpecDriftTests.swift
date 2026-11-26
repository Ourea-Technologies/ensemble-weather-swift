// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation
import Testing

@testable import EnsembleWeather

/// Spec drift (SDK-STANDARD "Tests"): every operation in the pinned OpenAPI
/// file is exposed, and the models round-trip every example in it.
@Suite("Spec drift")
struct SpecDriftTests {
    static let spec: JSONValue = {
        let url = specDirectory.appendingPathComponent("openapi/v1/openapi.yaml")
        guard let text = try? String(contentsOf: url, encoding: .utf8),
            let spec = try? MiniYAML.parse(text)
        else { return .null }
        return spec
    }()

    /// Operations out of the SDK's scope (BEHAVIOR 3).
    static let outOfScope: Set<String> = ["getMapsToken"]

    /// Each operation: an SDK call that makes it.
    ///
    /// The test checks the call reaches the operation's route.
    static let calls: [String: @Sendable (Client) async throws -> Void] = [
        "getLocationForecast": { _ = try await $0.forecast(for: "or/mt-hood-meadows") },
        "getPointForecast": {
            _ = try await $0.getPointForecast(latitude: 45.3, longitude: -121.7)
        },
        "getCurrentConditions": { _ = try await $0.currentConditions(for: "or/mt-hood-meadows") },
        "getCurrentByCoordinates": {
            _ = try await $0.getPointCurrent(latitude: 45.3, longitude: -121.7)
        },
        "getLocationAlerts": { _ = try await $0.alerts(for: "or/mt-hood-meadows") },
        "getAlertsByCoordinates": {
            _ = try await $0.getPointAlerts(latitude: 45.3, longitude: -121.7)
        },
        "getNearbyLocations": { _ = try await $0.nearbyLocations(to: "or/mt-hood-meadows") },
        "getNearbyByCoordinates": {
            _ = try await $0.getPointNearby(latitude: 45.3, longitude: -121.7)
        },
        "searchLocations": { _ = try await $0.searchLocations("hood") },
        "getAllLocations": { _ = try await $0.locationPage() },
        "getLocations": { _ = try await $0.locationPage(state: "or") },
        "listCatalogLocations": { _ = try await $0.catalogLocationPage() },
        "getCatalogLocation": { _ = try await $0.catalogLocation(slug: "mt-hood-meadows") },
        "listCatalogStations": { _ = try await $0.catalogStationPage() },
        "getCatalogStation": { _ = try await $0.catalogStation(slug: "mt-hood-test-site-snotel") },
        "getAvailableRuns": { _ = try await $0.availableRuns() },
        "getAttribution": { _ = try await $0.attribution() },
        "explore": { _ = try await $0.explorePage(.snow5Days) },
        "getComposition": { _ = try await $0.composition() },
        "getLocationSeason": { _ = try await $0.season(for: "or/mt-hood-meadows") },
        "getLocationSnowTrend": { _ = try await $0.snowTrend(for: "or/mt-hood-meadows") },
        "getLocationSnowpack": { _ = try await $0.snowpack(for: "or/mt-hood-meadows") },
        "getLocationSnowpackPlume": { _ = try await $0.snowpackPlume(for: "or/mt-hood-meadows") },
        "getAlertOutlines": { _ = try await $0.alertOutlines() },
        "getAvalancheZones": { _ = try await $0.avalancheZones() },
    ]

    /// Every `(operationId, route)` in the spec.
    static var operations: [(id: String, path: String)] {
        (spec["paths"]?.object ?? [:]).flatMap { path, item in
            (item.object ?? [:]).compactMap { method, operation in
                method == "get" ? operation["operationId"]?.string.map { ($0, path) } : nil
            }
        }.sorted { $0.id < $1.id }
    }

    @Test("The spec parses and has operations")
    func specLoads() {
        #expect(Self.operations.count >= 18)
    }

    @Test("Every operation in the spec is exposed and reaches its route")
    func everyOperationExposed() async throws {
        for operation in Self.operations where !Self.outOfScope.contains(operation.id) {
            guard let call = Self.calls[operation.id] else {
                Issue.record("the spec has an operation the SDK does not expose: \(operation.id)")
                continue
            }
            let transport = MockTransport([HTTPResponse(status: 418)])
            let client = Client(
                configuration: testConfiguration(transport: transport))
            _ = try? await call(client)
            let sent = transport.requests.first.flatMap {
                URLComponents(url: $0.url, resolvingAgainstBaseURL: false)?.percentEncodedPath
            }
            let pattern =
                "^"
                + operation.path.split(separator: "/", omittingEmptySubsequences: false)
                .map {
                    $0.hasPrefix("{")
                        ? "[^/]+" : NSRegularExpression.escapedPattern(for: String($0))
                }
                .joined(separator: "/") + "$"
            #expect(
                sent?.range(of: pattern, options: .regularExpression) != nil,
                "\(operation.id) sent \(sent ?? "nothing"), expected \(operation.path)")
        }
    }

    /// Response examples the spec itself gets wrong; reported upstream.
    static let knownBadExamples: [String: String] = [:]

    @Test("The models round-trip every response example")
    func responseExamples() throws {
        var checked = 0
        for (path, item) in Self.spec["paths"]?.object ?? [:] {
            guard let operation = item["get"], let id = operation["operationId"]?.string,
                !Self.outOfScope.contains(id)
            else { continue }
            for (status, response) in operation["responses"]?.object ?? [:] {
                guard
                    let content = response["content"]?["application/json"]
                        ?? response["content"]?["application/geo+json"]
                else { continue }
                var examples: [(String, JSONValue)] = []
                for (name, example) in content["examples"]?.object ?? [:] {
                    if let value = example["value"] { examples.append((name, value)) }
                }
                if let example = content["example"] { examples.append(("example", example)) }
                for (name, example) in examples {
                    let label = "\(id) \(status) \(name)"
                    checked += 1
                    if let reason = Self.knownBadExamples[label] {
                        withKnownIssue("spec example does not match its schema: \(reason)") {
                            try Self.roundTrip(
                                example, as: Self.modelType(id, status: status), label: label)
                        }
                    } else {
                        try Self.roundTrip(
                            example, as: Self.modelType(id, status: status),
                            label: "\(label) (\(path))")
                    }
                }
            }
        }
        #expect(checked >= 9, "examples checked")
    }

    @Test("The models round-trip every object schema example")
    func schemaExamples() throws {
        let types: [String: any Codable.Type] = [
            "Sector": Sector.self, "CircularStats": CircularStats.self,
            "MembersCumulative": MembersCumulative.self, "MembersSpread": MembersSpread.self,
            "PrecipitationByType": PrecipitationByType.self,
            "ForecastLocation": ForecastLocation.self,
        ]
        for (name, schema) in Self.spec["components"]?["schemas"]?.object ?? [:] {
            guard let example = schema["example"], example.object != nil else { continue }
            guard let type = types[name] else {
                Issue.record("schema \(name) has an object example but no round-trip mapping")
                continue
            }
            try Self.roundTrip(example, as: type, label: name)
        }
    }

    /// Each object schema's Swift model, by its `CodingKeys`.
    static let codingKeys: [String: any CodingKey.Type] = [
        "ActiveAlert": ActiveAlert.CodingKeys.self,
        "AlertOutlineCollection": AlertOutlineCollection.CodingKeys.self,
        "AlertOutlineFeature": AlertOutlineFeature.CodingKeys.self,
        "AlertOutlineGeometry": GeoJSONGeometry.CodingKeys.self,
        "AlertsResponse": AlertsResponse.CodingKeys.self,
        "AppliedOptions": AppliedOptions.CodingKeys.self,
        "AttributionProvider": AttributionProvider.CodingKeys.self,
        "AttributionRegistry": Attribution.CodingKeys.self,
        "AttributionSource": AttributionSource.CodingKeys.self,
        "AvalancheForecast": AvalancheForecast.CodingKeys.self,
        "AvalancheZoneCollection": AvalancheZoneCollection.CodingKeys.self,
        "AvalancheZoneFeature": AvalancheZoneFeature.CodingKeys.self,
        "AvalancheZoneGeometry": GeoJSONGeometry.CodingKeys.self,
        "BandColumns": BandColumns.CodingKeys.self,
        "CatalogResolvedEntry": CatalogResolvedEntry.CodingKeys.self,
        "CatalogTemplateSummary": CatalogTemplateSummary.CodingKeys.self,
        "CircularStats": CircularStats.CodingKeys.self,
        "CmsTemplateSection": CatalogTemplateSection.CodingKeys.self,
        "CompositionResponse": CompositionResponse.CodingKeys.self,
        "CurrentConditions": CurrentConditions.CodingKeys.self,
        "CurrentResponse": CurrentConditionsResponse.CodingKeys.self,
        "DailyAstro": DailyAstro.CodingKeys.self,
        "DailyForecast": DailyForecast.CodingKeys.self,
        "DailyWind": DailyWind.CodingKeys.self,
        "DayClimatology": DayClimatology.CodingKeys.self,
        "DayDeparture": DayDeparture.CodingKeys.self,
        "DayNormal": DayNormal.CodingKeys.self,
        "DayPercentile": DayPercentile.CodingKeys.self,
        "ElevationForecast": ElevationForecast.CodingKeys.self,
        "ElevationSummary": ElevationSummary.CodingKeys.self,
        "EnsembleStats": EnsembleStats.CodingKeys.self,
        "ErrorResponse": ErrorBody.CodingKeys.self,
        "ExploreItem": ExploreItem.CodingKeys.self,
        "ExploreResponse": ExploreResponse.CodingKeys.self,
        "ExploreValue": ExploreValue.CodingKeys.self,
        "ForecastData": ForecastData.CodingKeys.self,
        "ForecastLocation": ForecastLocation.CodingKeys.self,
        "ForecastResponse": ForecastResponse.CodingKeys.self,
        "FreezingLevelAboveProfile": FreezingLevel.CodingKeys.self,
        "FreezingLevelBelowSurface": FreezingLevel.CodingKeys.self,
        "FreezingLevelHeight": FreezingLevel.CodingKeys.self,
        "GapFlow": GapFlow.CodingKeys.self,
        "HourProvenance": HourProvenance.CodingKeys.self,
        "InversionInfo": InversionInfo.CodingKeys.self,
        "LocationRef": LocationReference.CodingKeys.self,
        "LocationSummary": LocationSummary.CodingKeys.self,
        "LocationsResponse": LocationPage.CodingKeys.self,
        "MemberForecast": MemberForecast.CodingKeys.self,
        "MemberPlume": MemberPlume.CodingKeys.self,
        "MemberQuantiles": MemberQuantiles.CodingKeys.self,
        "MembersCumulative": MembersCumulative.CodingKeys.self,
        "MembersSpread": MembersSpread.CodingKeys.self,
        "ModelColumns": ModelColumns.CodingKeys.self,
        "ModelEntry": ModelEntry.CodingKeys.self,
        "ModelRunInfo": ModelRun.CodingKeys.self,
        "ModelStats": ModelMean.CodingKeys.self,
        "NearbyLocation": NearbyLocation.CodingKeys.self,
        "NearbyLocationsResponse": NearbyLocations.CodingKeys.self,
        "NearbyPointResponse": NearbyPointLocations.CodingKeys.self,
        "NearestLocation": NearestLocation.CodingKeys.self,
        "NearestSensor": NearestSensor.CodingKeys.self,
        "PassCamera": PassCamera.CodingKeys.self,
        "PassChance": PassChance.CodingKeys.self,
        "PassChances": PassChances.CodingKeys.self,
        "PassForecast": PassForecast.CodingKeys.self,
        "PassHour": PassHour.CodingKeys.self,
        "PassOfficialStatus": PassOfficialStatus.CodingKeys.self,
        "PassRoadSensor": PassRoadSensor.CodingKeys.self,
        "PassSnow24h": PassSnow24h.CodingKeys.self,
        "PassSnowWindow": PassSnowWindow.CodingKeys.self,
        "PassStatusSegment": PassStatusSegment.CodingKeys.self,
        "PassTravelWindow": PassTravelWindow.CodingKeys.self,
        "PassTravelWindows": PassTravelWindows.CodingKeys.self,
        "PlaceSummary": PlaceSummary.CodingKeys.self,
        "PlumeBands": PlumeBands.CodingKeys.self,
        "PlumeHeadline": PlumeHeadline.CodingKeys.self,
        "PointInfo": PointInfo.CodingKeys.self,
        "PooledColumns": PooledColumns.CodingKeys.self,
        "PrecipDisplay": PrecipDisplay.CodingKeys.self,
        "PrecipOutlook": PrecipOutlook.CodingKeys.self,
        "PrecipType": PrecipType.CodingKeys.self,
        "PrecipitationByType": PrecipitationByType.CodingKeys.self,
        "ProbabilityResult": ProbabilityResult.CodingKeys.self,
        "ProbabilityThresholds": ProbabilityThresholds.CodingKeys.self,
        "PublicCatalogElevation": CatalogElevation.CodingKeys.self,
        "PublicCatalogLocation": CatalogLocation.CodingKeys.self,
        "PublicCatalogLocationDetail": CatalogLocationDetail.CodingKeys.self,
        "PublicCatalogLocationPage": CatalogLocationPage.CodingKeys.self,
        "PublicCatalogNearbyStation": CatalogNearbyStation.CodingKeys.self,
        "PublicCatalogPhoto": CatalogPhoto.CodingKeys.self,
        "PublicCatalogPrimaryLocation": CatalogPrimaryLocation.CodingKeys.self,
        "PublicCatalogStation": CatalogStation.CodingKeys.self,
        "PublicCatalogStationDetail": CatalogStationDetail.CodingKeys.self,
        "PublicCatalogStationPage": CatalogStationPage.CodingKeys.self,
        "PublicCatalogWebcam": CatalogWebcam.CodingKeys.self,
        "Quantiles": Quantiles.CodingKeys.self,
        "ResponseAttribution": ResponseAttribution.CodingKeys.self,
        "RunsResponse": AvailableRuns.CodingKeys.self,
        "SearchHit": SearchHit.CodingKeys.self,
        "SearchLocationsResponse": LocationSearchResults.CodingKeys.self,
        "SeasonDay": SeasonDay.CodingKeys.self,
        "SeasonResponse": SeasonResponse.CodingKeys.self,
        "SeasonStation": SeasonStation.CodingKeys.self,
        "SeasonTotal": SeasonTotal.CodingKeys.self,
        "Sector": Sector.CodingKeys.self,
        "SensorObservation": SensorObservation.CodingKeys.self,
        "SnowLevelRange": SnowLevelRange.CodingKeys.self,
        "SnowOnGround": SnowOnGround.CodingKeys.self,
        "SnowOutlook": SnowOutlook.CodingKeys.self,
        "SnowOutlookQuantiles": SnowOutlookQuantiles.CodingKeys.self,
        "SnowTrendDay": SnowTrendDay.CodingKeys.self,
        "SnowTrendGrid": SnowTrendGrid.CodingKeys.self,
        "SnowTrendResponse": SnowTrendResponse.CodingKeys.self,
        "SnowpackAspect": SnowpackAspect.CodingKeys.self,
        "SnowpackDepth": SnowpackDepth.CodingKeys.self,
        "SnowpackLayer": SnowpackLayer.CodingKeys.self,
        "SnowpackPlumeResponse": SnowpackPlumeResponse.CodingKeys.self,
        "SnowpackResponse": SnowpackResponse.CodingKeys.self,
        "SnowpackRun": SnowpackRun.CodingKeys.self,
        "SnowpackSpot": SnowpackSpot.CodingKeys.self,
        "SnowpackStep": SnowpackStep.CodingKeys.self,
        "SummaryEvent": SummaryEvent.CodingKeys.self,
        "SummaryValues": SummaryValues.CodingKeys.self,
        "TimeSeriesPoint": TimeSeriesPoint.CodingKeys.self,
        "WindowTotal": WindowTotal.CodingKeys.self,
    ]

    /// Object schemas with no model of their own, and why.
    static let unmodelled: [String: String] = [
        "AlertOutlineProperties":
            "GeoJSON properties pass through untouched as [String: JSONValue] (BEHAVIOR 3.0)"
    ]

    @Test("Every field of every object schema has a coding key in its model")
    func everyFieldModelled() {
        for (name, schema) in Self.spec["components"]?["schemas"]?.object ?? [:] {
            let fields = Self.properties(of: schema)
            guard !fields.isEmpty, Self.unmodelled[name] == nil else { continue }
            guard let keys = Self.codingKeys[name] else {
                Issue.record("schema \(name) has no Swift model in the drift map")
                continue
            }
            for field in fields where keys.init(stringValue: field) == nil {
                Issue.record("\(name).\(field) is not decoded by \(keys)")
            }
        }
    }

    /// The property names of an object schema, `allOf` flattened.
    static func properties(of schema: JSONValue) -> [String] {
        var names = Array((schema["properties"]?.object ?? [:]).keys)
        for part in schema["allOf"]?.array ?? [] {
            if let reference = part["$ref"]?.string,
                let target = reference.split(separator: "/").last.map(String.init),
                let resolved = spec["components"]?["schemas"]?[target]
            {
                names += properties(of: resolved)
            } else {
                names += properties(of: part)
            }
        }
        return names
    }

    static func modelType(_ operation: String, status: String) -> any Codable.Type {
        guard status.hasPrefix("2") else { return ErrorBody.self }
        switch operation {
        case "getLocationForecast", "getPointForecast": return ForecastResponse.self
        case "getAttribution": return Attribution.self
        case "getCurrentConditions", "getCurrentByCoordinates":
            return CurrentConditionsResponse.self
        case "getLocationAlerts", "getAlertsByCoordinates": return AlertsResponse.self
        case "getNearbyLocations": return NearbyLocations.self
        case "getNearbyByCoordinates": return NearbyPointLocations.self
        case "searchLocations": return LocationSearchResults.self
        case "getAllLocations", "getLocations": return LocationPage.self
        case "listCatalogLocations": return CatalogLocationPage.self
        case "getCatalogLocation": return CatalogLocationDetail.self
        case "listCatalogStations": return CatalogStationPage.self
        case "getCatalogStation": return CatalogStationDetail.self
        case "getAvailableRuns": return AvailableRuns.self
        case "explore": return ExploreResponse.self
        case "getComposition": return CompositionResponse.self
        case "getLocationSeason": return SeasonResponse.self
        case "getLocationSnowTrend": return SnowTrendResponse.self
        case "getLocationSnowpack": return SnowpackResponse.self
        case "getLocationSnowpackPlume": return SnowpackPlumeResponse.self
        case "getAlertOutlines": return AlertOutlineCollection.self
        case "getAvalancheZones": return AvalancheZoneCollection.self
        default: return JSONValue.self
        }
    }

    static func roundTrip(_ example: JSONValue, as type: any Codable.Type, label: String) throws {
        let data = try JSONCoding.encoder().encode(example)
        let decoded = try JSONCoding.decoder().decode(type, from: data)
        let again = try JSONValue.parse(try JSONCoding.encoder().encode(decoded))
        #expect(
            jsonEquivalent(again, example),
            "\(label) does not round-trip: \(firstDifference(again, example) ?? "")")
    }
}

@Suite("Vector bodies")
struct VectorBodyTests {
    static let bodies: [(String, any Codable.Type)] = [
        ("forecast-metric.json", ForecastResponse.self),
        ("forecast-imperial.json", ForecastResponse.self),
        ("forecast-prob-mixed.json", ForecastResponse.self),
        ("forecast-prob-snow.json", ForecastResponse.self),
        ("forecast-totals.json", ForecastResponse.self),
        ("catalog-page-1.json", CatalogLocationPage.self),
        ("catalog-page-2.json", CatalogLocationPage.self),
        ("catalog-detail.json", CatalogLocationDetail.self),
        ("search.json", LocationSearchResults.self), ("attribution.json", Attribution.self),
        ("error-bad-request.json", ErrorBody.self), ("error-unknown-code.json", ErrorBody.self),
        ("forecast-full.json", ForecastResponse.self),
        ("forecast-plume.json", ForecastResponse.self),
        ("forecast-pool.json", ForecastResponse.self),
        ("current-pass.json", CurrentConditionsResponse.self), ("alerts.json", AlertsResponse.self),
        ("locations-page.json", LocationPage.self), ("nearby.json", NearbyLocations.self),
        ("nearby-point.json", NearbyPointLocations.self), ("runs.json", AvailableRuns.self),
        ("search-sorted.json", LocationSearchResults.self), ("explore.json", ExploreResponse.self),
        ("composition.json", CompositionResponse.self), ("season.json", SeasonResponse.self),
        ("snow-trend.json", SnowTrendResponse.self), ("snowpack.json", SnowpackResponse.self),
        ("snowpack-plume.json", SnowpackPlumeResponse.self),
        ("alert-outlines.json", AlertOutlineCollection.self),
        ("avalanche-zones.json", AvalancheZoneCollection.self),
        ("catalog-detail-full.json", CatalogLocationDetail.self),
        ("catalog-station-detail.json", CatalogStationDetail.self),
    ]

    @Test("Every vector body has a model")
    func everyBodyListed() throws {
        let names = try FileManager.default.contentsOfDirectory(
            atPath: specDirectory.appendingPathComponent("vectors/bodies").path)
        let listed = Set(Self.bodies.map(\.0)).union(Self.errorOrOddBodies)
        for name in names where name.hasSuffix(".json") && !listed.contains(name) {
            Issue.record("vector body \(name) is not round-tripped")
        }
    }

    /// Bodies read only as errors, or as a forward-compatibility case.
    static let errorOrOddBodies: Set<String> = [
        "error-invalid-key.json", "error-not-found.json", "error-outside-coverage.json",
        "error-pro-required.json", "error-rate-limited.json", "error-unavailable.json",
        "forecast-unknown-fields.json",
    ]

    @Test("Every vector body round-trips through its model")
    func roundTrip() throws {
        for (name, type) in Self.bodies {
            try SpecDriftTests.roundTrip(
                try JSONValue.parse(try vectorBody(name)), as: type, label: name)
        }
    }

    @Test("Unknown fields are ignored and unknown enum values keep their raw string")
    func forwardCompatible() throws {
        let forecast = try JSONCoding.decoder().decode(
            ForecastResponse.self, from: try vectorBody("forecast-unknown-fields.json"))
        #expect(forecast.location.type == .unknown("a_location_type_added_later"))
        #expect(forecast.location.type?.rawValue == "a_location_type_added_later")
    }
}
