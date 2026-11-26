// SPDX-License-Identifier: BSD-2-Clause
// Current conditions and alerts: the blended current reading and the active
// weather alerts for a named location.

import EnsembleWeather

let client = Client()

let conditions = try await client.currentConditions(for: "or/mt-hood-meadows")
if let now = conditions.now {
    print(
        "\(conditions.location.name) now: \(now.text), \(now.temperature)\(conditions.units.temperatureUnit), "
            + "wind \(now.windSpeed) \(conditions.units.speedUnit) (from \(now.source.rawValue))")
} else {
    print("No current reading for \(conditions.location.name) yet.")
}
print("\(conditions.sensorCount) sensors nearby")

let alerts = try await client.alerts(for: "or/mt-hood-meadows")
if alerts.items.isEmpty { print("No active alerts.") }
for alert in alerts.items {
    print("\(alert.severity): \(alert.headline) (until \(alert.expires))")
}
