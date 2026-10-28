// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation
import Testing

@testable import EnsembleWeather

@Suite("Client")
struct ClientTests {
    @Test("Connection errors are retried with backoff, then reported as connection errors")
    func connectionRetries() async {
        let clock = FakeClock()
        let transport = MockTransport(
            results: Array(repeating: .failure(URLError(.networkConnectionLost)), count: 3))
        let client = EnsembleWeatherClient(
            configuration: testConfiguration(transport: transport, clock: clock))
        do {
            _ = try await client.attribution()
            Issue.record("expected an error")
        } catch let error as EnsembleWeatherError {
            #expect(error.category == .connection)
        } catch {
            Issue.record("unexpected \(error)")
        }
        #expect(transport.requests.count == 3)
        #expect(clock.sleeps == [0.5, 1.0])
    }

    @Test("Backoff is capped at 8 s")
    func backoffCap() {
        let executor = RequestExecutor(
            configuration: testConfiguration(transport: MockTransport([])),
            lastRateLimit: Locked(nil))
        let failure = RetryableFailure(error: URLError(.timedOut), retryAfter: nil)
        #expect(
            (1...6).map { executor.retryDelay(for: failure, retry: $0) } == [0.5, 1, 2, 4, 8, 8])
    }

    @Test("A 504 with Retry-After waits exactly that long before retrying")
    func gatewayTimeoutRetryAfter() async throws {
        let clock = FakeClock()
        let transport = MockTransport([
            jsonResponse(
                504, body: Data(#"{"error":"TIMEOUT","message":"Timed out."}"#.utf8),
                headers: ["Retry-After": "5"]),
            jsonResponse(200, body: try vectorBody("attribution.json")),
        ])
        let client = EnsembleWeatherClient(
            configuration: testConfiguration(transport: transport, clock: clock))
        _ = try await client.attribution()
        #expect(transport.requests.count == 2)
        #expect(clock.sleeps == [5])
    }

    @Test("An error body's request_id, doc_url, param and nearest_location are kept")
    func errorBodyFields() async {
        let body = #"""
            {"error":"PRO_REQUIRED","message":"Coordinates need a Pro key.","param":"lat",
             "request_id":"01JBQ6ZK3V8M4T2N7XQH5R9W0C",
             "doc_url":"https://docs.oureawx.com/features/errors/#pro_required",
             "nearest_location":{"slug":"mt-hood-meadows",
                                 "url":"/api/v1/locations/or/mt-hood-meadows",
                                 "distance_km":4.25,"elevation_m":1635.6}}
            """#
        let transport = MockTransport([
            jsonResponse(403, body: Data(body.utf8), headers: ["X-Request-Id": "header-id"])
        ])
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        do {
            _ = try await client.forecast(latitude: 45.3, longitude: -121.7)
            Issue.record("expected an error")
        } catch let error as EnsembleWeatherError {
            #expect(error.category == .permission)
            #expect(error.code == .proRequired)
            #expect(error.requestID == "01JBQ6ZK3V8M4T2N7XQH5R9W0C")
            #expect(
                error.docURL?.absoluteString
                    == "https://docs.oureawx.com/features/errors/#pro_required")
            #expect(error.parameter == "lat")
            #expect(error.nearestLocation?.slug == "mt-hood-meadows")
            #expect(error.nearestLocation?.url == "/api/v1/locations/or/mt-hood-meadows")
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    @Test("Withdrawn error codes keep their string and map by status")
    func withdrawnCodes() {
        for code in ["FORBIDDEN", "GONE", "MODEL_RUN_NOT_FOUND", "AMBIGUOUS", "INVALID_MAX_HOURS"] {
            #expect(EnsembleWeatherError.category(forCode: ErrorCode(rawValue: code)) == nil)
        }
        #expect(EnsembleWeatherError.category(forCode: .authUnavailable) == .unavailable)
        #expect(EnsembleWeatherError.category(forCode: .outsideCoverage) == .outsideCoverage)
    }

    @Test("A cancelled task stops without retrying")
    func cancellation() async {
        let transport = MockTransport(results: [.failure(CancellationError())])
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        await #expect(throws: CancellationError.self) { _ = try await client.attribution() }
        #expect(transport.requests.count == 1)
    }

    @Test("A response still fresh under max-age is served without a request")
    func freshCache() async throws {
        let body = try vectorBody("attribution.json")
        let transport = MockTransport([
            jsonResponse(200, body: body, headers: ["Cache-Control": "private, max-age=60"])
        ])
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        _ = try await client.attribution()
        let second = try await client.attribution()
        #expect(second.metadata.cacheStatus == .fresh)
        #expect(transport.requests.count == 1)
    }

    @Test("The client keeps the last rate-limit state")
    func rateLimitState() async throws {
        let transport = MockTransport([
            jsonResponse(
                200, body: try vectorBody("attribution.json"),
                headers: [
                    "RateLimit-Limit": "100", "RateLimit-Remaining": "7", "RateLimit-Reset": "30",
                ])
        ])
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        let response = try await client.attribution()
        #expect(response.metadata.rateLimit?.remaining == 7)
        #expect(client.rateLimit == RateLimit(limit: 100, remaining: 7, resetSeconds: 30))
    }

    @Test("probability(for:) finds a term's answer; duplicates share it")
    func probabilityLookup() async throws {
        let transport = MockTransport([
            jsonResponse(200, body: try vectorBody("forecast-prob-snow.json"))
        ])
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        let snow = ProbabilityQuery.snowfall(atLeast: .inches(6))
        var options = ForecastOptions(units: .imperial, probabilities: [snow, snow])
        options.probabilities.append(.temperature(atMost: .fahrenheit(32), in: .hours(12)))
        let forecast = try await client.forecast(for: "or/mt-hood-meadows", options: options)
        #expect(forecast.probabilities.map(\.probability) == [0.42, 0.42, 0.97])
        #expect(forecast.probability(for: snow)?.members == 131)
        #expect(forecast.probability(for: .snowfall(atLeast: .inches(7))) == nil)
    }

    @Test("The page sequence follows the cursor lazily")
    func paging() async throws {
        let transport = MockTransport([
            jsonResponse(200, body: try vectorBody("catalog-page-1.json")),
            jsonResponse(200, body: try vectorBody("catalog-page-2.json")),
        ])
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        var iterator = client.catalogLocations().makeAsyncIterator()
        #expect(try await iterator.next()?.slug == "mt-hood-meadows")
        #expect(transport.requests.count == 1)
        #expect(try await iterator.next()?.slug == "timberline-lodge")
        #expect(try await iterator.next() == nil)
        #expect(transport.requests.count == 2)
    }

    @Test("A deprecation is reported once per operation per reporter")
    func deprecationOnce() async throws {
        let notices = NoticeCollector()
        let headers: HTTPHeaders = ["Deprecation": "@1798761600"]
        let transport = MockTransport([
            jsonResponse(200, body: try vectorBody("attribution.json"), headers: headers),
            jsonResponse(200, body: try vectorBody("attribution.json"), headers: headers),
            jsonResponse(200, body: try vectorBody("search.json"), headers: headers),
        ])
        var configuration = testConfiguration(transport: transport, notices: notices)
        configuration.cache = nil
        let client = EnsembleWeatherClient(configuration: configuration)
        _ = try await client.attribution()
        _ = try await client.attribution()
        _ = try await client.searchLocations("hood")
        #expect(notices.notices.map(\.operation) == ["getAttribution", "searchLocations"])
    }

    @Test("Point routes send coordinates exactly as given and keep defaults out")
    func pointQueries() async throws {
        let transport = MockTransport([HTTPResponse(status: 418), HTTPResponse(status: 418)])
        let client = EnsembleWeatherClient(
            configuration: testConfiguration(apiKey: "ow_pro", transport: transport))
        _ = try? await client.nearbyLocations(
            latitude: 45.3311, longitude: -121.6649, limit: 3, radiusKilometers: 50)
        _ = try? await client.currentConditions(
            latitude: 45.3311, longitude: -121.6649, units: .imperial, includesNowcastHours: true)
        let queries = transport.requests.map {
            URLComponents(url: $0.url, resolvingAgainstBaseURL: false)?.percentEncodedQuery
        }
        #expect(
            queries == [
                "lat=45.3311&lon=-121.6649",
                "include=nowcast_hours&lat=45.3311&lon=-121.6649&units=imperial",
            ])
    }

    @Test("Forecast options serialise in canonical form")
    func forecastOptionQuery() async throws {
        let transport = MockTransport([HTTPResponse(status: 418)])
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        var options = ForecastOptions()
        options.elevations = .named(["summit", "base"])
        options.diagnostics = [.provenance]
        options.extraVariables = [.skinTemperature, .meanSeaLevelPressure]
        options.feelsLike = [.nws]
        options.run = Date(timeIntervalSince1970: 1_794_700_800)
        options.windowTotals = [
            .snowfall(in: .hours(72)), .precipitation(in: .hours(from: 24, to: 48)),
        ]
        _ = try? await client.forecast(for: "or/mt-hood-meadows", options: options)
        let query = transport.requests.first.flatMap {
            URLComponents(url: $0.url, resolvingAgainstBaseURL: false)?.percentEncodedQuery
        }
        #expect(
            query
                == "diagnostics=provenance&elevations=base,summit&include=mslp,skin_temperature"
                + "&run=2026-11-15T00%3A00%3A00Z&totals=precipitation:24-48h,snowfall:72h")
    }

    @Test("A key from the environment is used when none is passed; an explicit key wins")
    func environmentKey() {
        #expect(
            EnsembleWeatherClient.Configuration(environment: ["OUREA_API_KEY": "ow_env"]).apiKey
                == "ow_env")
        #expect(
            EnsembleWeatherClient.Configuration(
                apiKey: "ow_arg", environment: ["OUREA_API_KEY": "ow_env"]
            ).apiKey == "ow_arg")
        #expect(
            EnsembleWeatherClient.Configuration(environment: ["OUREA_API_KEY": ""]).apiKey == nil)
        #expect(
            EnsembleWeatherClient.Configuration(environment: [
                "OUREA_BASE_URL": "http://127.0.0.1:8080"
            ]).baseURL
                .absoluteString == "http://127.0.0.1:8080")
    }
}
