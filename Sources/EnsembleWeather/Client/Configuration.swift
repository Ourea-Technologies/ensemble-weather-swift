// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

extension EnsembleWeatherClient {
    /// How a client connects, authenticates, retries and caches.
    ///
    /// ```swift
    /// var configuration = EnsembleWeatherClient.Configuration(apiKey: "ow_...")
    /// configuration.units = .imperial
    /// configuration.maxRetries = 4
    /// let client = EnsembleWeatherClient(configuration: configuration)
    /// ```
    ///
    /// The API key never appears in the configuration's description.
    public struct Configuration: Sendable {
        /// The default API host.
        public static let defaultBaseURL =
            URL(string: "https://api.oureawx.com")
            ?? URL(fileURLWithPath: "/")

        /// The API key, sent as `X-API-Key`; `nil` calls anonymously at the Free tier.
        public var apiKey: String?
        /// The API host (and optional path prefix); a trailing slash is ignored.
        public var baseURL: URL
        /// The unit system of every request that takes `units`, unless a call overrides it.
        public var units: UnitSystem = .metric
        /// The timeout of each attempt, in seconds.
        public var timeout: TimeInterval = 30
        /// Retries after a connection error, 429, 502, 503 or 504; `0`
        /// makes exactly one attempt.
        public var maxRetries: Int = 2
        /// The `ETag` cache; `nil` turns caching off.
        ///
        /// A new in-memory cache (256 entries, 32 MiB) by default. Share one instance between
        /// clients to share entries; keyed and keyless entries never mix.
        public var cache: (any ResponseCache)? = MemoryResponseCache()
        /// Sends the key on the open routes too (search, catalog detail, attribution).
        ///
        /// Off by default: those are sent without credentials so the edge cache can share them
        /// between callers.
        public var sendsKeyOnOpenRoutes = false
        /// A product token appended to the `User-Agent`, such as `MyApp/2.1`.
        public var userAgentSuffix: String?
        /// The HTTP transport; ``URLSessionTransport`` by default.
        public var transport: any HTTPTransport = URLSessionTransport()
        /// The clock retries wait on.
        public var clock: any RetryClock = SystemRetryClock()
        /// Returns a random fraction in `0...1` for retry jitter.
        public var jitter: @Sendable () -> Double = { Double.random(in: 0...1) }
        /// Where deprecation notices go; once per operation per process by default.
        public var deprecationReporter: DeprecationReporter = .shared

        /// Creates a configuration.
        ///
        /// - Parameters:
        ///   - apiKey: The API key. When `nil`, `OUREA_API_KEY` from
        ///     `environment` is used if set; otherwise calls are anonymous.
        ///   - baseURL: The API host. When `nil`, `OUREA_BASE_URL` from
        ///     `environment` is used if set; otherwise `https://api.oureawx.com`.
        ///   - environment: The environment to read; the process's by default.
        public init(
            apiKey: String? = nil,
            baseURL: URL? = nil,
            environment: [String: String] = ProcessInfo.processInfo.environment
        ) {
            let environmentKey = environment["OUREA_API_KEY"].flatMap { $0.isEmpty ? nil : $0 }
            self.apiKey = apiKey ?? environmentKey
            self.baseURL =
                baseURL ?? environment["OUREA_BASE_URL"].flatMap {
                    $0.isEmpty ? nil : URL(string: $0)
                }
                ?? Self.defaultBaseURL
        }
    }
}

extension EnsembleWeatherClient.Configuration: CustomStringConvertible,
    CustomDebugStringConvertible,
    CustomReflectable
{
    /// A summary that shows whether a key is set, never the key.
    public var description: String {
        "Configuration(baseURL: \(baseURL.absoluteString), apiKey: \(apiKey == nil ? "none" : "<redacted>"), "
            + "units: \(units.rawValue), maxRetries: \(maxRetries), cache: \(cache == nil ? "off" : "on"))"
    }

    /// The same as ``description``.
    public var debugDescription: String { description }

    /// A mirror without the key, so `dump` and debuggers never print it.
    public var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "baseURL": baseURL, "apiKey": apiKey == nil ? "none" : "<redacted>",
                "units": units, "timeout": timeout, "maxRetries": maxRetries,
                "sendsKeyOnOpenRoutes": sendsKeyOnOpenRoutes,
            ])
    }
}

/// The SDK version and the `User-Agent` it sends.
public enum EnsembleWeatherVersion {
    /// This SDK's version.
    public static let sdk = "0.1.0"
    /// The API contract this SDK targets.
    public static let apiContract = "v1"

    /// The Swift language version the SDK was compiled with.
    static var swift: String {
        #if swift(>=6.3)
            "6.3"
        #elseif swift(>=6.2)
            "6.2"
        #elseif swift(>=6.1)
            "6.1"
        #else
            "6.0"
        #endif
    }

    /// `ensemble-weather-swift/<version> (Swift/<version>)`.
    public static var userAgent: String { "ensemble-weather-swift/\(sdk) (Swift/\(swift))" }
}
