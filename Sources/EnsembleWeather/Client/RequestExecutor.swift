// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// One API call, before it is sent.
struct Endpoint: Sendable {
    /// The OpenAPI `operationId`, for deprecation notices.
    var operation: String
    /// The path segments after the base URL, not yet encoded.
    var path: [String]
    var query = QueryString()
    /// A `security: []` route sent without the key (BEHAVIOR 3.2).
    var isOpenRoute = false
}

/// Sends endpoints: canonical URL, credentials, redirects, retries, the ETag
/// cache, deprecation notices and error mapping.
struct RequestExecutor: Sendable {
    static let maximumRedirects = 5
    static let maximumBodyBytes = URLSessionTransport.defaultMaximumBodyBytes
    static let maximumRetryAfter: TimeInterval = 60

    let configuration: EnsembleWeatherClient.Configuration
    let lastRateLimit: Locked<RateLimit?>

    // MARK: - Sending

    func send(_ endpoint: Endpoint) async throws -> (Data, ResponseMetadata) {
        let url = try makeURL(endpoint)
        let key =
            endpoint.isOpenRoute && !configuration.sendsKeyOnOpenRoutes ? nil : configuration.apiKey
        var attempt = 0
        while true {
            attempt += 1
            do {
                return try await sendFollowingRedirects(url: url, key: key, endpoint: endpoint)
            } catch let failure as RetryableFailure {
                guard attempt <= configuration.maxRetries,
                    let delay = retryDelay(for: failure, retry: attempt)
                else { throw failure.error }
                try await configuration.clock.sleep(seconds: delay)
            }
        }
    }

    private func sendFollowingRedirects(url start: URL, key startKey: String?, endpoint: Endpoint)
        async throws -> (Data, ResponseMetadata)
    {
        var url = start
        var key = startKey
        var redirects = 0
        while true {
            let cacheKey = Self.cacheKey(url: url, apiKey: key)
            let cached = await configuration.cache?.entry(forKey: cacheKey)
            if let cached, cached.maxAge > 0,
                configuration.clock.now.timeIntervalSince(cached.storedAt) < cached.maxAge
            {
                let headers = HTTPHeaders(cached.headers)
                return (cached.body, metadata(status: 200, headers: headers, cacheStatus: .fresh))
            }

            var headers: HTTPHeaders = [
                "Accept": "application/json",
                "User-Agent": userAgent,
            ]
            if let key { headers["X-API-Key"] = key }
            if let etag = cached?.etag { headers["If-None-Match"] = etag }
            let request = HTTPRequest(url: url, headers: headers, timeout: configuration.timeout)

            let response: HTTPResponse
            do {
                response = try await configuration.transport.send(request)
            } catch let error as CancellationError {
                throw error
            } catch let error as EnsembleWeatherError {
                throw error
            } catch {
                throw connectionFailure(error)
            }
            if Task.isCancelled { throw CancellationError() }
            guard response.body.count <= Self.maximumBodyBytes else {
                throw EnsembleWeatherError.invalidResponse(
                    "The response body is larger than the \(Self.maximumBodyBytes)-byte bound.",
                    status: response.status)
            }
            if let rateLimit = RateLimit(headers: response.headers) {
                lastRateLimit.withLock { $0 = rateLimit }
            }
            if let notice = DeprecationNotice(
                operation: endpoint.operation, headers: response.headers)
            {
                configuration.deprecationReporter.report(notice)
            }

            switch response.status {
            case 301, 302, 303, 307, 308:
                guard let location = response.headers["Location"],
                    let next = URL(string: location, relativeTo: url)?.absoluteURL
                else {
                    throw EnsembleWeatherError.invalidResponse(
                        "A \(response.status) redirect without a usable Location.",
                        status: response.status)
                }
                redirects += 1
                guard redirects <= Self.maximumRedirects else {
                    throw EnsembleWeatherError.invalidResponse(
                        "More than \(Self.maximumRedirects) redirects.", status: response.status)
                }
                if !Self.isSameOrigin(next, url) { key = nil }
                url = next
                continue
            case 304:
                guard var cached else {
                    throw EnsembleWeatherError.invalidResponse(
                        "A 304 Not Modified with no cached response to reuse.", status: 304)
                }
                var merged = HTTPHeaders(cached.headers)
                for (name, value) in response.headers { merged[name] = value }
                let control = CacheControl(merged["Cache-Control"])
                if control.noStore {
                    await configuration.cache?.removeEntry(forKey: cacheKey)
                } else {
                    cached.headers = merged.dictionary
                    cached.etag = response.headers["ETag"] ?? cached.etag
                    cached.storedAt = configuration.clock.now
                    cached.maxAge = control.maxAge
                    await configuration.cache?.store(cached, forKey: cacheKey)
                }
                return (
                    cached.body, metadata(status: 304, headers: merged, cacheStatus: .revalidated)
                )
            case 200..<300:
                await storeIfCacheable(response, key: cacheKey)
                return (response.body, metadata(status: response.status, headers: response.headers))
            default:
                let error = apiError(from: response)
                if Self.retryableStatuses.contains(response.status) {
                    throw RetryableFailure(error: error, retryAfter: error.retryAfter)
                }
                throw error
            }
        }
    }

    // MARK: - URLs and credentials

    func makeURL(_ endpoint: Endpoint) throws -> URL {
        var base = configuration.baseURL.absoluteString
        while base.hasSuffix("/") { base.removeLast() }
        var text =
            base + "/" + endpoint.path.map { PercentEncoding.encode($0) }.joined(separator: "/")
        let query = endpoint.query.encoded
        if !query.isEmpty { text += "?" + query }
        guard let url = URL(string: text) else {
            throw EnsembleWeatherError.usage("Could not build a URL from the base URL \(base).")
        }
        return url
    }

    var userAgent: String {
        guard let suffix = configuration.userAgentSuffix, !suffix.isEmpty else {
            return EnsembleWeatherVersion.userAgent
        }
        return EnsembleWeatherVersion.userAgent + " " + suffix
    }

    static func isSameOrigin(_ lhs: URL, _ rhs: URL) -> Bool {
        lhs.scheme?.lowercased() == rhs.scheme?.lowercased()
            && lhs.host?.lowercased() == rhs.host?.lowercased() && lhs.port == rhs.port
    }

    /// The full URL plus a SHA-256 digest of the key (never the key itself).
    static func cacheKey(url: URL, apiKey: String?) -> String {
        url.absoluteString + " "
            + (apiKey.map { "key:" + SHA256.hexDigest(of: Array($0.utf8)) } ?? "anonymous")
    }

    // MARK: - Caching

    private func storeIfCacheable(_ response: HTTPResponse, key: String) async {
        guard let cache = configuration.cache, response.status == 200 else { return }
        let control = CacheControl(response.headers["Cache-Control"])
        let etag = response.headers["ETag"]
        if control.noStore {
            await cache.removeEntry(forKey: key)
            return
        }
        guard etag != nil || control.maxAge > 0 else { return }
        await cache.store(
            CachedResponse(
                body: response.body, headers: response.headers.dictionary, etag: etag,
                storedAt: configuration.clock.now, maxAge: control.maxAge),
            forKey: key)
    }

    // MARK: - Metadata and errors

    private func metadata(
        status: Int, headers: HTTPHeaders, cacheStatus: ResponseMetadata.CacheStatus = .network
    ) -> ResponseMetadata {
        ResponseMetadata(
            status: status, headers: headers, rateLimit: RateLimit(headers: headers),
            requestID: headers["X-Request-Id"], etag: headers["ETag"], cacheStatus: cacheStatus)
    }

    static let retryableStatuses: Set<Int> = [429, 502, 503, 504]

    func apiError(from response: HTTPResponse) -> EnsembleWeatherError {
        let body = try? JSONDecoder().decode(ErrorBody.self, from: response.body)
        let code = body.map { ErrorCode(rawValue: $0.error) }
        let category =
            code.flatMap(EnsembleWeatherError.category(forCode:))
            ?? EnsembleWeatherError.category(forStatus: response.status)
        let message =
            body?.message
            ?? HTTPURLResponseText.reason(response.status)
        var retryAfter: TimeInterval?
        if response.status == 429 || response.status == 503 || response.status == 504 {
            retryAfter = response.headers["Retry-After"].flatMap {
                RetryAfter.seconds($0, now: configuration.clock.now)
            }
        }
        return EnsembleWeatherError(
            category: category, status: response.status, code: code, message: redact(message),
            requestID: body?.requestID ?? response.headers["X-Request-Id"],
            docURL: body?.docURL.flatMap(URL.init(string:)), parameter: body?.parameter,
            nearestLocation: body?.nearestLocation, retryAfter: retryAfter,
            rateLimit: RateLimit(headers: response.headers))
    }

    private func connectionFailure(_ error: any Error) -> any Error {
        let urlError = error as? URLError
        if urlError?.code == .cancelled, Task.isCancelled { return CancellationError() }
        let wrapped = EnsembleWeatherError(
            category: .connection,
            message: redact(
                "No response from the API: \(urlError.map { "\($0.code.rawValue) " } ?? "")"
                    + (error as NSError).localizedDescription))
        if let code = urlError?.code, Self.tlsFailures.contains(code) { return wrapped }
        return RetryableFailure(error: wrapped, retryAfter: nil)
    }

    static let tlsFailures: Set<URLError.Code> = [
        .serverCertificateUntrusted, .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot,
        .serverCertificateNotYetValid, .clientCertificateRejected, .clientCertificateRequired,
        .secureConnectionFailed,
    ]

    /// Removes the configured key from text that may reach an error message.
    func redact(_ text: String) -> String {
        guard let key = configuration.apiKey, !key.isEmpty else { return text }
        return text.replacingOccurrences(of: key, with: "<redacted>")
    }

    // MARK: - Retries

    /// The delay before retry `retry` (1-based), or `nil` when the failure
    /// must not be retried (a `Retry-After` over 60 s).
    func retryDelay(for failure: RetryableFailure, retry: Int) -> TimeInterval? {
        if let retryAfter = failure.retryAfter {
            return retryAfter > Self.maximumRetryAfter ? nil : retryAfter
        }
        let cap = min(8, 0.5 * pow(2, Double(retry - 1)))
        return min(max(configuration.jitter(), 0), 1) * cap
    }
}

/// A failure the executor may retry, carrying the error to throw if it does not.
struct RetryableFailure: Error {
    let error: any Error
    let retryAfter: TimeInterval?
}

/// The `Cache-Control` directives a private cache acts on.
struct CacheControl {
    var noStore = false
    var maxAge: TimeInterval = 0

    init(_ header: String?) {
        guard let header else { return }
        for directive in header.split(separator: ",") {
            let parts = directive.split(separator: "=", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces).lowercased()
            }
            switch parts.first {
            case "no-store": noStore = true
            case "no-cache": maxAge = 0
            case "max-age":
                if parts.count == 2,
                    let seconds = TimeInterval(
                        parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
                {
                    maxAge = max(0, seconds)
                }
            default: break
            }
        }
        if header.lowercased().contains("no-cache") { maxAge = 0 }
    }
}

/// `Retry-After` parsing: delta-seconds or an HTTP-date.
enum RetryAfter {
    static func seconds(_ value: String, now: Date) -> TimeInterval? {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if let seconds = TimeInterval(trimmed), seconds >= 0 { return seconds }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        guard let date = formatter.date(from: trimmed) else { return nil }
        return max(0, date.timeIntervalSince(now))
    }
}

/// Reason phrases for errors whose body carries no message.
enum HTTPURLResponseText {
    static func reason(_ status: Int) -> String {
        switch status {
        case 400: "Bad request."
        case 401: "Unauthorized."
        case 403: "Forbidden."
        case 404: "Not found."
        case 410: "Gone."
        case 429: "Too many requests."
        case 500: "Internal server error."
        case 502: "Bad gateway."
        case 503: "Service unavailable."
        case 504: "Gateway timeout."
        default: "HTTP \(status)."
        }
    }
}
