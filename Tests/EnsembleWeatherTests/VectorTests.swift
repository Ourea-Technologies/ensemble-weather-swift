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

    @Test("All 58 vectors are present")
    func vectorCount() {
        #expect(Self.vectorNames.count == 58)
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
    /// The SDK value the call returned, read by its Swift property names.
    var result: Any?
    var metadata: ResponseMetadata?
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
        var configuration = Client.Configuration(
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
            let client = Client(configuration: callConfiguration)
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

    private func perform(_ call: JSONValue, on client: Client) async -> CallOutcome {
        let args = call["args"]?.object ?? [:]
        do {
            switch call["operation"]?.string {
            case "getLocationForecast":
                return outcome(
                    try await client.forecast(
                        for: location(args), options: try forecastOptions(args)))
            case "getPointForecast":
                return outcome(
                    try await client.getPointForecast(
                        latitude: args["lat"]?.number ?? .nan,
                        longitude: args["lon"]?.number ?? .nan,
                        elevationMeters: args["elevation_m"]?.number,
                        options: try forecastOptions(args)))
            case "getCurrentConditions":
                return outcome(try await client.currentConditions(for: location(args)))
            case "getLocationAlerts":
                return outcome(try await client.alerts(for: location(args)))
            case "getLocations":
                return outcome(
                    try await client.locationPage(
                        state: args["state"]?.string, limit: args["limit"]?.number.map { Int($0) }))
            case "getNearbyLocations":
                return outcome(try await client.nearbyLocations(to: location(args)))
            case "getNearbyByCoordinates":
                return outcome(
                    try await client.getPointNearby(
                        latitude: args["lat"]?.number ?? .nan,
                        longitude: args["lon"]?.number ?? .nan))
            case "getAvailableRuns":
                return outcome(
                    try await client.availableRuns(
                        limit: args["limit"]?.number.map { Int($0) } ?? 10))
            case "searchLocations":
                return outcome(
                    try await client.searchLocations(
                        args["q"]?.string ?? "",
                        sort: args["sort"]?.string.map(ExploreMetric.init(rawValue:)),
                        order: args["order"]?.string.flatMap(RankOrder.init(rawValue:))
                            ?? .descending,
                        near: coordinate(args["near"]),
                        radiusKilometers: args["radius_km"]?.number ?? 100))
            case "explore":
                return outcome(
                    try await client.explorePage(
                        ExploreMetric(rawValue: args["metric"]?.string ?? ""),
                        order: args["order"]?.string.flatMap(RankOrder.init(rawValue:))
                            ?? .descending,
                        type: args["type"]?.string.map(LocationType.init(rawValue:)),
                        state: args["state"]?.string, near: coordinate(args["near"]),
                        radiusKilometers: args["radius_km"]?.number ?? 100,
                        elevationMin: args["elevation_min"]?.number,
                        elevationMax: args["elevation_max"]?.number,
                        points: args["points"]?.string.flatMap(ExplorePoints.init(rawValue:))
                            ?? .primary,
                        limit: args["limit"]?.number.map { Int($0) } ?? 25,
                        cursor: args["cursor"]?.string,
                        units: args["units"]?.string.map(UnitSystem.init(rawValue:))))
            case "getComposition":
                return outcome(try await client.composition())
            case "getLocationSeason":
                return outcome(
                    try await client.season(
                        for: location(args), waterYear: args["water_year"]?.number.map { Int($0) },
                        includesDaily: strings(args["include"]).contains("daily"),
                        units: args["units"]?.string.map(UnitSystem.init(rawValue:))))
            case "getLocationSnowTrend":
                return outcome(
                    try await client.snowTrend(
                        for: location(args), elevation: args["elevation"]?.string,
                        units: args["units"]?.string.map(UnitSystem.init(rawValue:))))
            case "getLocationSnowpack":
                return outcome(try await client.snowpack(for: location(args)))
            case "getLocationSnowpackPlume":
                return outcome(try await client.snowpackPlume(for: location(args)))
            case "getAlertOutlines":
                let box = args["bbox"].map {
                    BoundingBox(
                        west: $0["west"]?.number ?? .nan, south: $0["south"]?.number ?? .nan,
                        east: $0["east"]?.number ?? .nan, north: $0["north"]?.number ?? .nan)
                }
                return outcome(
                    try await client.alertOutlines(
                        classes: Set(strings(args["classes"]).map(AlertClass.init(rawValue:))),
                        boundingBox: box))
            case "getAvalancheZones":
                return outcome(try await client.avalancheZones())
            case "getCatalogLocation":
                return outcome(
                    try await client.catalogLocation(
                        slug: args["slug"]?.string ?? "",
                        extras: Set(
                            strings(args["include"]).compactMap(CatalogExtra.init(rawValue:)))))
            case "getCatalogStation":
                return outcome(try await client.catalogStation(slug: args["slug"]?.string ?? ""))
            case "getAttribution":
                return outcome(try await client.attribution())
            case "listCatalogLocations":
                if args["iterate"]?.bool == true {
                    var slugs: [String] = []
                    for try await location in client.catalogLocations() {
                        slugs.append(location.slug)
                    }
                    return CallOutcome(items: slugs)
                }
                return outcome(try await client.catalogLocationPage())
            case let operation:
                Issue.record("the runner has no mapping for operation \(operation ?? "nil")")
                return CallOutcome()
            }
        } catch {
            return CallOutcome(error: error)
        }
    }

    private func outcome<Value: Sendable>(_ response: APIResponse<Value>) -> CallOutcome {
        CallOutcome(result: response.value, metadata: response.metadata)
    }

    private func location(_ args: [String: JSONValue]) -> LocationID {
        args["location"]?.string.map { LocationID($0) }
            ?? LocationID(state: args["state"]?.string ?? "", slug: args["slug"]?.string ?? "")
    }

    private func strings(_ value: JSONValue?) -> [String] {
        if let text = value?.string { return [text] }
        return value?.array?.compactMap(\.string) ?? []
    }

    private func coordinate(_ spec: JSONValue?) -> Coordinate? {
        spec.map {
            Coordinate(latitude: $0["lat"]?.number ?? .nan, longitude: $0["lon"]?.number ?? .nan)
        }
    }

    private func forecastOptions(_ args: [String: JSONValue]) throws -> ForecastOptions {
        var options = ForecastOptions()
        if let units = args["units"]?.string { options.units = UnitSystem(rawValue: units) }
        if let value = args["max_hours"]?.number { options.maxHours = Int(value) }
        switch args["members"] {
        case .bool(true)?: options.members = .rows
        case .string("plume")?: options.members = .plume
        default: break
        }
        if let value = args["models"]?.bool { options.includesModels = value }
        if let value = args["nowcast"]?.bool { options.usesNowcast = value }
        if let value = args["include_past"]?.bool { options.includesPast = value }
        if let value = args["daily"]?.bool { options.includesDaily = value }
        if let value = args["hourly"]?.bool { options.includesHourly = value }
        if let elevations = args["elevations"] {
            options.elevations = elevations.string == "all" ? .all : .named(strings(elevations))
        }
        if args["sources"] != nil { options.sources = strings(args["sources"]) }
        if args["exclude_sources"] != nil {
            options.excludedSources = strings(args["exclude_sources"])
        }
        options.extraVariables = Set(
            strings(args["include"]).compactMap(ForecastExtraVariable.init(rawValue:)))
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
                let leaf = SDKPath.leaf(at: path, in: result)
                if let raw = expected["unknown"]?.string {
                    #expect(
                        leaf.map(SDKPath.isUnknownCase) == true,
                        "\(label) \(path) is an unknown case")
                    #expect(
                        leaf.flatMap(SDKPath.json) == .string(raw),
                        "\(label) \(path) keeps the raw '\(raw)'")
                    continue
                }
                actual = leaf.flatMap(SDKPath.json)
            }
            #expect(
                SDKPath.matches(actual, expected),
                "\(label) \(path): \(String(describing: actual)) != \(expected)")
        }
    }

    private func checkError(_ error: (any Error)?, against expectation: [String: JSONValue]) {
        guard let error = error as? OureaError else {
            Issue.record("expected an OureaError, got \(String(describing: error))")
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

extension OureaError.Category {
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

/// Reads a vector's result path off an SDK value by its Swift property names.
///
/// A path names the SDK fields of BEHAVIOR.md 3.0 in snake_case, such as
/// `series.timeseries[0].members[0].items[0].id`; each name is matched to the
/// Swift property the SDK declares for it (`series`, `timeseries`, `items`,
/// `id`), so a vector fails if the Swift name is not the SDK name. GeoJSON
/// `properties` and other free-form JSON are read by their wire keys.
enum SDKPath {
    /// The value at `path`, or `nil` where the path ends early.
    static func leaf(at path: String, in root: Any) -> Any? {
        var current: Any? = root
        for component in path.split(separator: ".") {
            var name = Substring(component)
            var indices: [Int] = []
            while let open = name.lastIndex(of: "["), name.hasSuffix("]"),
                let index = Int(name[name.index(after: open)..<name.index(before: name.endIndex)])
            {
                indices.insert(index, at: 0)
                name = name[..<open]
            }
            if !name.isEmpty { current = current.flatMap { child(of: $0, named: String(name)) } }
            for index in indices {
                guard let value = current.flatMap(unwrapped) else { return nil }
                let elements = Mirror(reflecting: value).children.map(\.value)
                guard Mirror(reflecting: value).displayStyle == .collection, index < elements.count
                else { return nil }
                current = elements[index]
            }
        }
        return current.flatMap(unwrapped)
    }

    /// `value` without its optional wrappers; `nil` for `.none`.
    static func unwrapped(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else { return value }
        return mirror.children.first.flatMap { unwrapped($0.value) }
    }

    private static func child(of value: Any, named name: String) -> Any? {
        guard let value = unwrapped(value) else { return nil }
        if let json = value as? JSONValue {
            if case .object(let object) = json { return object[name] }
            return nil
        }
        if let object = value as? [String: JSONValue] { return object[name] }
        let mirror = Mirror(reflecting: value)
        let names = swiftNames(for: name)
        for candidate in names {
            if let match = mirror.children.first(where: { $0.label == candidate }) {
                // An enum case's payload: its first value, as `.height(Double, ...)`.
                if mirror.displayStyle == .enum,
                    let first = Mirror(reflecting: match.value).children.first,
                    Mirror(reflecting: match.value).displayStyle == .tuple
                {
                    return first.value
                }
                return match.value
            }
        }
        // A labelled value inside an enum case's payload, as `aboveFreezingLayerAloft`.
        if mirror.displayStyle == .enum, let payload = mirror.children.first?.value {
            let fields = Mirror(reflecting: payload).children
            for candidate in names {
                if let match = fields.first(where: { $0.label == candidate }) { return match.value }
            }
        }
        return nil
    }

    /// The Swift property names an SDK field name may have: the SDK's naming
    /// (`lat` is `latitude`, `_km` is `Kilometers`, `_24h` is `24Hours`, an
    /// acronym is upper case) and, for a Boolean, an `is` prefix.
    static func swiftNames(for name: String) -> [String] {
        let words = name.split(separator: "_").map(String.init)
        let named = camel(
            words.enumerated().map { index, word in
                if let expanded = expansions[word] { return expanded }
                if word.count > 1, word.dropLast().allSatisfy(\.isNumber) {
                    if word.hasSuffix("h") { return String(word.dropLast()) + "Hours" }
                    if word.hasSuffix("d") { return String(word.dropLast()) + "Days" }
                }
                if word == "m", index > 0, index == words.count - 1 { return "Meters" }
                return word
            })
        let plain = camel(words)
        let prefixed = "is" + named.prefix(1).uppercased() + named.dropFirst()
        return [named, plain, prefixed] + (aliases[name].map { [$0] } ?? [])
    }

    private static let expansions = [
        "id": "ID", "ids": "IDs", "url": "URL", "km": "Kilometers", "deg": "Degrees",
        "lat": "Latitude", "lon": "Longitude", "slr": "SnowToLiquidRatio",
        "swe": "SnowWaterEquivalent", "diff": "Difference",
    ]

    /// SDK names whose Swift property is named differently.
    private static let aliases = ["op": "comparison", "mslp": "meanSeaLevelPressure"]

    private static func camel(_ words: [String]) -> String {
        guard let first = words.first else { return "" }
        let head: String
        switch first {
        case "ID": head = "id"
        case "URL": head = "url"
        default: head = first.prefix(1).lowercased() + first.dropFirst()
        }
        return head + words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }

    /// The JSON form of a leaf value, encoded as the SDK encodes models.
    static func json(_ value: Any) -> JSONValue? {
        if let json = value as? JSONValue { return json }
        guard let encodable = value as? any Encodable else { return nil }
        return try? JSONValue.encoding(encodable)
    }

    /// Whether an open enum's value is its `unknown(_:)` case.
    static func isUnknownCase(_ value: Any) -> Bool {
        Mirror(reflecting: value).children.first?.label == "unknown"
    }

    /// Compares an SDK value with the vector's expectation: numbers numerically,
    /// `null` and absence alike, and a timestamp string as an instant.
    static func matches(_ actual: JSONValue?, _ expected: JSONValue) -> Bool {
        if case .string(let text)? = actual, case .string(let want) = expected,
            let lhs = JSONCoding.parseTimestamp(text), let rhs = JSONCoding.parseTimestamp(want)
        {
            return lhs == rhs
        }
        return jsonEquivalent(actual, expected)
    }
}
