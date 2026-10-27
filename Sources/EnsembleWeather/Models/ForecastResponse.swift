// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// A forecast for a named location or a point.
///
/// Every value is a distribution (``Quantiles``) in ``units``. The answers
/// to your ``ForecastOptions/probabilities`` and
/// ``ForecastOptions/windowTotals`` are in ``probabilities`` and
/// ``windowTotals``, in the order you asked.
public struct ForecastResponse: Sendable, Hashable {
    /// The events behind each served probability, in the request's units.
    public var thresholds: ProbabilityThresholds?
    /// The answers to the request's probability terms, in the caller's order.
    ///
    /// A repeated term repeats its answer; a term the server did not answer
    /// is left out (never filled in). Empty when none were asked. Look one
    /// up with ``probability(for:)``.
    public var probabilities: [ProbabilityResult]
    /// The answers to the request's window totals, in the caller's order;
    /// empty when none were asked.
    public var windowTotals: [WindowTotal]
    /// The options the server applied, after the tier clamps.
    public var applied: AppliedOptions?
    /// The location (or the resolved point) forecast.
    public var location: LocationReference
    /// The model run and the models blended.
    public var modelRun: ModelRun
    /// The unit system every value in this response is in.
    public var units: UnitSystem
    /// The hourly series, the daily summaries and the snow outlook.
    public var forecast: ForecastData
    /// Forecasts at the location's other named elevations (with `elevations`).
    public var elevationForecasts: [ElevationForecast]?
    /// Whether the live nowcast layer is blended in.
    public var isNowcastApplied: Bool
    /// The live nowcast sources this response was built without, because
    /// they did not answer in time.
    public var nowcastUnavailable: [NowcastSource]?
    /// Which member view the hourly `members` carry, when they are present.
    public var membersView: MembersView?
    /// Columbia Gorge gap flow at the first served hour, where it applies.
    public var gapFlow: GapFlow?
    /// Nearby observation sensors, ranked by elevation-weighted distance.
    public var nearestSensors: [NearestSensor]?
    /// For a point forecast: the grid point and elevation served.
    public var point: PointInfo?
    /// The current conditions read off the first served hours.
    public var current: CurrentConditions?
    /// The data sources this response drew on and the credit to carry with it.
    public var attribution: ResponseAttribution

    /// Creates a forecast; the SDK builds these from responses, and tests or
    /// previews can build their own.
    public init(
        thresholds: ProbabilityThresholds? = nil,
        probabilities: [ProbabilityResult] = [],
        windowTotals: [WindowTotal] = [],
        applied: AppliedOptions? = nil,
        location: LocationReference,
        modelRun: ModelRun,
        units: UnitSystem,
        forecast: ForecastData,
        elevationForecasts: [ElevationForecast]? = nil,
        isNowcastApplied: Bool,
        nowcastUnavailable: [NowcastSource]? = nil,
        membersView: MembersView? = nil,
        gapFlow: GapFlow? = nil,
        nearestSensors: [NearestSensor]? = nil,
        point: PointInfo? = nil,
        current: CurrentConditions? = nil,
        attribution: ResponseAttribution
    ) {
        self.thresholds = thresholds
        self.probabilities = probabilities
        self.windowTotals = windowTotals
        self.applied = applied
        self.location = location
        self.modelRun = modelRun
        self.units = units
        self.forecast = forecast
        self.elevationForecasts = elevationForecasts
        self.isNowcastApplied = isNowcastApplied
        self.nowcastUnavailable = nowcastUnavailable
        self.membersView = membersView
        self.gapFlow = gapFlow
        self.nearestSensors = nearestSensors
        self.point = point
        self.current = current
        self.attribution = attribution
    }

    /// The answer to `query`, matched on its variable, comparison, threshold
    /// (converted to ``units`` and rounded as the server rounds), window and
    /// aggregation; `nil` when the response does not carry it.
    public func probability(for query: ProbabilityQuery) -> ProbabilityResult? {
        guard let key = try? ResolvedProbabilityTerm(query, units: units) else { return nil }
        return probabilities.first { ResolvedProbabilityTerm($0, units: units) == key }
    }

    /// The answer to `query`; `nil` when the response does not carry it.
    public func windowTotal(for query: WindowTotalQuery) -> WindowTotal? {
        guard let key = try? ResolvedWindowTotal(query) else { return nil }
        return windowTotals.first { ResolvedWindowTotal($0) == key }
    }
}

extension ForecastResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case thresholds
        case probabilities
        case windowTotals = "window_totals"
        case applied
        case location
        case modelRun = "model_run"
        case units
        case forecast
        case elevationForecasts = "elevation_forecasts"
        case isNowcastApplied = "nowcast_applied"
        case nowcastUnavailable = "nowcast_unavailable"
        case membersView = "members_view"
        case gapFlow = "gap_flow"
        case nearestSensors = "nearest_sensors"
        case point
        case current
        case attribution
    }

    /// Decodes a forecast; absent `probabilities` and `window_totals` are empty.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        thresholds = try container.decodeIfPresent(ProbabilityThresholds.self, forKey: .thresholds)
        probabilities =
            try container.decodeIfPresent([ProbabilityResult].self, forKey: .probabilities) ?? []
        windowTotals =
            try container.decodeIfPresent([WindowTotal].self, forKey: .windowTotals) ?? []
        applied = try container.decodeIfPresent(AppliedOptions.self, forKey: .applied)
        location = try container.decode(LocationReference.self, forKey: .location)
        modelRun = try container.decode(ModelRun.self, forKey: .modelRun)
        units = try container.decode(UnitSystem.self, forKey: .units)
        forecast = try container.decode(ForecastData.self, forKey: .forecast)
        elevationForecasts = try container.decodeIfPresent(
            [ElevationForecast].self, forKey: .elevationForecasts)
        isNowcastApplied = try container.decode(Bool.self, forKey: .isNowcastApplied)
        nowcastUnavailable = try container.decodeIfPresent(
            [NowcastSource].self, forKey: .nowcastUnavailable)
        membersView = try container.decodeIfPresent(MembersView.self, forKey: .membersView)
        gapFlow = try container.decodeIfPresent(GapFlow.self, forKey: .gapFlow)
        nearestSensors = try container.decodeIfPresent(
            [NearestSensor].self, forKey: .nearestSensors)
        point = try container.decodeIfPresent(PointInfo.self, forKey: .point)
        current = try container.decodeIfPresent(CurrentConditions.self, forKey: .current)
        attribution = try container.decode(ResponseAttribution.self, forKey: .attribution)
    }

    /// Encodes the forecast in the API's JSON shape.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(thresholds, forKey: .thresholds)
        if !probabilities.isEmpty { try container.encode(probabilities, forKey: .probabilities) }
        if !windowTotals.isEmpty { try container.encode(windowTotals, forKey: .windowTotals) }
        try container.encodeIfPresent(applied, forKey: .applied)
        try container.encode(location, forKey: .location)
        try container.encode(modelRun, forKey: .modelRun)
        try container.encode(units, forKey: .units)
        try container.encode(forecast, forKey: .forecast)
        try container.encodeIfPresent(elevationForecasts, forKey: .elevationForecasts)
        try container.encode(isNowcastApplied, forKey: .isNowcastApplied)
        try container.encodeIfPresent(nowcastUnavailable, forKey: .nowcastUnavailable)
        try container.encodeIfPresent(membersView, forKey: .membersView)
        try container.encodeIfPresent(gapFlow, forKey: .gapFlow)
        try container.encodeIfPresent(nearestSensors, forKey: .nearestSensors)
        try container.encodeIfPresent(point, forKey: .point)
        try container.encodeIfPresent(current, forKey: .current)
        try container.encode(attribution, forKey: .attribution)
    }
}

/// The JSON error body every non-2xx response carries.
struct ErrorBody: Codable {
    let error: String
    let message: String?
}

extension APIResponse where Value == ForecastResponse {
    /// The answer to `query`; see ``ForecastResponse/probability(for:)``.
    public func probability(for query: ProbabilityQuery) -> ProbabilityResult? {
        value.probability(for: query)
    }

    /// The answer to `query`; see ``ForecastResponse/windowTotal(for:)``.
    public func windowTotal(for query: WindowTotalQuery) -> WindowTotal? {
        value.windowTotal(for: query)
    }
}
