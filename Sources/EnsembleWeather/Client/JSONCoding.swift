// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The JSON coders for API bodies: RFC 3339 timestamps, with or without fractional seconds.
///
/// Decoding is into concrete types only.
enum JSONCoding {
    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = parseTimestamp(text) else {
                throw DecodingError.dataCorruptedError(
                    in: container, debugDescription: "Not an RFC 3339 timestamp: \(text)")
            }
            return date
        }
        return decoder
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatTimestamp(date))
        }
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    static func parseTimestamp(_ text: String) -> Date? {
        if let date = try? Date(text, strategy: .iso8601) { return date }
        return try? Date(
            text, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }

    static func formatTimestamp(_ date: Date) -> String {
        let whole = date.timeIntervalSince1970.rounded(.down) == date.timeIntervalSince1970
        return whole
            ? date.formatted(.iso8601)
            : date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }

    /// Decodes `body`, reporting a failure as an invalid-response error.
    static func decode<Value: Decodable>(_ type: Value.Type, from body: Data, status: Int) throws
        -> Value
    {
        do {
            return try decoder().decode(type, from: body)
        } catch {
            throw EnsembleWeatherError.invalidResponse(
                "The response is not a valid \(type): \(describe(error))", status: status)
        }
    }

    private static func describe(_ error: any Error) -> String {
        guard let error = error as? DecodingError else { return "malformed JSON." }
        switch error {
        case .keyNotFound(let key, let context):
            return "missing '\(key.stringValue)' at \(path(context))."
        case .typeMismatch(_, let context), .valueNotFound(_, let context):
            return "unexpected value at \(path(context))."
        case .dataCorrupted(let context):
            return "\(context.debugDescription) at \(path(context))."
        @unknown default:
            return "malformed JSON."
        }
    }

    private static func path(_ context: DecodingError.Context) -> String {
        let path = context.codingPath.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }
            .joined()
        return path.isEmpty ? "the top level" : path
    }
}
