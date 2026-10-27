// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// The default transport: `URLSession`, with redirects handed back to the
/// client, no `URLCache`, no cookies, and a bound on the response body.
///
/// TLS certificate validation is the system's own and cannot be turned off.
public final class URLSessionTransport: HTTPTransport {
    /// The largest response body accepted, in bytes: 64 MiB.
    public static let defaultMaximumBodyBytes = 64 * 1024 * 1024

    private let session: URLSession
    let delegate: SessionDelegate

    /// Creates a transport.
    ///
    /// - Parameter maximumBodyBytes: The largest response body accepted; a
    ///   larger body ends the request with an
    ///   ``EnsembleWeatherError/Category/invalidResponse`` error instead of
    ///   using unbounded memory. At most 64 MiB.
    public convenience init(maximumBodyBytes: Int = URLSessionTransport.defaultMaximumBodyBytes) {
        self.init(configuration: .ephemeral, maximumBodyBytes: maximumBodyBytes)
    }

    /// Creates a transport on `configuration` (tests use it to install a `URLProtocol`).
    init(configuration: URLSessionConfiguration, maximumBodyBytes: Int) {
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        delegate = SessionDelegate(
            maximumBodyBytes: min(maximumBodyBytes, Self.defaultMaximumBodyBytes))
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    deinit {
        session.finishTasksAndInvalidate()
    }

    /// Sends `request` with `URLSession`.
    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url, timeoutInterval: request.timeout)
        urlRequest.httpMethod = request.method
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        for (name, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }
        let taskBox = Locked<URLSessionDataTask?>(nil)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let task = session.dataTask(with: urlRequest)
                delegate.register(task, continuation: continuation)
                taskBox.withLock { $0 = task }
                task.resume()
                if Task.isCancelled { task.cancel() }
            }
        } onCancel: {
            taskBox.withLock { $0?.cancel() }
        }
    }
}

/// Collects each task's response under a size bound and hands redirects back.
final class SessionDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private struct Pending {
        var continuation: CheckedContinuation<HTTPResponse, any Error>
        var response: HTTPURLResponse?
        var body = Data()
        var overflowed = false
    }

    let maximumBodyBytes: Int
    private let pending = Locked<[Int: Pending]>([:])

    init(maximumBodyBytes: Int) {
        self.maximumBodyBytes = maximumBodyBytes
    }

    func register(
        _ task: URLSessionTask, continuation: CheckedContinuation<HTTPResponse, any Error>
    ) {
        pending.withLock { $0[task.taskIdentifier] = Pending(continuation: continuation) }
    }

    func urlSession(
        _ session: URLSession, task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }

    func urlSession(
        _ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        let tooLarge = response.expectedContentLength > Int64(maximumBodyBytes)
        pending.withLock {
            $0[dataTask.taskIdentifier]?.response = response as? HTTPURLResponse
            if tooLarge { $0[dataTask.taskIdentifier]?.overflowed = true }
        }
        completionHandler(tooLarge ? .cancel : .allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let overflow = pending.withLock { state -> Bool in
            guard var entry = state[dataTask.taskIdentifier] else { return false }
            if entry.body.count + data.count > maximumBodyBytes {
                entry.overflowed = true
                entry.body = Data()
            } else {
                entry.body.append(data)
            }
            state[dataTask.taskIdentifier] = entry
            return entry.overflowed
        }
        if overflow { dataTask.cancel() }
    }

    func urlSession(
        _ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?
    ) {
        guard let entry = pending.withLock({ $0.removeValue(forKey: task.taskIdentifier) }) else {
            return
        }
        if entry.overflowed {
            entry.continuation.resume(
                throwing: EnsembleWeatherError.invalidResponse(
                    "The response body is larger than the \(maximumBodyBytes)-byte bound.",
                    status: entry.response?.statusCode))
        } else if let error {
            entry.continuation.resume(throwing: error)
        } else if let response = entry.response ?? (task.response as? HTTPURLResponse) {
            var headers = HTTPHeaders()
            for (name, value) in response.allHeaderFields {
                if let name = name as? String { headers[name] = "\(value)" }
            }
            entry.continuation.resume(
                returning: HTTPResponse(
                    status: response.statusCode, headers: headers, body: entry.body))
        } else {
            entry.continuation.resume(throwing: URLError(.badServerResponse))
        }
    }
}

/// A value guarded by a lock.
final class Locked<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) { self.value = value }

    func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}
