// SPDX-License-Identifier: BSD-2-Clause
// Snow report: the models behind the forecast, the five places with the most
// snow coming in the next five days, and a ski area's season so far.

import EnsembleWeather

let client = Client()

let composition = try await client.composition()
print("Blended from \(composition.modelCount) models, \(composition.totalMembers) members")

let ranking = try await client.explorePage(.snow5Days, type: .skiArea, limit: 5)
for item in ranking.items {
    print("\(item.rank). \(item.location.name): \(item.value) \(ranking.unit) in 5 days")
}

let season = try await client.season(for: "or/mt-hood-meadows")
if let precipitation = season.precipitation {
    let normal = precipitation.percentOfNormal.map { " (\($0)% of normal)" } ?? ""
    print(
        "\(season.location.name), water year \(season.waterYear): "
            + "\(precipitation.amount) \(precipitation.unit) of precipitation\(normal)")
}

let snowpack = try await client.snowpack(for: "or/mt-hood-meadows")
if let spot = snowpack.spots.first, let depth = spot.depth.p50.first {
    print("Snowpack (beta) at \(spot.displayName ?? spot.name ?? "the base"): \(depth) depth now")
}

// The snow trend needs a Plus or Pro key.
do {
    let trend = try await client.snowTrend(for: "or/mt-hood-meadows")
    print("Snow trend: \(trend.grids.count) sources over \(trend.dates.count) days")
} catch let error as OureaError where error.category == .permission {
    print("Snow trend: \(error.code?.rawValue ?? "permission denied") (needs a Plus or Pro key)")
}
