// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

@testable import EnsembleWeather

/// A small YAML reader for the block-style subset the spec's OpenAPI file uses (PyYAML-style
/// output): block mappings and sequences, plain, quoted and literal (`|`) scalars, and one-line
/// flow collections.
///
/// It keeps the test target free of dependencies; `MiniYAMLTests` checks it against the whole spec
/// file.
struct MiniYAML {
    enum Failure: Error, CustomStringConvertible {
        case syntax(line: Int, String)
        var description: String {
            switch self {
            case .syntax(let line, let message): "YAML line \(line + 1): \(message)"
            }
        }
    }

    private struct Line {
        let number: Int
        let indent: Int
        let text: String  // without indentation
    }

    private var lines: [Line] = []
    private var raw: [String] = []
    private var position = 0

    static func parse(_ text: String) throws -> JSONValue {
        var parser = MiniYAML()
        parser.raw = text.components(separatedBy: "\n")
        for (number, line) in parser.raw.enumerated() {
            let trimmed = line.drop { $0 == " " }
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            parser.lines.append(
                Line(number: number, indent: line.count - trimmed.count, text: String(trimmed)))
        }
        guard !parser.lines.isEmpty else { return .null }
        return try parser.parseNode(indent: parser.lines[0].indent)
    }

    // MARK: - Nodes

    private mutating func parseNode(indent: Int) throws -> JSONValue {
        let line = lines[position]
        if line.text == "-" || line.text.hasPrefix("- ") {
            return try parseSequence(indent: line.indent)
        }
        return try parseMapping(indent: line.indent)
    }

    private mutating func parseSequence(indent: Int) throws -> JSONValue {
        var items: [JSONValue] = []
        while position < lines.count, lines[position].indent == indent,
            lines[position].text == "-" || lines[position].text.hasPrefix("- ")
        {
            let line = lines[position]
            let rest = line.text == "-" ? "" : String(line.text.dropFirst(2))
            if rest.isEmpty {
                position += 1
                items.append(
                    position < lines.count && lines[position].indent > indent
                        ? try parseNode(indent: lines[position].indent) : .null)
            } else if splitKey(rest) != nil && !rest.hasPrefix("{") && !rest.hasPrefix("[") {
                // A compact mapping: "- key: value" continues at indent + 2.
                let inner = indent + 2
                lines[position] = Line(number: line.number, indent: inner, text: rest)
                items.append(try parseMapping(indent: inner))
            } else {
                position += 1
                items.append(try scalarOrFlow(rest, line: line, parentIndent: indent))
            }
        }
        return .array(items)
    }

    private mutating func parseMapping(indent: Int) throws -> JSONValue {
        var object: [String: JSONValue] = [:]
        while position < lines.count, lines[position].indent == indent {
            let line = lines[position]
            if line.text.hasPrefix("- ") { break }
            guard let (key, rest) = splitKey(line.text) else {
                throw Failure.syntax(line: line.number, "expected 'key: value', got '\(line.text)'")
            }
            position += 1
            if rest.isEmpty {
                if position < lines.count, lines[position].indent > indent {
                    object[key] = try parseNode(indent: lines[position].indent)
                } else if position < lines.count, lines[position].indent == indent,
                    lines[position].text.hasPrefix("- ")
                {
                    object[key] = try parseSequence(indent: indent)
                } else {
                    object[key] = .null
                }
            } else {
                object[key] = try scalarOrFlow(rest, line: line, parentIndent: indent)
            }
        }
        return .object(object)
    }

    // MARK: - Scalars

    private mutating func scalarOrFlow(_ text: String, line: Line, parentIndent: Int) throws
        -> JSONValue
    {
        if text == "|" || text == "|-" || text == "|+" || text == ">" || text == ">-" {
            return .string(blockScalar(style: text, parentIndent: parentIndent, after: line.number))
        }
        if text.hasPrefix("'") || text.hasPrefix("\"") {
            return .string(try quoted(text, line: line, parentIndent: parentIndent))
        }
        if text.hasPrefix("[") || text.hasPrefix("{") {
            var index = text.startIndex
            return try flow(text, &index, line: line.number)
        }
        // A plain scalar may continue on more-indented lines.
        var value = stripComment(text)
        while position < lines.count, lines[position].indent > parentIndent,
            splitKey(lines[position].text) == nil, !lines[position].text.hasPrefix("- ")
        {
            value += " " + stripComment(lines[position].text)
            position += 1
        }
        return plain(value)
    }

    private func stripComment(_ text: String) -> String {
        if let range = text.range(of: " #") { return String(text[..<range.lowerBound]) }
        return text
    }

    private func plain(_ text: String) -> JSONValue {
        switch text {
        case "null", "~", "": return .null
        case "true", "True": return .bool(true)
        case "false", "False": return .bool(false)
        default:
            if text.range(
                of: #"^[-+]?(\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?$"#, options: .regularExpression)
                != nil,
                let number = Double(text)
            {
                return .number(number)
            }
            return .string(text)
        }
    }

    private mutating func quoted(_ start: String, line: Line, parentIndent: Int) throws -> String {
        let quote = start.first ?? "'"
        var text = String(start.dropFirst())
        var result = ""
        var pendingNewlines = 0
        while true {
            var index = text.startIndex
            while index < text.endIndex {
                let character = text[index]
                if quote == "'" && character == "'" {
                    let next = text.index(after: index)
                    if next < text.endIndex && text[next] == "'" {
                        result.append("'")
                        index = text.index(after: next)
                        continue
                    }
                    return result
                }
                if quote == "\"" && character == "\"" { return result }
                if quote == "\"" && character == "\\" {
                    let next = text.index(after: index)
                    guard next < text.endIndex else {
                        index = next
                        pendingNewlines = -1  // escaped line break: join without a space
                        break
                    }
                    switch text[next] {
                    case "n": result.append("\n")
                    case "t": result.append("\t")
                    case "\"": result.append("\"")
                    case "\\": result.append("\\")
                    case "/": result.append("/")
                    case "u":
                        let hexStart = text.index(after: next)
                        let hexEnd = text.index(hexStart, offsetBy: 4)
                        if let scalar = UInt32(text[hexStart..<hexEnd], radix: 16).flatMap(
                            Unicode.Scalar.init)
                        {
                            result.unicodeScalars.append(scalar)
                        }
                        index = hexEnd
                        continue
                    default: result.append(text[next])
                    }
                    index = text.index(after: next)
                    continue
                }
                result.append(character)
                index = text.index(after: index)
            }
            // The scalar continues on the next raw line (folded).
            guard position < lines.count else {
                throw Failure.syntax(line: line.number, "unterminated quote")
            }
            let continuation = lines[position]
            position += 1
            let gap =
                continuation.number
                - (position >= 2 ? lines[position - 2].number : continuation.number) - 1
            if pendingNewlines == -1 {
                pendingNewlines = 0
            } else if gap > 0 {
                result += String(repeating: "\n", count: gap)
            } else {
                result += " "
            }
            text = continuation.text
        }
    }

    private mutating func blockScalar(style: String, parentIndent: Int, after lineNumber: Int)
        -> String
    {
        var collected: [String] = []
        var blockIndent: Int?
        var rawIndex = lineNumber + 1
        while rawIndex < raw.count {
            let line = raw[rawIndex]
            let trimmed = line.drop { $0 == " " }
            let indent = line.count - trimmed.count
            if trimmed.isEmpty {
                collected.append("")
                rawIndex += 1
                continue
            }
            if indent <= parentIndent { break }
            if blockIndent == nil { blockIndent = indent }
            if indent < (blockIndent ?? indent) { break }
            collected.append(String(line.dropFirst(blockIndent ?? indent)))
            rawIndex += 1
        }
        while position < lines.count, lines[position].number < rawIndex { position += 1 }
        var trailing = 0
        while collected.last == "" {
            collected.removeLast()
            trailing += 1
        }
        var text: String
        if style.hasPrefix(">") {
            text = ""
            for (index, line) in collected.enumerated() {
                if index > 0 {
                    text +=
                        (line.isEmpty || collected[index - 1].isEmpty || line.hasPrefix(" "))
                        ? "\n" : " "
                }
                text += line
            }
        } else {
            text = collected.joined(separator: "\n")
        }
        if style.hasSuffix("-") { return text }
        if style.hasSuffix("+") { return text + String(repeating: "\n", count: trailing + 1) }
        return collected.isEmpty ? "" : text + "\n"
    }

    // MARK: - Flow collections (one line)

    private func flow(_ text: String, _ index: inout String.Index, line: Int) throws -> JSONValue {
        func skipSpaces() {
            while index < text.endIndex, text[index] == " " { index = text.index(after: index) }
        }
        skipSpaces()
        guard index < text.endIndex else { return .null }
        let opening = text[index]
        if opening == "[" || opening == "{" {
            let closing: Character = opening == "[" ? "]" : "}"
            index = text.index(after: index)
            var items: [JSONValue] = []
            var object: [String: JSONValue] = [:]
            while true {
                skipSpaces()
                guard index < text.endIndex else {
                    throw Failure.syntax(line: line, "unterminated flow")
                }
                if text[index] == closing {
                    index = text.index(after: index)
                    break
                }
                if opening == "{" {
                    let key = try flowScalar(text, &index, stops: [":"])
                    index = text.index(after: index)
                    object[key.string ?? ""] = try flow(text, &index, line: line)
                } else {
                    items.append(try flow(text, &index, line: line))
                }
                skipSpaces()
                if index < text.endIndex, text[index] == "," { index = text.index(after: index) }
            }
            return opening == "[" ? .array(items) : .object(object)
        }
        return try flowScalar(text, &index, stops: [",", "]", "}"])
    }

    private func flowScalar(_ text: String, _ index: inout String.Index, stops: Set<Character>)
        throws -> JSONValue
    {
        while index < text.endIndex, text[index] == " " { index = text.index(after: index) }
        if index < text.endIndex, text[index] == "'" || text[index] == "\"" {
            let quote = text[index]
            index = text.index(after: index)
            var value = ""
            while index < text.endIndex, text[index] != quote {
                value.append(text[index])
                index = text.index(after: index)
            }
            if index < text.endIndex { index = text.index(after: index) }
            return .string(value)
        }
        var value = ""
        while index < text.endIndex, !stops.contains(text[index]) {
            value.append(text[index])
            index = text.index(after: index)
        }
        return plain(value.trimmingCharacters(in: .whitespaces))
    }

    // MARK: - Keys

    /// Splits `key: rest` (or `key:`), with plain or quoted keys.
    private func splitKey(_ text: String) -> (String, String)? {
        if text.hasPrefix("'") || text.hasPrefix("\"") {
            let quote = text[text.startIndex]
            var index = text.index(after: text.startIndex)
            var key = ""
            while index < text.endIndex {
                if text[index] == quote {
                    let next = text.index(after: index)
                    if quote == "'", next < text.endIndex, text[next] == "'" {
                        key.append("'")
                        index = text.index(after: next)
                        continue
                    }
                    let after = text[next...]
                    if after == ":" { return (key, "") }
                    if after.hasPrefix(": ") {
                        return (
                            key, String(after.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                        )
                    }
                    return nil
                }
                key.append(text[index])
                index = text.index(after: index)
            }
            return nil
        }
        if text.hasPrefix("[") || text.hasPrefix("{") { return nil }
        if text.hasSuffix(":"), !text.dropLast().contains(": ") {
            let key = String(text.dropLast())
            return key.contains(" #") ? nil : (key, "")
        }
        guard let range = text.range(of: ": ") else { return nil }
        let key = String(text[..<range.lowerBound])
        if key.contains("#") && key.hasPrefix("#") { return nil }
        return (key, String(text[range.upperBound...]).trimmingCharacters(in: .whitespaces))
    }
}
