// SPDX-License-Identifier: BSD-2-Clause
// Maps: the outlines of the active winter alerts over the Pacific Northwest
// and the avalanche forecast zones, as GeoJSON with the API's own keys.

import EnsembleWeather

let client = Client()

let outlines = try await client.alertOutlines(
    classes: [.winter], boundingBox: BoundingBox(west: -125, south: 41, east: -116, north: 49))
print("\(outlines.features.count) winter alert outlines in the Pacific Northwest")
for feature in outlines.features.prefix(3) {
    if case .string(let event)? = feature.properties["event"] {
        print("  \(event) (\(feature.geometry.type))")
    }
}

let zones = try await client.avalancheZones()
let rated = zones.features.filter {
    if case .number? = $0.properties["danger_level"] { return true }
    return false
}
print("\(zones.features.count) avalanche zones, \(rated.count) rated today")
