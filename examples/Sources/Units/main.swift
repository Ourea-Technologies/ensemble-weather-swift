// SPDX-License-Identifier: BSD-2-Clause
// Units: the same forecast in metric and imperial. The server converts; the
// SDK only labels each value with its unit.

import EnsembleWeather

let client = Client()

for units in [UnitSystem.metric, .imperial] {
    let forecast = try await client.forecast(
        for: "or/mt-hood-meadows", options: ForecastOptions(units: units))
    guard let hour = forecast.series.timeseries?.first else { continue }
    let temperature = hour.ensemble.temperature.median.map { "\($0)" } ?? "n/a"
    let precipitation = hour.ensemble.precipitation.median.map { "\($0)" } ?? "n/a"
    print(
        "\(units.rawValue): median temperature \(temperature)\(forecast.units.temperatureUnit), "
            + "median precipitation \(precipitation) \(forecast.units.amountUnit)")
}
