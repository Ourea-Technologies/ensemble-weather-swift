// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// A pair of percentiles the server serves, for ``Quantiles/range(_:)``.
///
/// Only served pairs exist: the SDK never interpolates a percentile the
/// server did not send.
public enum QuantileRange: Sendable, Hashable, CaseIterable {
    /// The 10th to 90th percentile: 8 in 10 ensemble outcomes fall inside.
    case p10ToP90
    /// The 25th to 75th percentile (interquartile): half the outcomes fall inside.
    case p25ToP75
}

/// Two percentiles of a distribution, low and high.
///
/// Not a `ClosedRange`: for the circular `wind_direction`, `lower` may be
/// numerically greater than `upper` (an arc through north, such as 355° to
/// 15°). The SDK reports the server's values and does not "fix" them.
public struct QuantileInterval: Sendable, Hashable {
    /// The lower percentile's value.
    public var lower: Double
    /// The upper percentile's value.
    public var upper: Double

    /// Creates an interval.
    public init(lower: Double, upper: Double) {
        self.lower = lower
        self.upper = upper
    }
}

extension Quantiles {
    /// The median (p50).
    ///
    /// This is the middle ensemble outcome, not "the forecast": read it with
    /// a range or a probability.
    public var median: Double? { p50 }

    /// The interval between a served pair of percentiles, or `nil` when the
    /// server did not send both.
    ///
    /// ```swift
    /// if let range = hour.ensemble.temperature.range(.p10ToP90) {
    ///     print("\(range.lower) to \(range.upper)")
    /// }
    /// ```
    public func range(_ pair: QuantileRange) -> QuantileInterval? {
        let bounds: (Double?, Double?) =
            switch pair {
            case .p10ToP90: (p10, p90)
            case .p25ToP75: (p25, p75)
            }
        guard let lower = bounds.0, let upper = bounds.1 else { return nil }
        return QuantileInterval(lower: lower, upper: upper)
    }
}
