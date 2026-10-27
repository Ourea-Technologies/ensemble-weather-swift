// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation
import Testing

@testable import EnsembleWeather

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// The SDK-side guarantees of SDK-STANDARD "Security".
@Suite("Security")
struct SecurityTests {
    static let secret = "ow_live_0123456789abcdef_SECRET"

    @Test("The key never appears in a configuration's or client's description, mirror or dump")
    func keyNotInDescriptions() {
        let configuration = EnsembleWeatherClient.Configuration(
            apiKey: Self.secret, environment: [:])
        let client = EnsembleWeatherClient(configuration: configuration)
        var dumped = ""
        dump(configuration, to: &dumped)
        var dumpedClient = ""
        dump(client, to: &dumpedClient)
        for text in [
            "\(configuration)", String(reflecting: configuration), dumped, "\(client)",
            String(reflecting: client),
            dumpedClient,
        ] {
            #expect(!text.contains(Self.secret), "leaked in: \(text)")
        }
    }

    @Test("The key never appears in an error, even when the server echoes it")
    func keyNotInErrors() async {
        let echo = Data(
            #"{"error":"INVALID_API_KEY","message":"Key \#(Self.secret) is revoked."}"#.utf8)
        let transport = MockTransport([jsonResponse(401, body: echo)])
        let client = EnsembleWeatherClient(
            configuration: testConfiguration(apiKey: Self.secret, transport: transport))
        do {
            _ = try await client.forecast(for: "or/mt-hood-meadows")
            Issue.record("expected an error")
        } catch {
            for text in ["\(error)", String(reflecting: error), error.localizedDescription] {
                #expect(!text.contains(Self.secret), "leaked in: \(text)")
            }
        }
    }

    @Test("The key never appears in a connection error built from the transport's message")
    func keyNotInConnectionErrors() async {
        struct Leaky: Error, LocalizedError {
            var errorDescription: String? { "failed sending X-API-Key: \(SecurityTests.secret)" }
        }
        let transport = MockTransport(results: [.failure(Leaky())])
        var configuration = testConfiguration(apiKey: Self.secret, transport: transport)
        configuration.maxRetries = 0
        let client = EnsembleWeatherClient(configuration: configuration)
        do {
            _ = try await client.forecast(for: "or/mt-hood-meadows")
            Issue.record("expected an error")
        } catch {
            #expect((error as? EnsembleWeatherError)?.category == .connection)
            #expect(!"\(error)".contains(Self.secret))
        }
    }

    @Test("The key never appears in a deprecation notice or the logs")
    func keyNotInNotices() async throws {
        let notices = NoticeCollector()
        let transport = MockTransport([
            jsonResponse(
                200, body: try vectorBody("forecast-metric.json"),
                headers: ["Sunset": "Wed, 01 Dec 2027 00:00:00 GMT"])
        ])
        let client = EnsembleWeatherClient(
            configuration: testConfiguration(
                apiKey: Self.secret, transport: transport, notices: notices))
        _ = try await client.forecast(for: "or/mt-hood-meadows")
        #expect(notices.notices.count == 1)
        #expect(notices.notices.allSatisfy { !$0.description.contains(Self.secret) })
    }

    @Test("The key is never sent to another host, nor back after it left")
    func noKeyAcrossHosts() async throws {
        let transport = MockTransport([
            HTTPResponse(
                status: 301, headers: ["Location": "/api/v1/locations/or/mt-hood-meadows"]),
            HTTPResponse(status: 307, headers: ["Location": "https://cdn.example.test/x"]),
            HTTPResponse(status: 308, headers: ["Location": "https://api.oureawx.com/api/v1/y"]),
            jsonResponse(200, body: try vectorBody("forecast-metric.json")),
        ])
        let client = EnsembleWeatherClient(
            configuration: testConfiguration(apiKey: Self.secret, transport: transport))
        _ = try await client.forecast(for: "oregon/mt-hood-meadows")
        let keys = transport.requests.map { $0.headers["X-API-Key"] }
        #expect(keys == [Self.secret, Self.secret, nil, nil])
    }

    @Test("A redirect to the same host over plain HTTP drops the key")
    func noKeyOnSchemeDowngrade() async throws {
        let transport = MockTransport([
            HTTPResponse(
                status: 302, headers: ["Location": "http://api.oureawx.com/api/v1/attribution"]),
            jsonResponse(200, body: try vectorBody("forecast-metric.json")),
        ])
        let client = EnsembleWeatherClient(
            configuration: testConfiguration(apiKey: Self.secret, transport: transport))
        _ = try await client.forecast(for: "or/mt-hood-meadows")
        #expect(transport.requests.last?.headers["X-API-Key"] == nil)
    }

    @Test("More than five redirects is an error, not a loop")
    func redirectLimit() async {
        let transport = MockTransport(
            Array(repeating: HTTPResponse(status: 302, headers: ["Location": "/again"]), count: 10))
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        await #expect(throws: EnsembleWeatherError.self) { _ = try await client.attribution() }
        #expect(transport.requests.count == 6)
    }

    @Test("TLS cannot be turned off: the session delegate never answers certificate challenges")
    func noTLSOverride() {
        let transport = URLSessionTransport()
        #if canImport(Darwin)
            let challenge = NSSelectorFromString(
                "URLSession:didReceiveChallenge:completionHandler:")
            let taskChallenge = NSSelectorFromString(
                "URLSession:task:didReceiveChallenge:completionHandler:")
            #expect(!transport.delegate.responds(to: challenge))
            #expect(!transport.delegate.responds(to: taskChallenge))
        #endif
        // No configuration property can carry a TLS override.
        let names = Mirror(reflecting: transport).children.compactMap(\.label).map {
            $0.lowercased()
        }
        #expect(
            !names.contains {
                $0.contains("tls") || $0.contains("insecure") || $0.contains("trust")
            })
    }

    @Test("A TLS verification failure is reported, never retried")
    func tlsFailureNotRetried() async {
        let transport = MockTransport(results: [.failure(URLError(.serverCertificateUntrusted))])
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        await #expect(throws: EnsembleWeatherError.self) { _ = try await client.attribution() }
        #expect(transport.requests.count == 1)
    }

    @Test("A response body over 64 MiB is an error, whatever the transport")
    func bodyBoundInClient() async {
        let huge = Data(count: 64 * 1024 * 1024 + 1)
        let transport = MockTransport([jsonResponse(200, body: huge)])
        let client = EnsembleWeatherClient(configuration: testConfiguration(transport: transport))
        do {
            _ = try await client.attribution()
            Issue.record("expected an error")
        } catch let error as EnsembleWeatherError {
            #expect(error.category == .invalidResponse)
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    @Test(
        "URLSessionTransport stops reading a body past its bound, and the bound is at most 64 MiB")
    func bodyBoundInTransport() async throws {
        #expect(
            URLSessionTransport(maximumBodyBytes: .max).delegate.maximumBodyBytes == 64 * 1024
                * 1024)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StreamingStubProtocol.self]
        let transport = URLSessionTransport(configuration: configuration, maximumBodyBytes: 4096)
        let request = HTTPRequest(url: try #require(URL(string: "https://stub.example.test/big")))
        do {
            _ = try await transport.send(request)
            Issue.record("expected the bound to stop the body")
        } catch let error as EnsembleWeatherError {
            #expect(error.category == .invalidResponse)
        }
        let small = try await transport.send(
            HTTPRequest(url: try #require(URL(string: "https://stub.example.test/small"))))
        #expect(small.status == 200)
        #expect(small.body.count == 1024)
    }

    @Test("JSON decodes into concrete model types only")
    func noPolymorphicDecoding() throws {
        let hostile = Data(#"{"providers":[],"$type":"System.Object","__proto__":{"x":1}}"#.utf8)
        let attribution = try JSONCoding.decoder().decode(Attribution.self, from: hostile)
        #expect(attribution.providers.isEmpty)
    }
}

/// Serves `/big` as 16 chunks of 1 KiB and `/small` as one 1 KiB chunk.
final class StreamingStubProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "stub.example.test"
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
            let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])
        else { return }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        let chunks = url.path == "/big" ? 16 : 1
        for _ in 0..<chunks { client?.urlProtocol(self, didLoad: Data(count: 1024)) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
