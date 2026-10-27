// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The model runs the API can serve, newest first, and the run it serves now.
public struct AvailableRuns: Sendable, Hashable, Codable {
    /// What a forecast request serves now; `null` when no cycle is servable.
    public var served: ServedRun
    /// Init times at least two models completed, newest first (it was `available_runs`, bare strings).
    public var runs: [ModelRunSummary]
    /// Count.
    public var count: Int

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(served: ServedRun, runs: [ModelRunSummary], count: Int) {
        self.served = served
        self.runs = runs
        self.count = count
    }

    enum CodingKeys: String, CodingKey {
        case served
        case runs
        case count
    }
}

/// What a forecast request serves now; `null` when no cycle is servable.
public struct ServedRun: Sendable, Hashable, Codable {
    /// The reference init: the newest contributing cycle, a forecast's `model_run.initialized_at`.
    public var initializedAt: Date
    /// Each contributing model and its own cycle (`{id, cycle}`), as `model_run.models`.
    public var models: [ModelEntry]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(initializedAt: Date, models: [ModelEntry]) {
        self.initializedAt = initializedAt
        self.models = models
    }

    enum CodingKeys: String, CodingKey {
        case initializedAt = "initialized_at"
        case models
    }
}

/// Init times at least two models completed, newest first (it was `available_runs`, bare strings).
public struct ModelRunSummary: Sendable, Hashable, Codable {
    /// Initialized at.
    public var initializedAt: Date

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(initializedAt: Date) {
        self.initializedAt = initializedAt
    }

    enum CodingKeys: String, CodingKey {
        case initializedAt = "initialized_at"
    }
}

/// Recent storm reports: forecast against observed totals.
public struct StormReportList: Sendable, Hashable, Codable {
    /// Reports.
    public var reports: [StormReport]
    /// Count.
    public var count: Int

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(reports: [StormReport], count: Int) {
        self.reports = reports
        self.count = count
    }

    enum CodingKeys: String, CodingKey {
        case reports
        case count
    }
}

/// A verified storm event summary published to the public `/api/v1/storm-reports` surface.
public struct StormReport: Sendable, Hashable, Codable {
    /// Id.
    public var id: Int64
    /// Location name.
    public var locationName: String
    /// Precipitation regime (e.g., `snowfall`, `rainfall`, `atmospheric_river`).
    public var eventType: String
    /// Onset time.
    public var onsetTime: Date
    /// End time.
    public var endTime: Date
    /// Forecast total mm.
    public var forecastTotalMillimeters: Double
    /// Observed total mm.
    public var observedTotalMillimeters: Double
    /// Forecast snowfall mm.
    public var forecastSnowfallMillimeters: Double?
    /// Observed snowfall mm.
    public var observedSnowfallMillimeters: Double?
    /// Model with the highest composite score for this event.
    public var bestModel: String?
    /// Best lead time hours.
    public var bestLeadTimeHours: Int?
    /// 0-1 skill score (higher = better).
    public var compositeScore: Double?
    /// Headline.
    public var headline: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: Int64, locationName: String, eventType: String, onsetTime: Date, endTime: Date,
        forecastTotalMillimeters: Double, observedTotalMillimeters: Double,
        forecastSnowfallMillimeters: Double? = nil, observedSnowfallMillimeters: Double? = nil,
        bestModel: String? = nil, bestLeadTimeHours: Int? = nil, compositeScore: Double? = nil,
        headline: String? = nil
    ) {
        self.id = id
        self.locationName = locationName
        self.eventType = eventType
        self.onsetTime = onsetTime
        self.endTime = endTime
        self.forecastTotalMillimeters = forecastTotalMillimeters
        self.observedTotalMillimeters = observedTotalMillimeters
        self.forecastSnowfallMillimeters = forecastSnowfallMillimeters
        self.observedSnowfallMillimeters = observedSnowfallMillimeters
        self.bestModel = bestModel
        self.bestLeadTimeHours = bestLeadTimeHours
        self.compositeScore = compositeScore
        self.headline = headline
    }

    enum CodingKeys: String, CodingKey {
        case id
        case locationName = "location_name"
        case eventType = "event_type"
        case onsetTime = "onset_time"
        case endTime = "end_time"
        case forecastTotalMillimeters = "forecast_total_mm"
        case observedTotalMillimeters = "observed_total_mm"
        case forecastSnowfallMillimeters = "forecast_snowfall_mm"
        case observedSnowfallMillimeters = "observed_snowfall_mm"
        case bestModel = "best_model"
        case bestLeadTimeHours = "best_lead_time_hours"
        case compositeScore = "composite_score"
        case headline
    }
}
