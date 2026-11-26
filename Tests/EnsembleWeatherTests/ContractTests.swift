// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation
import Testing

@testable import EnsembleWeather

/// The 0.1.0 additions the shared vectors do not reach: argument checks
/// (a refused argument sends nothing), the snow trend's tier error, and the
/// decoding details of the new bodies.
@Suite("0.1.0 contract")
struct ContractTests {
    /// Runs `call` against a transport that answers 418, returning what it
    /// sent and what it threw.
    private func attempt(_ call: (Client) async throws -> Void) async -> (
        requests: [HTTPRequest], error: OureaError?
    ) {
        let transport = MockTransport([HTTPResponse(status: 418)])
        let client = Client(configuration: testConfiguration(transport: transport))
        do {
            try await call(client)
            return (transport.requests, nil)
        } catch {
            return (transport.requests, error as? OureaError)
        }
    }

    @Test(
        "An out-of-range near is a usage error, and nothing is sent",
        arguments: [
            Coordinate(latitude: 90.5, longitude: 0), Coordinate(latitude: 0, longitude: -181),
            Coordinate(latitude: .nan, longitude: 0), Coordinate(latitude: 0, longitude: .infinity),
        ])
    func nearOutOfRange(_ near: Coordinate) async {
        for call: (Client) async throws -> Void in [
            { _ = try await $0.explorePage(.snow5Days, near: near) },
            { _ = try await $0.searchLocations("hood", near: near) },
        ] {
            let (requests, error) = await attempt(call)
            #expect(error?.category == .usage)
            #expect(requests.isEmpty)
        }
    }

    @Test(
        "A bounding box out of range or inside out is a usage error, and nothing is sent",
        arguments: [
            BoundingBox(west: -116, south: 41, east: -125, north: 49),
            BoundingBox(west: -125, south: 49, east: -116, north: 41),
            BoundingBox(west: -181, south: 41, east: -116, north: 49),
            BoundingBox(west: -125, south: 41, east: -116, north: 91),
        ])
    func boundingBoxRefused(_ box: BoundingBox) async {
        let (requests, error) = await attempt { _ = try await $0.alertOutlines(boundingBox: box) }
        #expect(error?.category == .usage)
        #expect(requests.isEmpty)
    }

    @Test("A point on the bounds is sent with the shortest decimals and literal commas")
    func boundsSent() async {
        let (requests, _) = await attempt {
            _ = try await $0.explorePage(
                .baseDepth, near: Coordinate(latitude: -90, longitude: 180.0))
        }
        let query = requests.first.flatMap {
            URLComponents(url: $0.url, resolvingAgainstBaseURL: false)?.percentEncodedQuery
        }
        #expect(query == "metric=base_depth&near=-90,180")
    }

    @Test("members is left out by default, and sent as true or plume")
    func members() async {
        let cases: [(MemberSelection, String)] = [
            (.excluded, ""), (.rows, "members=true"), (.plume, "members=plume"),
        ]
        for (selection, expected) in cases {
            var options = ForecastOptions()
            options.members = selection
            let (requests, _) = await attempt {
                _ = try await $0.forecast(for: "or/mt-hood-meadows", options: options)
            }
            let query = requests.first.flatMap {
                URLComponents(url: $0.url, resolvingAgainstBaseURL: false)?.percentEncodedQuery
            }
            #expect((query ?? "") == expected, "\(selection)")
        }
    }

    @Test("PLUS_REQUIRED on the snow trend is a permission error")
    func plusRequired() async {
        let body = #"{"error":"PLUS_REQUIRED","message":"The snow trend needs a Plus or Pro key."}"#
        let transport = MockTransport([jsonResponse(403, body: Data(body.utf8))])
        let client = Client(configuration: testConfiguration(transport: transport))
        do {
            _ = try await client.snowTrend(for: "or/mt-hood-meadows")
            Issue.record("expected an error")
        } catch let error as OureaError {
            #expect(error.category == .permission)
            #expect(error.code == .plusRequired)
            #expect(error.status == 403)
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    @Test("The snowpack definitions keep their codes as keys")
    func definitionsKeepRawKeys() throws {
        let snowpack = try JSONCoding.decoder().decode(
            SnowpackResponse.self, from: try vectorBody("snowpack.json"))
        let raw = try JSONValue.parse(try vectorBody("snowpack.json"))
        let surface = raw["definitions"]?["surface"]?.object ?? [:]
        #expect(!surface.isEmpty)
        #expect(Set(snowpack.definitions.surface.keys) == Set(surface.keys))
        for (code, text) in surface { #expect(snowpack.definitions.surface[code] == text.string) }
    }

    @Test("The plume view has no hourly series, and its pool keeps null steps")
    func plumeShape() throws {
        let forecast = try JSONCoding.decoder().decode(
            ForecastResponse.self, from: try vectorBody("forecast-pool.json"))
        #expect(forecast.series.timeseries == nil)
        #expect(forecast.membersView == .pool)
        #expect(forecast.series.plume?.pool?.temperature.isEmpty == false)
    }

    @Test("A snow trend day may be null")
    func nullSnowTrendDay() throws {
        let raw = try JSONValue.parse(try vectorBody("snow-trend.json"))
        let trend = try JSONCoding.decoder().decode(
            SnowTrendResponse.self, from: try vectorBody("snow-trend.json"))
        let rawDays = raw["grids"]?.array?.first?["runs"]?.array?.first?["days"]?.array ?? []
        let days = trend.grids.first?.runs.first?.days ?? []
        #expect(days.count == rawDays.count)
        for (day, rawDay) in zip(days, rawDays) { #expect((day == nil) == (rawDay == .null)) }
    }
}
