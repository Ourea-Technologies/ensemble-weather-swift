// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// A decoded response together with what its HTTP exchange reported.
///
/// Read the model's properties straight through the response (dynamic
/// member lookup), or take ``value``:
///
/// ```swift
/// let forecast = try await client.forecast(for: "or/mt-hood-meadows")
/// print(forecast.location.name)                   // the model's property
/// print(forecast.metadata.rateLimit?.remaining)   // the exchange's
/// ```
@dynamicMemberLookup
public struct APIResponse<Value: Sendable>: Sendable {
    /// The decoded body.
    public var value: Value
    /// The status, headers, rate-limit state and cache status of the exchange.
    public var metadata: ResponseMetadata

    /// Creates a response.
    public init(value: Value, metadata: ResponseMetadata) {
        self.value = value
        self.metadata = metadata
    }

    /// A property of ``value``.
    public subscript<Property>(dynamicMember keyPath: KeyPath<Value, Property>) -> Property {
        value[keyPath: keyPath]
    }
}

extension APIResponse: Equatable where Value: Equatable {}
extension APIResponse: Hashable where Value: Hashable {}

/// What an HTTP exchange reported besides its body.
public struct ResponseMetadata: Sendable, Hashable {
    /// Where a response body came from.
    public enum CacheStatus: Sendable, Hashable {
        /// A fresh body from the network.
        case network
        /// The local cache's body, confirmed current by a `304 Not Modified`.
        case revalidated
        /// The local cache's body, still fresh under its `max-age`, with no request sent.
        case fresh
    }

    /// The HTTP status of the final response (`200`, or `304` when revalidated).
    public var status: Int
    /// The final response's headers.
    public var headers: HTTPHeaders
    /// The rate-limit state the response reported; `nil` on responses a
    /// shared cache may store, which carry none.
    public var rateLimit: RateLimit?
    /// The `X-Request-Id`, for support requests.
    public var requestID: String?
    /// The `ETag` of the body.
    public var etag: String?
    /// Where the body came from.
    public var cacheStatus: CacheStatus

    /// Creates metadata.
    public init(
        status: Int, headers: HTTPHeaders, rateLimit: RateLimit? = nil, requestID: String? = nil,
        etag: String? = nil, cacheStatus: CacheStatus = .network
    ) {
        self.status = status
        self.headers = headers
        self.rateLimit = rateLimit
        self.requestID = requestID
        self.etag = etag
        self.cacheStatus = cacheStatus
    }

    /// Whether the body is the cached one, confirmed by a `304`.
    public var isRevalidated: Bool { cacheStatus == .revalidated }
}
