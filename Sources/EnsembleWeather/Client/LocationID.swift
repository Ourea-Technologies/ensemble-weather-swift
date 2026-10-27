// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// A named location: a US state and the location's slug.
///
/// Write it as one string, `"or/mt-hood-meadows"`, or give the parts. A
/// two-letter state code is lowercased (the canonical form); a state name
/// (`"oregon"`) is passed through and the server redirects it.
public struct LocationID: Sendable, Hashable, ExpressibleByStringLiteral, CustomStringConvertible {
    /// The state: a USPS code (`or`) or a name.
    public var state: String
    /// The location's slug (`mt-hood-meadows`).
    public var slug: String

    /// Creates a location from its state and slug.
    public init(state: String, slug: String) {
        self.state = state
        self.slug = slug
    }

    /// Creates a location from `"state/slug"`, split on its one `/`.
    public init(_ combined: String) {
        let parts = combined.split(separator: "/", omittingEmptySubsequences: false)
        if parts.count == 2 {
            self.init(state: String(parts[0]), slug: String(parts[1]))
        } else {
            self.init(state: combined, slug: "")
        }
    }

    /// Creates a location from a `"state/slug"` literal.
    public init(stringLiteral value: String) { self.init(value) }

    /// `"state/slug"`.
    public var description: String { "\(state)/\(slug)" }

    /// The two path segments, state canonicalised, or a usage error.
    func pathSegments() throws(EnsembleWeatherError) -> [String] {
        guard !state.isEmpty, !slug.isEmpty else {
            throw .usage(
                "A location is \"state/slug\", for example \"or/mt-hood-meadows\"; got \"\(self)\"."
            )
        }
        let isCode = state.count == 2 && state.allSatisfy { $0.isASCII && $0.isLetter }
        return [isCode ? state.lowercased() : state, slug]
    }
}
