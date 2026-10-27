// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation
import Testing

@testable import EnsembleWeather

@Suite("MiniYAML")
struct MiniYAMLTests {
    @Test("Parses the block-style constructs the spec uses")
    func constructs() throws {
        let yaml = """
            a: 1
            b: 'it''s'
            c: "x\\ny"
            d:
              - one
              - k: v
                n: 2.5
            e: |
              line one
              line two
            f: []
            g: {}
            h: plain text
              continued
            '200': ok
            """
        let value = try MiniYAML.parse(yaml)
        #expect(value["a"] == .number(1))
        #expect(value["b"] == .string("it's"))
        #expect(value["c"] == .string("x\ny"))
        #expect(value["d"]?.array?.count == 2)
        #expect(value["d"]?.array?[1]["n"] == .number(2.5))
        #expect(value["e"] == .string("line one\nline two\n"))
        #expect(value["f"] == .array([]))
        #expect(value["g"] == .object([:]))
        #expect(value["h"] == .string("plain text continued"))
        #expect(value["200"] == .string("ok"))
    }

    /// Writes the parsed spec as JSON when `OUREA_DUMP_SPEC_JSON` names a
    /// file, so the parser can be diffed against a full YAML library.
    @Test("Parses the whole pinned OpenAPI file")
    func wholeSpec() throws {
        let text = try String(
            contentsOf: specDirectory.appendingPathComponent("openapi/v1/openapi.yaml"),
            encoding: .utf8)
        let spec = try MiniYAML.parse(text)
        #expect(spec["openapi"] == .string("3.1.0"))
        #expect((spec["paths"]?.object?.count ?? 0) >= 20)
        if let path = ProcessInfo.processInfo.environment["OUREA_DUMP_SPEC_JSON"] {
            try JSONCoding.encoder().encode(spec).write(to: URL(fileURLWithPath: path))
        }
    }
}
