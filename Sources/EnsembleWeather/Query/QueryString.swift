// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// Builds a canonical query string (BEHAVIOR 3.1): parameters at their
/// route default are left out, names are sorted, values are RFC 3986
/// percent-encoded, and `prob`/`totals` keep `:` and `,` literal.
struct QueryString: Sendable {
    private var items: [(name: String, value: String)] = []

    /// Adds a string parameter unless it is `nil` or equal to `defaultValue`.
    mutating func add(_ name: String, _ value: String?, default defaultValue: String? = nil) {
        guard let value, value != defaultValue else { return }
        items.append((name, PercentEncoding.encode(value)))
    }

    /// Adds a Boolean parameter unless it is `nil` or equal to `defaultValue`.
    mutating func add(_ name: String, _ value: Bool?, default defaultValue: Bool) {
        guard let value, value != defaultValue else { return }
        items.append((name, value ? "true" : "false"))
    }

    /// Adds an integer parameter unless it is `nil` or equal to `defaultValue`.
    mutating func add(_ name: String, _ value: Int?, default defaultValue: Int? = nil) {
        guard let value, value != defaultValue else { return }
        items.append((name, String(value)))
    }

    /// Adds a number parameter, written as the shortest decimal that
    /// round-trips, unless it is `nil` or equal to `defaultValue`.
    mutating func add(_ name: String, _ value: Double?, default defaultValue: Double? = nil) {
        guard let value, value != defaultValue else { return }
        items.append((name, PercentEncoding.encode(DecimalFormatting.shortest(value))))
    }

    /// Adds a comma-separated list, each element encoded, the commas literal
    /// (the API's list syntax), unless the list is `nil` or empty.
    mutating func addList(_ name: String, _ values: [String]?) {
        guard let values, !values.isEmpty else { return }
        items.append((name, values.map { PercentEncoding.encode($0) }.joined(separator: ",")))
    }

    /// Adds one parameter per value (the API's `explode` form), unless the
    /// list is `nil` or empty.
    mutating func addRepeated(_ name: String, _ values: [String]?) {
        guard let values else { return }
        for value in Set(values).sorted() {
            items.append((name, PercentEncoding.encode(value)))
        }
    }

    /// Adds a value the caller has already put in canonical wire form, with
    /// `:` and `,` literal (the `prob` and `totals` syntax).
    mutating func addWireValue(_ name: String, _ value: String?) {
        guard let value, !value.isEmpty else { return }
        items.append((name, PercentEncoding.encode(value, keeping: [":", ","])))
    }

    /// The query string, without a leading `?`; empty when no parameter is sent.
    var encoded: String {
        items.enumerated()
            .sorted { lhs, rhs in
                lhs.element.name == rhs.element.name
                    ? lhs.offset < rhs.offset : lhs.element.name < rhs.element.name
            }
            .map { "\($0.element.name)=\($0.element.value)" }
            .joined(separator: "&")
    }
}

/// RFC 3986 percent-encoding: unreserved characters as they are, every other
/// byte of the UTF-8 form as `%XX` in uppercase hex.
enum PercentEncoding {
    private static let hex = Array("0123456789ABCDEF".utf8)

    static func encode(_ value: String, keeping extra: Set<Character> = []) -> String {
        let keptBytes = Set(extra.compactMap(\.asciiValue))
        var bytes: [UInt8] = []
        bytes.reserveCapacity(value.utf8.count)
        for byte in value.utf8 {
            if isUnreserved(byte) || keptBytes.contains(byte) {
                bytes.append(byte)
            } else {
                bytes.append(UInt8(ascii: "%"))
                bytes.append(hex[Int(byte >> 4)])
                bytes.append(hex[Int(byte & 0x0F)])
            }
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    private static func isUnreserved(_ byte: UInt8) -> Bool {
        switch byte {
        case UInt8(ascii: "A")...UInt8(ascii: "Z"), UInt8(ascii: "a")...UInt8(ascii: "z"),
            UInt8(ascii: "0")...UInt8(ascii: "9"), UInt8(ascii: "-"), UInt8(ascii: "."),
            UInt8(ascii: "_"), UInt8(ascii: "~"):
            true
        default:
            false
        }
    }
}

/// Number formatting for the wire.
enum DecimalFormatting {
    /// The shortest decimal that round-trips, never with an exponent, and
    /// without a trailing `.0` (BEHAVIOR 3.1 rule 6).
    static func shortest(_ value: Double) -> String {
        precondition(value.isFinite, "a query number must be finite")
        if value == 0 { return "0" }
        var text = value.description
        if let exponentIndex = text.firstIndex(where: { $0 == "e" || $0 == "E" }) {
            text = expand(
                mantissa: String(text[..<exponentIndex]),
                exponent: Int(text[text.index(after: exponentIndex)...]) ?? 0)
        }
        if text.hasSuffix(".0") { text.removeLast(2) }
        return text
    }

    /// Writes `mantissa × 10^exponent` in plain positional notation.
    private static func expand(mantissa: String, exponent: Int) -> String {
        var digits = mantissa
        let negative = digits.hasPrefix("-")
        if negative { digits.removeFirst() }
        let parts = digits.split(separator: ".", omittingEmptySubsequences: false)
        let integerPart = String(parts[0])
        let fractionPart = parts.count > 1 ? String(parts[1]) : ""
        let allDigits = integerPart + fractionPart
        let pointPosition = integerPart.count + exponent
        var result: String
        if pointPosition <= 0 {
            result = "0." + String(repeating: "0", count: -pointPosition) + allDigits
        } else if pointPosition >= allDigits.count {
            result = allDigits + String(repeating: "0", count: pointPosition - allDigits.count)
        } else {
            let index = allDigits.index(allDigits.startIndex, offsetBy: pointPosition)
            result = allDigits[..<index] + "." + allDigits[index...]
        }
        while result.contains("."), result.hasSuffix("0") { result.removeLast() }
        if result.hasSuffix(".") { result.removeLast() }
        while result.count > 1, result.hasPrefix("0"), !result.hasPrefix("0.") {
            result.removeFirst()
        }
        return negative ? "-" + result : result
    }

    /// `value` rounded half away from zero to `decimals` places, in IEEE-754
    /// doubles exactly as the server rounds (BEHAVIOR 4), as a scaled integer:
    /// the result is `scaled / 10^decimals`.
    static func roundedScaled(_ value: Double, decimals: Int) -> Int64? {
        let scale = power(decimals)
        let scaled = (value * scale).rounded(.toNearestOrAwayFromZero)
        guard scaled.isFinite, abs(scaled) < 9.0e15 else { return nil }
        return Int64(scaled)
    }

    /// A scaled integer written with exactly `decimals` places; `-0` is `0`.
    static func fixed(scaled: Int64, decimals: Int) -> String {
        let negative = scaled < 0
        let magnitude = String(scaled.magnitude)
        guard decimals > 0 else { return (negative ? "-" : "") + magnitude }
        let padded =
            magnitude.count <= decimals
            ? String(repeating: "0", count: decimals - magnitude.count + 1) + magnitude
            : magnitude
        let split = padded.index(padded.endIndex, offsetBy: -decimals)
        return (negative ? "-" : "") + padded[..<split] + "." + padded[split...]
    }

    static func power(_ decimals: Int) -> Double {
        var result = 1.0
        for _ in 0..<decimals { result *= 10 }
        return result
    }
}
