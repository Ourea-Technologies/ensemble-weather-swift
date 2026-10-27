// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// A window of forecast hours, counted from the first served hour.
///
/// ```swift
/// ForecastWindow.hours(24)            // hours 0 to 24, sent as `24h`
/// ForecastWindow.hours(from: 12, to: 36)  // sent as `12-36h`
/// ```
public struct ForecastWindow: Sendable, Hashable, Comparable {
    /// The longest window the API serves, in hours.
    public static let maximumHours = 360

    /// The first hour of the window.
    public var startHours: Int
    /// The hour the window ends at.
    public var endHours: Int

    /// Creates a window from `startHours` to `endHours`.
    public init(startHours: Int, endHours: Int) {
        self.startHours = startHours
        self.endHours = endHours
    }

    /// The next `hours` hours: from the first served hour to `hours` after it.
    public static func hours(_ hours: Int) -> Self { Self(startHours: 0, endHours: hours) }

    /// The hours from `start` to `end`.
    public static func hours(from start: Int, to end: Int) -> Self {
        Self(startHours: start, endHours: end)
    }

    /// The default window, the next 24 hours.
    public static let next24Hours = hours(24)

    /// Orders windows by start, then end (the API's canonical order).
    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.startHours, lhs.endHours) < (rhs.startHours, rhs.endHours)
    }

    /// The wire form: `<N>h`, or `<A>-<B>h` when the window does not start at 0.
    func wireValue() throws(EnsembleWeatherError) -> String {
        guard startHours >= 0, endHours > startHours, endHours <= Self.maximumHours else {
            throw .usage(
                "A forecast window must satisfy 0 <= start < end <= \(Self.maximumHours) h; "
                    + "got \(startHours)-\(endHours) h.")
        }
        return startHours == 0 ? "\(endHours)h" : "\(startHours)-\(endHours)h"
    }
}
