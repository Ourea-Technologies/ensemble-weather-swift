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
    static let calls: [String: @Sendable (EnsembleWeatherClient) async throws -> Void] = [
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
            let client = EnsembleWeatherClient(
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
                guard let content = response["content"]?["application/json"] else { continue }
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
            "MembersCumulative": MembersCumulative.self,
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

    static func modelType(_ operation: String, status: String) -> any Codable.Type {
        guard status.hasPrefix("2") else { return ErrorBody.self }
        switch operation {
        case "getLocationForecast", "getPointForecast": return ForecastResponse.self
        case "getAttribution": return Attribution.self
        case "getCurrentConditions", "getCurrentByCoordinates":
            return CurrentConditionsResponse.self
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
