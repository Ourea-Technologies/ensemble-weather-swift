// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation
import Testing

@testable import EnsembleWeather

@Suite("Canonical form")
struct CanonicalFormTests {
    @Test(
        "Numbers are the shortest round-trip decimal, never an exponent",
        arguments: [
            (45.3311, "45.3311"), (-121.6649, "-121.6649"), (1661, "1661"), (0.00001, "0.00001"),
            (1.5e-7, "0.00000015"), (1e21, "1000000000000000000000"), (-0.0, "0"), (50, "50"),
            (0.1, "0.1"),
        ])
    func shortestDecimal(value: Double, expected: String) {
        #expect(DecimalFormatting.shortest(value) == expected)
    }

    @Test(
        "Thresholds round half away from zero in doubles and print fixed decimals",
        arguments: [
            (0.0625, 3, "0.063"), (1.005, 2, "1.00"), (-0.04, 1, "0.0"), (-5, 1, "-5.0"),
            (1524.4, 0, "1524"),
            (152.4, 2, "152.40"), (2.5, 0, "3"), (-2.5, 0, "-3"), (0.05, 1, "0.1"),
        ])
    func rounding(value: Double, decimals: Int, expected: String) throws {
        let scaled = try #require(DecimalFormatting.roundedScaled(value, decimals: decimals))
        #expect(DecimalFormatting.fixed(scaled: scaled, decimals: decimals) == expected)
    }

    @Test("Percent-encoding is RFC 3986 with uppercase hex")
    func percentEncoding() {
        #expect(PercentEncoding.encode("Mt. Hood & co/ñ") == "Mt.%20Hood%20%26%20co%2F%C3%B1")
        #expect(PercentEncoding.encode("a-b_c.d~e") == "a-b_c.d~e")
        #expect(PercentEncoding.encode("a:b,c", keeping: [":", ","]) == "a:b,c")
        #expect(PercentEncoding.encode("a+b") == "a%2Bb")
    }

    @Test("Query parameters are sorted by name; defaults are dropped")
    func queryOrder() {
        var query = QueryString()
        query.add("units", "imperial", default: "metric")
        query.add("max_hours", 24, default: 24)
        query.add("include_past", true, default: false)
        query.add("cursor", nil as String?)
        query.addRepeated("capability", ["swe", "air_temp", "swe"])
        #expect(
            query.encoded == "capability=air_temp&capability=swe&include_past=true&units=imperial")
    }

    @Test("Unit conversion of thresholds uses the exact factors")
    func conversions() throws {
        func wire(_ query: ProbabilityQuery, _ units: UnitSystem) throws -> String {
            try ResolvedProbabilityTerm(query, units: units).wireValue
        }
        #expect(try wire(.snowfall(atLeast: .inches(6)), .metric) == "snowfall:ge:152.40:24h")
        #expect(
            try wire(.snowfall(atLeast: .centimeters(15)), .imperial) == "snowfall:ge:5.906:24h")
        #expect(
            try wire(.temperature(atMost: .fahrenheit(32)), .metric) == "temperature:le:0.0:24h")
        #expect(
            try wire(.temperature(atMost: .celsius(1.85)), .kelvin) == "temperature:le:275.0:24h")
        #expect(
            try wire(.temperature(atMost: .celsius(-40)), .imperial) == "temperature:le:-40.0:24h")
        #expect(
            try wire(.windSpeed(atLeast: .milesPerHour(50)), .metric) == "wind_speed:ge:22.4:24h")
        #expect(try wire(.snowLevel(atMost: .feet(5000)), .metric) == "snow_level:le:1524:24h")
        #expect(try wire(.windSpeed(atLeast: 15), .imperial) == "wind_speed:ge:15.0:24h")
    }

    @Test("Probability terms are de-duplicated and sorted as the server sorts them")
    func termOrder() throws {
        let queries: [ProbabilityQuery] = [
            .temperature(atMost: 0), .snowfall(atLeast: 10, in: .hours(48)), .snowfall(atLeast: 5),
            .temperature(atLeast: 0), .temperature(atMost: 0, in: .hours(24), aggregation: .all),
            .snowfall(atLeast: 5), .temperature(atMost: 0, in: .hours(from: 6, to: 12)),
        ]
        let terms = try queries.map { try ResolvedProbabilityTerm($0, units: .metric) }
        #expect(
            ResolvedProbabilityTerm.wireValue(for: terms)
                == "snowfall:ge:5.00:24h,snowfall:ge:10.00:48h,temperature:ge:0.0:24h,"
                + "temperature:le:0.0:24h,temperature:le:0.0:24h:all,temperature:le:0.0:6-12h")
    }

    @Test("Invalid terms are usage errors before anything is sent")
    func invalidTerms() {
        let invalid: [ProbabilityQuery] = [
            ProbabilityQuery(
                variable: .precipitation, comparison: .atLeast, threshold: 1, aggregation: .any),
            ProbabilityQuery(
                variable: .temperature, comparison: .atLeast, threshold: 1, aggregation: .total),
            .snowfall(atLeast: .fahrenheit(3)),
            .snowfall(atLeast: 1, in: .hours(361)),
            .snowfall(atLeast: 1, in: .hours(from: 12, to: 12)),
            ProbabilityQuery(variable: .unknown("humidity"), comparison: .atLeast, threshold: 1),
            .snowfall(atLeast: Threshold(.nan)),
        ]
        for query in invalid {
            #expect(throws: EnsembleWeatherError.self) {
                try ResolvedProbabilityTerm(query, units: .metric)
            }
        }
        #expect(throws: EnsembleWeatherError.self) {
            try ResolvedWindowTotal(WindowTotalQuery(variable: .temperature, window: .hours(24)))
        }
    }

    @Test("A combined location splits on its one slash; a state code is lowercased")
    func locationIDs() throws {
        #expect(try LocationID("OR/mt-hood-meadows").pathSegments() == ["or", "mt-hood-meadows"])
        #expect(
            try LocationID("oregon/mt-hood-meadows").pathSegments() == [
                "oregon", "mt-hood-meadows",
            ])
        #expect(throws: EnsembleWeatherError.self) {
            try LocationID("mt-hood-meadows").pathSegments()
        }
        #expect(throws: EnsembleWeatherError.self) { try LocationID("a/b/c").pathSegments() }
    }
}

@Suite("Support")
struct SupportTests {
    @Test("SHA-256 matches the FIPS 180-4 test vectors")
    func sha256() {
        #expect(
            SHA256.hexDigest(of: Array("".utf8))
                == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        #expect(
            SHA256.hexDigest(of: Array("abc".utf8))
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        #expect(
            SHA256.hexDigest(
                of: Array("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".utf8))
                == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1")
        #expect(SHA256.hexDigest(of: [UInt8](repeating: 0x61, count: 1000)).count == 64)
    }

    @Test("The memory cache evicts least recently used entries past its bounds")
    func lruCache() async {
        let cache = MemoryResponseCache(maximumEntries: 2, maximumBytes: 1000)
        func entry(_ size: Int) -> CachedResponse {
            CachedResponse(
                body: Data(count: size), headers: [:], etag: "\"x\"", storedAt: Date(), maxAge: 0)
        }
        await cache.store(entry(10), forKey: "a")
        await cache.store(entry(10), forKey: "b")
        _ = await cache.entry(forKey: "a")
        await cache.store(entry(10), forKey: "c")
        #expect(await cache.entry(forKey: "b") == nil)
        #expect(await cache.entry(forKey: "a") != nil)
        await cache.store(entry(990), forKey: "d")
        #expect(await cache.count == 2)
        await cache.store(entry(2000), forKey: "e")
        #expect(await cache.entry(forKey: "e") == nil)
    }

    @Test("Retry-After parses delta-seconds and HTTP-dates")
    func retryAfter() {
        let now = Date(timeIntervalSince1970: 1_794_700_800)
        #expect(RetryAfter.seconds("3", now: now) == 3)
        #expect(RetryAfter.seconds("Sun, 15 Nov 2026 00:00:30 GMT", now: now) == 30)
        #expect(RetryAfter.seconds("soon", now: now) == nil)
    }

    @Test("Cache-Control: no-store and max-age")
    func cacheControl() {
        #expect(CacheControl("no-store").noStore)
        #expect(
            CacheControl("public, max-age=0, s-maxage=600, stale-while-revalidate=60").maxAge == 0)
        #expect(CacheControl("private, max-age=120").maxAge == 120)
        #expect(CacheControl("max-age=120, no-cache").maxAge == 0)
    }

    @Test("The deprecation Link is the rel=deprecation target")
    func deprecationLink() {
        let header =
            #"</api/v1/attribution>; rel="license", <https://docs.oureawx.com/changelog>; rel="deprecation""#
        #expect(
            DeprecationNotice.deprecationLink(in: header)?.absoluteString
                == "https://docs.oureawx.com/changelog")
    }

    @Test("Quantile ranges exist only for served pairs and never reorder a circular arc")
    func quantileRanges() {
        let direction = Quantiles(mean: 5, p10: 355, p25: 0, p50: 5, p75: 10, p90: 15)
        #expect(direction.range(.p10ToP90) == QuantileInterval(lower: 355, upper: 15))
        #expect(direction.median == 5)
        #expect(Quantiles(p10: 1).range(.p10ToP90) == nil)
    }

    @Test("The User-Agent names the SDK and the Swift version")
    func userAgent() {
        #expect(
            EnsembleWeatherVersion.userAgent.range(
                of: #"^ensemble-weather-swift/0\.1\.0 \(Swift/\d+\.\d+\)$"#,
                options: .regularExpression) != nil)
    }
}
