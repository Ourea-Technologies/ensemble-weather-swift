// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// One probability question for the server: the chance that a variable is at
/// least (or at most) a threshold over a window.
///
/// The server computes every probability from the full ensemble; the SDK only
/// builds the `prob=` request and maps each answer back to your term. Ask
/// with ``ForecastOptions/probabilities`` and read the answers from
/// ``ForecastResponse/probabilities`` (in the order you asked) or
/// ``ForecastResponse/probability(for:)``.
///
/// ```swift
/// let snow = ProbabilityQuery.snowfall(atLeast: .inches(6))
/// let freeze = ProbabilityQuery.temperature(atMost: .fahrenheit(32), in: .hours(48))
/// ```
public struct ProbabilityQuery: Sendable, Hashable {
    /// The variable asked about.
    public var variable: ForecastVariable
    /// At least (`ge`) or at most (`le`).
    public var comparison: ProbabilityComparison
    /// The threshold.
    public var threshold: Threshold
    /// The window of hours, counted from the first served hour.
    public var window: ForecastWindow
    /// How the window's hours combine; `nil` is the variable's default
    /// (``ProbabilityAggregation/total`` for precipitation and snowfall,
    /// ``ProbabilityAggregation/any`` otherwise).
    public var aggregation: ProbabilityAggregation?

    /// Creates a probability term.
    ///
    /// - Parameters:
    ///   - variable: The variable asked about.
    ///   - comparison: At least or at most.
    ///   - threshold: The threshold, with a unit or in the request's units.
    ///   - window: The window; the next 24 hours by default.
    ///   - aggregation: How the hours combine; `nil` for the variable's default.
    public init(
        variable: ForecastVariable,
        comparison: ProbabilityComparison,
        threshold: Threshold,
        window: ForecastWindow = .next24Hours,
        aggregation: ProbabilityAggregation? = nil
    ) {
        self.variable = variable
        self.comparison = comparison
        self.threshold = threshold
        self.window = window
        self.aggregation = aggregation
    }
}

extension ProbabilityQuery {
    /// The chance the window's total snowfall is at least `threshold`.
    public static func snowfall(
        atLeast threshold: Threshold, in window: ForecastWindow = .next24Hours
    )
        -> Self
    {
        Self(variable: .snowfall, comparison: .atLeast, threshold: threshold, window: window)
    }

    /// The chance the window's total snowfall is at most `threshold`.
    public static func snowfall(
        atMost threshold: Threshold, in window: ForecastWindow = .next24Hours
    )
        -> Self
    {
        Self(variable: .snowfall, comparison: .atMost, threshold: threshold, window: window)
    }

    /// The chance the window's total precipitation is at least `threshold`.
    public static func precipitation(
        atLeast threshold: Threshold, in window: ForecastWindow = .next24Hours
    ) -> Self {
        Self(variable: .precipitation, comparison: .atLeast, threshold: threshold, window: window)
    }

    /// The chance the window's total precipitation is at most `threshold`.
    public static func precipitation(
        atMost threshold: Threshold, in window: ForecastWindow = .next24Hours
    ) -> Self {
        Self(variable: .precipitation, comparison: .atMost, threshold: threshold, window: window)
    }

    /// The chance the temperature is at least `threshold` in `aggregation` hours of the window.
    public static func temperature(
        atLeast threshold: Threshold, in window: ForecastWindow = .next24Hours,
        aggregation: ProbabilityAggregation? = nil
    ) -> Self {
        Self(
            variable: .temperature, comparison: .atLeast, threshold: threshold, window: window,
            aggregation: aggregation)
    }

    /// The chance the temperature is at most `threshold` in `aggregation` hours of the window.
    public static func temperature(
        atMost threshold: Threshold, in window: ForecastWindow = .next24Hours,
        aggregation: ProbabilityAggregation? = nil
    ) -> Self {
        Self(
            variable: .temperature, comparison: .atMost, threshold: threshold, window: window,
            aggregation: aggregation)
    }

    /// The chance the wind speed is at least `threshold` in `aggregation` hours of the window.
    public static func windSpeed(
        atLeast threshold: Threshold, in window: ForecastWindow = .next24Hours,
        aggregation: ProbabilityAggregation? = nil
    ) -> Self {
        Self(
            variable: .windSpeed, comparison: .atLeast, threshold: threshold, window: window,
            aggregation: aggregation)
    }

    /// The chance the wind speed is at most `threshold` in `aggregation` hours of the window.
    public static func windSpeed(
        atMost threshold: Threshold, in window: ForecastWindow = .next24Hours,
        aggregation: ProbabilityAggregation? = nil
    ) -> Self {
        Self(
            variable: .windSpeed, comparison: .atMost, threshold: threshold, window: window,
            aggregation: aggregation)
    }

    /// The chance the snow level is at least `threshold` in `aggregation` hours of the window.
    public static func snowLevel(
        atLeast threshold: Threshold, in window: ForecastWindow = .next24Hours,
        aggregation: ProbabilityAggregation? = nil
    ) -> Self {
        Self(
            variable: .snowLevel, comparison: .atLeast, threshold: threshold, window: window,
            aggregation: aggregation)
    }

    /// The chance the snow level is at most `threshold` in `aggregation` hours of the window.
    public static func snowLevel(
        atMost threshold: Threshold, in window: ForecastWindow = .next24Hours,
        aggregation: ProbabilityAggregation? = nil
    ) -> Self {
        Self(
            variable: .snowLevel, comparison: .atMost, threshold: threshold, window: window,
            aggregation: aggregation)
    }
}

/// A probability term resolved against a request's unit system: the key the
/// server's answer is matched on, and the term's wire form.
struct ResolvedProbabilityTerm: Hashable, Comparable {
    let variable: ForecastVariable
    let comparison: ProbabilityComparison
    let scaledThreshold: Int64
    let decimals: Int
    let window: ForecastWindow
    let aggregation: ProbabilityAggregation

    init(_ query: ProbabilityQuery, units: UnitSystem) throws(EnsembleWeatherError) {
        let variable = query.variable
        guard variable.dimension != nil else {
            throw .usage("Unknown forecast variable '\(variable.rawValue)' in a probability term.")
        }
        switch query.comparison {
        case .atLeast, .atMost: break
        case .unknown(let raw):
            throw .usage("Unknown comparison '\(raw)' in a probability term; use ge or le.")
        }
        let aggregation = query.aggregation ?? variable.defaultAggregation
        let isAmount = variable == .precipitation || variable == .snowfall
        switch aggregation {
        case .total where !isAmount:
            throw .usage(
                "'total' aggregates precipitation and snowfall only, not \(variable.rawValue).")
        case .any where isAmount, .all where isAmount:
            throw .usage(
                "\(variable.rawValue) takes the 'total' aggregation only, not '\(aggregation.rawValue)'."
            )
        case .unknown(let raw):
            throw .usage("Unknown aggregation '\(raw)' in a probability term.")
        default: break
        }
        _ = try query.window.wireValue()
        let decimals = variable.decimals(in: units)
        let value = try query.threshold.value(for: variable, in: units)
        guard let scaled = DecimalFormatting.roundedScaled(value, decimals: decimals) else {
            throw .usage("A probability threshold must be a finite number of sensible size.")
        }
        self.variable = variable
        self.comparison = query.comparison
        self.scaledThreshold = scaled
        self.decimals = decimals
        self.window = query.window
        self.aggregation = aggregation
    }

    /// The key of a server answer, or `nil` when it cannot match any term.
    init?(_ result: ProbabilityResult, units: UnitSystem) {
        let decimals = result.variable.decimals(in: units)
        guard
            let scaled = DecimalFormatting.roundedScaled(result.threshold, decimals: decimals)
        else { return nil }
        self.variable = result.variable
        self.comparison = result.comparison
        self.scaledThreshold = scaled
        self.decimals = decimals
        self.window = ForecastWindow(
            startHours: result.windowStartHours, endHours: result.windowEndHours)
        self.aggregation = result.aggregation
    }

    var wireValue: String {
        var term =
            "\(variable.rawValue):\(comparison.rawValue):"
            + DecimalFormatting.fixed(scaled: scaledThreshold, decimals: decimals) + ":"
            + (window.startHours == 0
                ? "\(window.endHours)h" : "\(window.startHours)-\(window.endHours)h")
        if aggregation != variable.defaultAggregation { term += ":\(aggregation.rawValue)" }
        return term
    }

    /// The server's canonical order: variable, op, window, aggregation, threshold.
    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.variable.rawValue != rhs.variable.rawValue {
            return lhs.variable.rawValue < rhs.variable.rawValue
        }
        if lhs.comparison != rhs.comparison { return lhs.comparison == .atLeast }
        if lhs.window != rhs.window { return lhs.window < rhs.window }
        if lhs.aggregation != rhs.aggregation {
            return lhs.aggregation.canonicalRank < rhs.aggregation.canonicalRank
        }
        return lhs.scaledThreshold < rhs.scaledThreshold
    }

    /// The `prob=` value for `terms`: de-duplicated, sorted, comma-joined.
    static func wireValue(for terms: [Self]) -> String? {
        terms.isEmpty ? nil : Set(terms).sorted().map(\.wireValue).joined(separator: ",")
    }
}

extension ProbabilityAggregation {
    fileprivate var canonicalRank: Int {
        switch self {
        case .total: 0
        case .any: 1
        case .all: 2
        case .unknown: 3
        }
    }
}

/// A window-total question: the distribution of each member's total
/// precipitation or snowfall over a window, computed by the server.
///
/// This is the only storm total the SDK offers: summing hourly quantiles
/// gives a wrong answer, so the SDK never does it.
///
/// ```swift
/// let storm = WindowTotalQuery.snowfall(in: .hours(72))
/// ```
public struct WindowTotalQuery: Sendable, Hashable {
    /// ``ForecastVariable/precipitation`` or ``ForecastVariable/snowfall``.
    public var variable: ForecastVariable
    /// The window of hours.
    public var window: ForecastWindow

    /// Creates a window-total query.
    public init(variable: ForecastVariable, window: ForecastWindow) {
        self.variable = variable
        self.window = window
    }

    /// The distribution of total snowfall over `window`.
    public static func snowfall(in window: ForecastWindow) -> Self {
        Self(variable: .snowfall, window: window)
    }

    /// The distribution of total precipitation over `window`.
    public static func precipitation(in window: ForecastWindow) -> Self {
        Self(variable: .precipitation, window: window)
    }
}

/// A window-total query checked and keyed for matching the server's answer.
struct ResolvedWindowTotal: Hashable, Comparable {
    let variable: ForecastVariable
    let window: ForecastWindow

    init(_ query: WindowTotalQuery) throws(EnsembleWeatherError) {
        guard query.variable == .precipitation || query.variable == .snowfall else {
            throw .usage(
                "Window totals are for precipitation and snowfall, not \(query.variable.rawValue).")
        }
        _ = try query.window.wireValue()
        self.variable = query.variable
        self.window = query.window
    }

    init(_ total: WindowTotal) {
        variable = total.variable
        window = ForecastWindow(startHours: total.windowStartHours, endHours: total.windowEndHours)
    }

    var wireValue: String {
        "\(variable.rawValue):"
            + (window.startHours == 0
                ? "\(window.endHours)h" : "\(window.startHours)-\(window.endHours)h")
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.variable.rawValue == rhs.variable.rawValue
            ? lhs.window < rhs.window : lhs.variable.rawValue < rhs.variable.rawValue
    }

    static func wireValue(for totals: [Self]) -> String? {
        totals.isEmpty ? nil : Set(totals).sorted().map(\.wireValue).joined(separator: ",")
    }
}
