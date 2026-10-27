// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation
import Testing

@testable import EnsembleWeather

/// Runs every shared vector in `spec/vectors/` (BEHAVIOR 13) through a mock transport.
///
/// A vector this runner cannot run fails; none is skipped.
@Suite("Shared vectors")
struct VectorTests {
    static let vectorsDirectory = specDirectory.appendingPathComponent("vectors")

    /// Every vector file, as `area/name.json`.
    static let vectorNames: [String] = {
        let areas =
            (try? FileManager.default.contentsOfDirectory(atPath: vectorsDirectory.path)) ?? []
        return areas.filter { $0 != "bodies" }.flatMap { area in
            ((try? FileManager.default.contentsOfDirectory(
                atPath: vectorsDirectory.appendingPathComponent(area).path)) ?? [])
                .filter { $0.hasSuffix(".json") }
                .map { "\(area)/\($0)" }
        }.sorted()
    }()

    @Test("All 43 vectors are present")
    func vectorCount() {
        #expect(Self.vectorNames.count == 43)
    }

    @Test("Vector", arguments: vectorNames)
    func run(_ name: String) async throws {
        let vector = try JSONValue.parse(
            Data(contentsOf: Self.vectorsDirectory.appendingPathComponent(name)))
        try await VectorRun(vector: vector).execute()
    }
}

/// The outcome of one call.
private struct CallOutcome {
    var result: JSONValue?
    var metadata: ResponseMetadata?
    var unknownEnums: [String: String] = [:]
    var error: (any Error)?
    var items: [String]?
}

private struct VectorRun {
    let vector: JSONValue

    func execute() async throws {
        let responses = try (vector["responses"]?.array ?? []).map(makeResponse)
        let transport = MockTransport(responses)
        let clock = FakeClock()
        let notices = NoticeCollector()
        let clientSpec = vector["client"]?.object ?? [:]
        var environment: [String: String] = [:]
        for (key, value) in clientSpec["env"]?.object ?? [:] { environment[key] = value.string }
        var configuration = EnsembleWeatherClient.Configuration(
            apiKey: clientSpec["api_key"]?.string,
            baseURL: clientSpec["base_url"]?.string.flatMap(URL.init(string:)),
            environment: environment)
        configuration.transport = transport
        configuration.clock = clock
        configuration.jitter = { 1.0 }
        configuration.deprecationReporter = DeprecationReporter { notices.add($0) }
        if let retries = clientSpec["max_retries"]?.number {
            configuration.maxRetries = Int(retries)
        }
        if clientSpec["cache"]?.bool == false { configuration.cache = nil }
        if let sends = clientSpec["send_key_on_open_routes"]?.bool {
            configuration.sendsKeyOnOpenRoutes = sends
        }

        let calls = vector["calls"]?.array ?? [vector["call"]].compactMap { $0 }
        var outcomes: [CallOutcome] = []
        for call in calls {
            var callConfiguration = configuration
            if let key = call["with_api_key"]?.string { callConfiguration.apiKey = key }
            let client = EnsembleWeatherClient(configuration: callConfiguration)
            outcomes.append(await perform(call, on: client))
        }

        let expected = vector["expect"]?.object ?? [:]
        let requests = transport.requests

        // Requests.
        if vector["expect_request"] == .null {
            #expect(requests.isEmpty, "no request may be sent")
        }
        let expectedRequests =
            vector["expect_requests"]?.array
            ?? [vector["expect_request"]].compactMap { $0 }.filter { $0 != .null }
        for (index, expectation) in expectedRequests.enumerated() {
            guard index < requests.count else {
                Issue.record("expected request \(index) was not sent")
                continue
            }
            checkRequest(requests[index], against: expectation, index: index)
        }
        if let count = expected["requests"]?.number {
            #expect(requests.count == Int(count), "request count")
        }

        // Results.
        if let result = expected["result"] {
            check(outcomes.last, against: result, label: "result")
        }
        for (index, result) in (expected["results"]?.array ?? []).enumerated() {
            check(
                index < outcomes.count ? outcomes[index] : nil, against: result,
                label: "results[\(index)]")
        }
        if let errorExpectation = expected["error"]?.object {
            checkError(outcomes.last?.error, against: errorExpectation)
        } else {
            for outcome in outcomes where outcome.error != nil {
                Issue.record("unexpected error: \(String(describing: outcome.error))")
            }
        }
        if let items = expected["items"]?.array {
            #expect(outcomes.last?.items == items.compactMap(\.string), "iterated items")
        }
        if let delays = expected["delays_s"]?.array {
            #expect(clock.sleeps == delays.compactMap(\.number), "retry delays")
        }
        if let warnings = expected["warnings"]?.array {
            let texts = notices.notices.map(\.description)
            #expect(texts.count == warnings.count, "warning count")
            for (text, warning) in zip(texts, warnings) {
                if let fragment = warning["contains"]?.string {
                    #expect(text.contains(fragment), "warning '\(text)' contains '\(fragment)'")
                }
            }
        }
    }

    private func makeResponse(_ spec: JSONValue) throws -> HTTPResponse {
        var headers = HTTPHeaders()
        for (name, value) in spec["headers"]?.object ?? [:] { headers[name] = value.string }
        var body = Data()
        if let file = spec["body_file"]?.string {
            body = try Data(contentsOf: VectorTests.vectorsDirectory.appendingPathComponent(file))
        } else if let text = spec["body"]?.string {
            body = Data(text.utf8)
        }
        return HTTPResponse(
            status: Int(spec["status"]?.number ?? 200), headers: headers, body: body)
    }

    // MARK: - The per-language mapping: vector operations to SDK calls

    private func perform(_ call: JSONValue, on client: EnsembleWeatherClient) async -> CallOutcome {
        let args = call["args"]?.object ?? [:]
        do {
            switch call["operation"]?.string {
            case "getLocationForecast":
                let location =
                    args["location"]?.string.map { LocationID($0) }
                    ?? LocationID(
                        state: args["state"]?.string ?? "", slug: args["name"]?.string ?? "")
                let response = try await client.forecast(
                    for: location, options: try forecastOptions(args))
                return try outcome(response) { (forecast: ForecastResponse) in
                    ["location.type": forecast.location.type]
                }
            case "getPointForecast":
                let response = try await client.forecast(
                    latitude: args["lat"]?.number ?? .nan, longitude: args["lon"]?.number ?? .nan,
                    elevationMeters: args["elevation_m"]?.number, options: try forecastOptions(args)
                )
                return try outcome(response) { (forecast: ForecastResponse) in
                    ["location.type": forecast.location.type]
                }
            case "searchLocations":
                return try outcome(try await client.searchLocations(args["q"]?.string ?? "")) { _ in
                    [:]
                }
            case "getCatalogLocation":
                return try outcome(
                    try await client.catalogLocation(slug: args["slug"]?.string ?? "")
                ) {
                    (detail: CatalogLocationDetail) in ["type": detail.type]
                }
            case "getAttribution":
                return try outcome(try await client.attribution()) { _ in [:] }
            case "listCatalogLocations":
                if args["iterate"]?.bool == true {
                    var slugs: [String] = []
                    for try await location in client.catalogLocations() {
                        slugs.append(location.slug)
                    }
                    return CallOutcome(items: slugs)
                }
                return try outcome(try await client.catalogLocationPage()) { _ in [:] }
            case let operation:
                Issue.record("the runner has no mapping for operation \(operation ?? "nil")")
                return CallOutcome()
            }
        } catch {
            return CallOutcome(error: error)
        }
    }

    private func outcome<Value: Encodable>(
        _ response: APIResponse<Value>, unknownEnums: (Value) -> [String: LocationType]
    ) throws -> CallOutcome {
        var unknown: [String: String] = [:]
        for (path, value) in unknownEnums(response.value) {
            if case .unknown(let raw) = value { unknown[path] = raw }
        }
        return CallOutcome(
            result: try JSONValue.encoding(response.value), metadata: response.metadata,
            unknownEnums: unknown)
    }

    private func forecastOptions(_ args: [String: JSONValue]) throws -> ForecastOptions {
        var options = ForecastOptions()
        if let units = args["units"]?.string { options.units = UnitSystem(rawValue: units) }
        if let value = args["max_hours"]?.number { options.maxHours = Int(value) }
        if let value = args["members"]?.bool { options.includesMembers = value }
        if let value = args["models"]?.bool { options.includesModels = value }
        if let value = args["nowcast"]?.bool { options.usesNowcast = value }
        if let value = args["include_past"]?.bool { options.includesPast = value }
        if let value = args["daily"]?.bool { options.includesDaily = value }
        if let value = args["hourly"]?.bool { options.includesHourly = value }
        options.probabilities = (args["prob"]?.array ?? []).map { term in
            ProbabilityQuery(
                variable: ForecastVariable(rawValue: term["variable"]?.string ?? ""),
                comparison: ProbabilityComparison(rawValue: term["op"]?.string ?? ""),
                threshold: threshold(term["threshold"]),
                window: window(term["window"]),
                aggregation: term["aggregation"]?.string.map(ProbabilityAggregation.init(rawValue:))
            )
        }
        options.windowTotals = (args["totals"]?.array ?? []).map { total in
            WindowTotalQuery(
                variable: ForecastVariable(rawValue: total["variable"]?.string ?? ""),
                window: window(total["window"]))
        }
        return options
    }

    private func threshold(_ spec: JSONValue?) -> Threshold {
        Threshold(
            spec?["value"]?.number ?? .nan,
            unit: spec?["unit"]?.string.flatMap(Threshold.Unit.init(rawValue:)))
    }

    private func window(_ spec: JSONValue?) -> ForecastWindow {
        guard let spec else { return .next24Hours }
        if let hours = spec["hours"]?.number { return .hours(Int(hours)) }
        return .hours(
            from: Int(spec["start_hours"]?.number ?? 0), to: Int(spec["end_hours"]?.number ?? 0))
    }

    // MARK: - Checks

    private func checkRequest(_ request: HTTPRequest, against expectation: JSONValue, index: Int) {
        let label = "request \(index)"
        let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
        if let method = expectation["method"]?.string {
            #expect(request.method == method, "\(label) method")
        }
        if let path = expectation["path"]?.string {
            #expect(components?.percentEncodedPath == path, "\(label) path")
        }
        if let prefix = expectation["url_prefix"]?.string {
            #expect(
                request.url.absoluteString.hasPrefix(prefix),
                "\(label) URL \(request.url) starts with \(prefix)")
        }
        let rawQuery = components?.percentEncodedQuery ?? ""
        if let queryString = expectation["query_string"]?.string {
            #expect(rawQuery == queryString, "\(label) query string")
        }
        var decoded: [String: String] = [:]
        for pair in rawQuery.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1).map {
                String($0).removingPercentEncoding ?? ""
            }
            decoded[parts[0]] = parts.count > 1 ? parts[1] : ""
        }
        for (name, value) in expectation["query"]?.object ?? [:] {
            #expect(decoded[name] == value.string, "\(label) query \(name)")
        }
        for name in expectation["query_absent"]?.array?.compactMap(\.string) ?? [] {
            #expect(decoded[name] == nil, "\(label) query \(name) absent")
        }
        for (name, value) in expectation["headers"]?.object ?? [:] {
            #expect(request.headers[name] == value.string, "\(label) header \(name)")
        }
        for name in expectation["headers_absent"]?.array?.compactMap(\.string) ?? [] {
            #expect(request.headers[name] == nil, "\(label) header \(name) absent")
        }
        for (name, pattern) in expectation["headers_match"]?.object ?? [:] {
            let value = request.headers[name] ?? ""
            let matches =
                (pattern.string.flatMap { try? NSRegularExpression(pattern: $0) })
                .map {
                    $0.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil
                } ?? false
            #expect(matches, "\(label) header \(name) '\(value)' matches \(pattern)")
        }
    }

    private func check(_ outcome: CallOutcome?, against expectation: JSONValue, label: String) {
        guard let outcome, outcome.error == nil, let result = outcome.result else {
            Issue.record("\(label): no result (\(String(describing: outcome?.error)))")
            return
        }
        for (path, expected) in expectation.object ?? [:] {
            let actual: JSONValue?
            switch path {
            case "revalidated":
                actual = outcome.metadata.map { .bool($0.isRevalidated) }
            case let path where path.hasPrefix("rate_limit."):
                let limit = outcome.metadata?.rateLimit
                let value: Int? =
                    switch path {
                    case "rate_limit.limit": limit?.limit
                    case "rate_limit.remaining": limit?.remaining
                    case "rate_limit.reset": limit?.resetSeconds
                    default: nil
                    }
                actual = value.map { .number(Double($0)) }
            default:
                if let raw = expected["unknown"]?.string {
                    #expect(
                        outcome.unknownEnums[path] == raw,
                        "\(label) \(path) is the unknown case '\(raw)'")
                    continue
                }
                actual = result.value(at: path)
            }
            #expect(
                jsonEquivalent(actual, expected),
                "\(label) \(path): \(String(describing: actual)) != \(expected)")
        }
    }

    private func checkError(_ error: (any Error)?, against expectation: [String: JSONValue]) {
        guard let error = error as? EnsembleWeatherError else {
            Issue.record("expected an EnsembleWeatherError, got \(String(describing: error))")
            return
        }
        if let category = expectation["category"]?.string {
            #expect(error.category.vectorName == category, "error category")
        }
        if let code = expectation["code"] {
            #expect(error.code?.rawValue == code.string, "error code")
        }
        if let status = expectation["status"]?.number {
            #expect(error.status == Int(status), "error status")
        }
        if let retryAfter = expectation["retry_after"]?.number {
            #expect(error.retryAfter == retryAfter, "error retry_after")
        }
        if let secret = expectation["string_excludes"]?.string {
            for text in [
                error.message, error.description, error.localizedDescription, "\(error)",
                String(reflecting: error),
            ] {
                #expect(!text.contains(secret), "error text must not contain the secret")
            }
        }
    }
}

extension EnsembleWeatherError.Category {
    /// The snake_case name the vectors use.
    var vectorName: String {
        switch self {
        case .notFound: "not_found"
        case .invalidRequest: "invalid_request"
        case .outsideCoverage: "outside_coverage"
        case .rateLimited: "rate_limited"
        case .invalidResponse: "invalid_response"
        default: rawValue
        }
    }
}
