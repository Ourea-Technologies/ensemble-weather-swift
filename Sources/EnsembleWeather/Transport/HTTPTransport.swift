// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// Sends one HTTP request and returns its response, without following
/// redirects, retrying or caching (the client does those).
///
/// The default is ``URLSessionTransport``. Supply your own to route requests
/// through another HTTP stack, or a mock in tests:
///
/// ```swift
/// struct CannedTransport: HTTPTransport {
///     func send(_ request: HTTPRequest) async throws -> HTTPResponse {
///         HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: body)
///     }
/// }
/// ```
///
/// Throw `URLError` (or any error) when no response arrives; the client
/// reports it as a ``EnsembleWeatherError/Category/connection`` error and
/// retries it.
public protocol HTTPTransport: Sendable {
    /// Sends `request` and returns the response as received, 3xx included.
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}

/// An HTTP request the client asks a transport to send.
///
/// Every API request is a `GET`.
public struct HTTPRequest: Sendable, Hashable {
    /// The method; always `GET`.
    public var method: String
    /// The full URL, already percent-encoded in canonical form.
    public var url: URL
    /// The request headers.
    public var headers: HTTPHeaders
    /// The timeout for this attempt, in seconds.
    public var timeout: TimeInterval

    /// Creates a request.
    public init(
        method: String = "GET", url: URL, headers: HTTPHeaders = [:], timeout: TimeInterval = 30
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.timeout = timeout
    }
}

/// An HTTP response as a transport received it.
public struct HTTPResponse: Sendable, Hashable {
    /// The status code.
    public var status: Int
    /// The response headers.
    public var headers: HTTPHeaders
    /// The body.
    public var body: Data

    /// Creates a response.
    public init(status: Int, headers: HTTPHeaders = [:], body: Data = Data()) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

/// HTTP header fields with case-insensitive names, in insertion order.
public struct HTTPHeaders: Sendable, Hashable, ExpressibleByDictionaryLiteral, Sequence {
    private var fields: [(name: String, value: String)]

    /// Creates an empty set of headers.
    public init() { fields = [] }

    /// Creates headers from name-value pairs.
    public init(dictionaryLiteral elements: (String, String)...) {
        fields = elements.map { ($0.0, $0.1) }
    }

    /// Creates headers from a dictionary.
    public init(_ dictionary: [String: String]) {
        fields = dictionary.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    /// The value of the field named `name` (any case), or `nil`.
    ///
    /// Setting replaces every field of that name; setting `nil` removes them.
    public subscript(name: String) -> String? {
        get { fields.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value }
        set {
            fields.removeAll { $0.name.caseInsensitiveCompare(name) == .orderedSame }
            if let newValue { fields.append((name, newValue)) }
        }
    }

    /// Iterates over the fields as `(name, value)` pairs.
    public func makeIterator() -> IndexingIterator<[(name: String, value: String)]> {
        fields.makeIterator()
    }

    /// Two header sets are equal when they hold the same fields, ignoring name case and order.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.normalized == rhs.normalized
    }

    /// Hashes the fields, ignoring name case and order.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(normalized)
    }

    private var normalized: [String: String] {
        Dictionary(
            fields.map { ($0.name.lowercased(), $0.value) }, uniquingKeysWith: { _, last in last })
    }

    /// The fields as a dictionary keyed by the names as sent.
    public var dictionary: [String: String] {
        Dictionary(fields.map { ($0.name, $0.value) }, uniquingKeysWith: { _, last in last })
    }
}
