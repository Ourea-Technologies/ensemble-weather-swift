// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The model runs the API can serve, newest first, and the run it serves now.
public struct AvailableRuns: Sendable, Hashable, Codable {
    /// What a forecast request serves now; `nil` when no cycle is servable.
    public var served: ServedRun?
    /// Init times at least two models completed, newest first.
    public var runs: [ModelRunSummary]
    /// Count.
    public var count: Int
    /// Pass it back as `cursor` (with the same `limit`) for the next page; `nil` on the last page.
    public var nextCursor: String?

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        served: ServedRun?, runs: [ModelRunSummary], count: Int, nextCursor: String? = nil
    ) {
        self.served = served
        self.runs = runs
        self.count = count
        self.nextCursor = nextCursor
    }

    enum CodingKeys: String, CodingKey {
        case served
        case runs
        case count
        case nextCursor = "next_cursor"
    }
}

/// The run a forecast request serves now.
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

/// A run at least two models completed.
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
