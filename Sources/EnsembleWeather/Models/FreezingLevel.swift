// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// An hour's freezing level.
public enum FreezingLevel: Sendable, Hashable {
    /// The whole profile is below freezing down to the surface.
    case belowSurface
    /// The freezing level's height, in the request's units; when
    /// `aboveFreezingLayerAloft` is `true` a warm layer lies above it.
    case height(Double, aboveFreezingLayerAloft: Bool)
    /// The profile is above freezing up to `top`, its highest level.
    case aboveProfile(top: Double)
    /// A kind this SDK version does not know, with its raw `kind` string.
    case unknown(kind: String)
}

extension FreezingLevel: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind
        case height
        case aboveFreezingLayerAloft = "above_freezing_layer_aloft"
        case top
    }

    /// Decodes the `kind`-tagged object.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "below_surface":
            self = .belowSurface
        case "height":
            self = .height(
                try container.decode(Double.self, forKey: .height),
                aboveFreezingLayerAloft: try container.decode(
                    Bool.self, forKey: .aboveFreezingLayerAloft))
        case "above_profile":
            self = .aboveProfile(top: try container.decode(Double.self, forKey: .top))
        default:
            self = .unknown(kind: kind)
        }
    }

    /// Encodes the `kind`-tagged object.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .belowSurface:
            try container.encode("below_surface", forKey: .kind)
        case .height(let height, let aloft):
            try container.encode("height", forKey: .kind)
            try container.encode(height, forKey: .height)
            try container.encode(aloft, forKey: .aboveFreezingLayerAloft)
        case .aboveProfile(let top):
            try container.encode("above_profile", forKey: .kind)
            try container.encode(top, forKey: .top)
        case .unknown(let kind):
            try container.encode(kind, forKey: .kind)
        }
    }
}
