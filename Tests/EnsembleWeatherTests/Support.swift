// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation
import Testing

@testable import EnsembleWeather

/// The repository root, found from this file's path.
let repositoryRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// The pinned spec's directory.
let specDirectory = repositoryRoot.appendingPathComponent("spec")

/// A transport that answers from a queue and records what was sent.
final class MockTransport: HTTPTransport {
    private let queue: Locked<[Result<HTTPResponse, any Error>]>
    private let sent = Locked<[HTTPRequest]>([])

    init(_ responses: [HTTPResponse]) {
        queue = Locked(responses.map { .success($0) })
    }

    init(results: [Result<HTTPResponse, any Error>]) {
        queue = Locked(results)
    }

    var requests: [HTTPRequest] { sent.withLock { $0 } }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        sent.withLock { $0.append(request) }
        let next = queue.withLock { $0.isEmpty ? nil : $0.removeFirst() }
        guard let next else {
            throw URLError(.resourceUnavailable)
        }
        return try next.get()
    }
}

/// A clock that never sleeps and records the delays asked for.
final class FakeClock: RetryClock {
    private let recorded = Locked<[TimeInterval]>([])
    let now = Date(timeIntervalSince1970: 1_794_700_800)  // 2026-11-15T00:00:00Z

    var sleeps: [TimeInterval] { recorded.withLock { $0 } }

    func sleep(seconds: TimeInterval) async throws {
        recorded.withLock { $0.append(seconds) }
    }
}

/// Collects deprecation notices.
final class NoticeCollector: Sendable {
    private let collected = Locked<[DeprecationNotice]>([])
    var notices: [DeprecationNotice] { collected.withLock { $0 } }
    func add(_ notice: DeprecationNotice) { collected.withLock { $0.append(notice) } }
}

/// A test configuration: no environment, a mock transport, a fake clock and
/// jitter pinned to its upper bound.
func testConfiguration(
    apiKey: String? = nil, transport: any HTTPTransport, clock: FakeClock = FakeClock(),
    notices: NoticeCollector = NoticeCollector()
) -> EnsembleWeatherClient.Configuration {
    var configuration = EnsembleWeatherClient.Configuration(apiKey: apiKey, environment: [:])
    configuration.transport = transport
    configuration.clock = clock
    configuration.jitter = { 1.0 }
    configuration.deprecationReporter = DeprecationReporter { notices.add($0) }
    return configuration
}

/// A JSON response from a spec vector body file.
func vectorBody(_ name: String) throws -> Data {
    try Data(contentsOf: specDirectory.appendingPathComponent("vectors/bodies/\(name)"))
}

func jsonResponse(_ status: Int, body: Data, headers: HTTPHeaders = [:]) -> HTTPResponse {
    var headers = headers
    headers["Content-Type"] = "application/json"
    return HTTPResponse(status: status, headers: headers, body: body)
}

extension JSONValue {
    subscript(key: String) -> JSONValue? {
        if case .object(let object) = self { return object[key] }
        return nil
    }

    var string: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var number: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var bool: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var array: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    var object: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    /// The value at a dot and `[i]` path, such as `probabilities[0].threshold`.
    func value(at path: String) -> JSONValue? {
        var current: JSONValue? = self
        for component in path.split(separator: ".") {
            var name = Substring(component)
            var indices: [Int] = []
            while let open = name.lastIndex(of: "["), name.hasSuffix("]") {
                guard
                    let index = Int(
                        name[name.index(after: open)..<name.index(before: name.endIndex)])
                else {
                    break
                }
                indices.insert(index, at: 0)
                name = name[..<open]
            }
            if !name.isEmpty { current = current?[String(name)] }
            for index in indices {
                guard let array = current?.array, index < array.count else { return nil }
                current = array[index]
            }
        }
        if case .null = current { return nil }
        return current
    }

    /// Decodes JSON text.
    static func parse(_ data: Data) throws -> JSONValue {
        try JSONDecoder().decode(JSONValue.self, from: data)
    }

    /// The JSON form of an encodable value, encoded as the SDK encodes models.
    static func encoding<Value: Encodable>(_ value: Value) throws -> JSONValue {
        try parse(try JSONCoding.encoder().encode(value))
    }
}

/// Compares JSON values numerically, treating `null` and absence alike.
func jsonEquivalent(_ lhs: JSONValue?, _ rhs: JSONValue?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil), (nil, .null?), (.null?, nil), (.null?, .null?): return true
    case (.number(let a)?, .number(let b)?): return a == b
    case (.object(let a)?, .object(let b)?):
        for key in Set(a.keys).union(b.keys) where !jsonEquivalent(a[key], b[key]) { return false }
        return true
    case (.array(let a)?, .array(let b)?):
        return a.count == b.count && zip(a, b).allSatisfy { jsonEquivalent($0, $1) }
    default: return lhs == rhs
    }
}

/// The first path where two JSON values differ, for test failure messages.
func firstDifference(_ lhs: JSONValue?, _ rhs: JSONValue?, path: String = "$") -> String? {
    if jsonEquivalent(lhs, rhs) { return nil }
    switch (lhs, rhs) {
    case (.object(let a)?, .object(let b)?):
        for key in Set(a.keys).union(b.keys).sorted() {
            if let difference = firstDifference(a[key], b[key], path: "\(path).\(key)") {
                return difference
            }
        }
    case (.array(let a)?, .array(let b)?) where a.count == b.count:
        for (index, pair) in zip(a, b).enumerated() {
            if let difference = firstDifference(pair.0, pair.1, path: "\(path)[\(index)]") {
                return difference
            }
        }
    default: break
    }
    return "\(path): \(String(describing: lhs)) vs \(String(describing: rhs))"
}
