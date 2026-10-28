# Probabilities, not single numbers

Ask the server for probabilities and window totals; never compute them.

## Overview

Every forecast value is a distribution (``Quantiles``) computed from the full
ensemble. The SDK never sums, averages or interpolates quantiles, and never
derives a probability from them: summing hourly quantiles gives a wrong storm
total. When you need a probability or a total, ask the server for it.

### The chance of an event

```swift
let freeze = ProbabilityQuery.temperature(atMost: .fahrenheit(32), in: .hours(48), aggregation: .all)
let forecast = try await client.forecast(
    for: "or/mt-hood-meadows", options: ForecastOptions(probabilities: [freeze]))
let answer = forecast.probability(for: freeze)
print(answer?.probability as Any, answer?.members as Any)
```

Each ``ProbabilityResult`` carries its reference class: variable, comparison,
threshold (in the response's units), window and the members that voted. It
also echoes its canonical ``ProbabilityResult/term``, and the SDK matches each
answer to your query by that term, never by position. A `nil` probability is
never reported as 0: ``ProbabilityResult/nullReason`` says why it is missing
(the forecast does not reach the window's end, too few members cover it, or
no member carries the variable).

A threshold with a unit is converted to the request's units with exact
factors and rounded exactly as the server rounds, so the request is the
canonical one every caller shares.

### Window totals

```swift
let forecast = try await client.forecast(
    for: "or/mt-hood-meadows",
    options: ForecastOptions(windowTotals: [.snowfall(in: .hours(72))]))
let storm = forecast.windowTotals.first?.quantiles?.range(.p10ToP90)
```

A ``WindowTotal`` with `nil` quantiles carries its
``WindowTotal/nullReason``, like a probability.

### Quantiles

``Quantiles/range(_:)`` returns only pairs the server serves (p10 to p90,
p25 to p75). ``Quantiles/median`` is the median, not "the forecast".

The wind direction is not a ``Quantiles`` but a ``CircularStats``: a mean
bearing, a standard deviation, and the central 50 % and 90 % of the members as
clockwise ``Sector``s. A sector's `to` may be numerically less than its `from`:
the arc runs through north.

See <https://docs.oureawx.com/concepts/probabilities>.
