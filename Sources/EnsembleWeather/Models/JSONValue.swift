// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// A free-form JSON value, for the few response fields whose shape the API
/// does not fix (catalog content bodies, ad configuration, external links).
public enum JSONValue: Sendable, Hashable {
    /// `null`.
    case null
    /// `true` or `false`.
    case bool(Bool)
    /// A number.
    case number(Double)
    /// A string.
    case string(String)
    /// An array.
    case array([JSONValue])
    /// An object.
    case object([String: JSONValue])
}

extension JSONValue: Codable {
    /// Decodes any JSON value.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }

    /// Encodes the value as JSON.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}
