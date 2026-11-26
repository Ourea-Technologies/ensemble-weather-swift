// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// A point in degrees, for `near` on search and explore.
///
/// It is sent as one `lat,lon` value, each number the shortest decimal that
/// round-trips, with a literal comma.
public struct Coordinate: Sendable, Hashable {
    /// Degrees north, -90...90.
    public var latitude: Double
    /// Degrees east, -180...180.
    public var longitude: Double

    /// Creates a coordinate.
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    /// `lat,lon` on the wire, or a usage error for an out-of-range value.
    func wireValue() throws(OureaError) -> String {
        try Degrees.format(latitude, name: "near latitude", bound: 90) + ","
            + Degrees.format(longitude, name: "near longitude", bound: 180)
    }
}

/// A box in degrees, for `bbox` on the alert outlines.
///
/// It is sent as one `west,south,east,north` value with literal commas.
public struct BoundingBox: Sendable, Hashable {
    /// The western edge, degrees east (-180...180).
    public var west: Double
    /// The southern edge, degrees north (-90...90).
    public var south: Double
    /// The eastern edge, degrees east; at least `west`.
    public var east: Double
    /// The northern edge, degrees north; at least `south`.
    public var north: Double

    /// Creates a box.
    public init(west: Double, south: Double, east: Double, north: Double) {
        self.west = west
        self.south = south
        self.east = east
        self.north = north
    }

    /// `west,south,east,north` on the wire, or a usage error.
    func wireValue() throws(OureaError) -> String {
        let edges = [
            try Degrees.format(west, name: "bbox west", bound: 180),
            try Degrees.format(south, name: "bbox south", bound: 90),
            try Degrees.format(east, name: "bbox east", bound: 180),
            try Degrees.format(north, name: "bbox north", bound: 90),
        ]
        guard west <= east, south <= north else {
            throw .usage(
                "A bounding box is (west, south, east, north) with west <= east and south <= north."
            )
        }
        return edges.joined(separator: ",")
    }
}

/// The order of a ranking (`order` on search and explore).
public enum RankOrder: String, Sendable, Hashable, CaseIterable {
    /// Highest first (the default; not sent).
    case descending = "desc"
    /// Lowest first.
    case ascending = "asc"
}

/// Which of a location's points an explore ranking covers (`points`).
public enum ExplorePoints: String, Sendable, Hashable, CaseIterable {
    /// Each location's primary point (the default; not sent).
    case primary
    /// Every named elevation of every location.
    case all
}

enum Degrees {
    static func format(_ value: Double, name: String, bound: Double) throws(OureaError) -> String {
        guard value.isFinite, (-bound...bound).contains(value) else {
            throw .usage("The \(name) must be a number within ±\(Int(bound)), got \(value).")
        }
        return DecimalFormatting.shortest(value)
    }
}
