// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The one error type the SDK throws (besides `CancellationError` when the
/// calling task is cancelled).
///
/// Switch on ``category`` for the kind of failure, and read ``code`` for the
/// API's own error code, kept verbatim even when this SDK version does not
/// know it:
///
/// ```swift
/// do {
///     _ = try await client.forecast(latitude: 51.5, longitude: -0.1)
/// } catch let error as EnsembleWeatherError where error.category == .outsideCoverage {
///     print("Outside the forecast domain: \(error.message)")
/// }
/// ```
///
/// No error ever contains the API key: not in ``message``, not in its
/// description, and not in ``localizedDescription``.
public struct EnsembleWeatherError: Error, Sendable, Hashable {
    /// The kind of failure (BEHAVIOR 8).
    ///
    /// Mapped from the API's code first, then from the HTTP status when the code is unknown or
    /// absent.
    public enum Category: String, Sendable, Hashable, CaseIterable {
        /// The API key is missing, invalid or revoked (401).
        case authentication
        /// The key is valid but its tier does not allow this (403), for
        /// example `PRO_REQUIRED`.
        case permission
        /// The location or route does not exist (404, 410).
        case notFound
        /// The server rejected the request's parameters (400).
        case invalidRequest
        /// The point lies outside the forecast domain (`OUTSIDE_COVERAGE`).
        case outsideCoverage
        /// Over a rate budget (429).
        ///
        /// See ``EnsembleWeatherError/retryAfter``.
        case rateLimited
        /// The server could not answer (5xx), for example `FORECAST_UNAVAILABLE`.
        case unavailable
        /// No response arrived: DNS, TLS, a reset connection or a timeout.
        case connection
        /// The SDK refused the call before sending it: an invalid probability
        /// term, window or argument.
        case usage
        /// The response could not be read: malformed JSON, an unexpected
        /// shape, a body over the size bound, or too many redirects.
        case invalidResponse
    }

    /// The kind of failure.
    public var category: Category
    /// The HTTP status, when a response arrived.
    public var status: Int?
    /// The API's error code (`"OUTSIDE_COVERAGE"`), verbatim; `nil` when the
    /// body carried none.
    public var code: ErrorCode?
    /// A human-readable explanation, from the server when it sent one.
    public var message: String
    /// The request's id, for support requests: the body's `request_id`, else
    /// the response's `X-Request-Id` header.
    public var requestID: String?
    /// The code's explanation on the docs errors page (cause, fix, whether to
    /// retry), when the body carried one.
    public var docURL: URL?
    /// On a 400 about one query parameter, its name (`max_hours`, `prob`).
    public var parameter: String?
    /// On a coordinate request refused with `PRO_REQUIRED`: a named location
    /// near the point whose forecast needs no key.
    public var nearestLocation: NearestLocation?
    /// For a 429, 503 or 504 with `Retry-After`: the seconds to wait before retrying.
    public var retryAfter: TimeInterval?
    /// The rate-limit state the error response reported, if any.
    public var rateLimit: RateLimit?

    /// Creates an error.
    public init(
        category: Category,
        status: Int? = nil,
        code: ErrorCode? = nil,
        message: String,
        requestID: String? = nil,
        docURL: URL? = nil,
        parameter: String? = nil,
        nearestLocation: NearestLocation? = nil,
        retryAfter: TimeInterval? = nil,
        rateLimit: RateLimit? = nil
    ) {
        self.category = category
        self.status = status
        self.code = code
        self.message = message
        self.requestID = requestID
        self.docURL = docURL
        self.parameter = parameter
        self.nearestLocation = nearestLocation
        self.retryAfter = retryAfter
        self.rateLimit = rateLimit
    }

    static func usage(_ message: String) -> Self {
        Self(category: .usage, message: message)
    }

    static func invalidResponse(_ message: String, status: Int? = nil) -> Self {
        Self(category: .invalidResponse, status: status, message: message)
    }

    /// The category an error code maps to, if the code is a known one.
    static func category(forCode code: ErrorCode) -> Category? {
        switch code {
        case .invalidAPIKey, .unauthorized: .authentication
        case .proRequired: .permission
        case .locationNotFound, .notFound: .notFound
        case .badRequest, .invalidCoordinates, .invalidElevation, .elevationRequired:
            .invalidRequest
        case .outsideCoverage: .outsideCoverage
        case .tooManyRequests: .rateLimited
        case .forecastUnavailable, .timeout, .internalError, .databaseError, .authUnavailable:
            .unavailable
        default: nil
        }
    }

    /// The category an HTTP status maps to when the code does not decide it.
    static func category(forStatus status: Int) -> Category {
        switch status {
        case 401: .authentication
        case 403: .permission
        case 404, 410: .notFound
        case 429: .rateLimited
        case 500...599: .unavailable
        case 400...499: .invalidRequest
        default: .invalidResponse
        }
    }
}

extension EnsembleWeatherError: LocalizedError, CustomStringConvertible {
    /// A one-line description: category, status, code and message.
    public var errorDescription: String? { description }

    /// A one-line description: category, status, code and message.
    public var description: String {
        var parts = ["Ourea API error (\(category.rawValue)"]
        if let status { parts.append(", HTTP \(status)") }
        if let code { parts.append(", \(code.rawValue)") }
        if let parameter { parts.append(", param \(parameter)") }
        parts.append("): \(message)")
        if let requestID { parts.append(" [request \(requestID)]") }
        return parts.joined()
    }
}

/// An API error code, such as `OUTSIDE_COVERAGE`.
///
/// Codes are open: a code this SDK version does not list still compares and
/// prints as its raw string.
public struct ErrorCode: RawRepresentable, Sendable, Hashable, ExpressibleByStringLiteral,
    CustomStringConvertible
{
    /// The code as the API sent it.
    public let rawValue: String

    /// Creates a code from its raw string.
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Creates a code from a string literal.
    public init(stringLiteral value: String) { self.rawValue = value }

    /// The raw code.
    public var description: String { rawValue }

    /// `INVALID_API_KEY`: the key is not a valid, active key.
    public static let invalidAPIKey: Self = "INVALID_API_KEY"
    /// `UNAUTHORIZED`: credentials are required.
    public static let unauthorized: Self = "UNAUTHORIZED"
    /// `PRO_REQUIRED`: the request needs a Pro key.
    public static let proRequired: Self = "PRO_REQUIRED"
    /// `LOCATION_NOT_FOUND`: no such location.
    public static let locationNotFound: Self = "LOCATION_NOT_FOUND"
    /// `NOT_FOUND`: no such resource or route.
    public static let notFound: Self = "NOT_FOUND"
    /// `BAD_REQUEST`: a malformed or unknown parameter.
    public static let badRequest: Self = "BAD_REQUEST"
    /// `INVALID_COORDINATES`: a malformed latitude or longitude.
    public static let invalidCoordinates: Self = "INVALID_COORDINATES"
    /// `INVALID_ELEVATION`: elevation out of range.
    public static let invalidElevation: Self = "INVALID_ELEVATION"
    /// `ELEVATION_REQUIRED`: no terrain elevation for the point; pass one.
    public static let elevationRequired: Self = "ELEVATION_REQUIRED"
    /// `OUTSIDE_COVERAGE`: the point is outside the forecast domain (a 404).
    public static let outsideCoverage: Self = "OUTSIDE_COVERAGE"
    /// `TOO_MANY_REQUESTS`: over a rate budget.
    public static let tooManyRequests: Self = "TOO_MANY_REQUESTS"
    /// `FORECAST_UNAVAILABLE`: no forecast can be served yet.
    public static let forecastUnavailable: Self = "FORECAST_UNAVAILABLE"
    /// `TIMEOUT`: the server did not finish in time.
    public static let timeout: Self = "TIMEOUT"
    /// `INTERNAL_ERROR`: a server fault.
    public static let internalError: Self = "INTERNAL_ERROR"
    /// `DATABASE_ERROR`: a server storage fault.
    public static let databaseError: Self = "DATABASE_ERROR"
    /// `AUTH_UNAVAILABLE`: the server could not check the credentials just now (503).
    public static let authUnavailable: Self = "AUTH_UNAVAILABLE"
}
