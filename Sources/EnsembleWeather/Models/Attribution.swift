// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The data sources THIS response drew on, and what their licences ask us to say.
public struct ResponseAttribution: Sendable, Hashable, Codable {
    /// Source ids from `GET /api/v1/attribution`, in registry order.
    public var sources: [String]
    /// Credit.
    public var credit: String
    /// Path of the full registry.
    public var url: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(sources: [String], credit: String, url: String) {
        self.sources = sources
        self.credit = credit
        self.url = url
    }

    enum CodingKeys: String, CodingKey {
        case sources
        case credit
        case url
    }
}

/// Every data provider the API draws on, with its credit line, licence and notices.
public struct Attribution: Sendable, Hashable, Codable {
    /// Providers.
    public var providers: [AttributionProvider]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(providers: [AttributionProvider]) {
        self.providers = providers
    }

    enum CodingKeys: String, CodingKey {
        case providers
    }
}

/// One data provider: its credit line, licence, terms and the sources it supplies.
public struct AttributionProvider: Sendable, Hashable, Codable {
    /// Id.
    public var id: String
    /// Name.
    public var name: String
    /// The credit line a response carries for this provider.
    public var credit: String
    /// SPDX id where one exists (`CC-BY-4.0`, `CC-BY-3.0`, `ODbL-1.0`).
    public var licence: String
    /// Licence url.
    public var licenceURL: String
    /// The page the wording was taken from.
    public var termsURL: String
    /// Ourea serves this provider's data modified and its terms ask that this be said.
    public var isModified: Bool
    /// Statements the terms require shown in full, beyond `credit`.
    public var notices: [String]
    /// Sources.
    public var sources: [AttributionSource]

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(
        id: String, name: String, credit: String, licence: String, licenceURL: String,
        termsURL: String, isModified: Bool, notices: [String], sources: [AttributionSource]
    ) {
        self.id = id
        self.name = name
        self.credit = credit
        self.licence = licence
        self.licenceURL = licenceURL
        self.termsURL = termsURL
        self.isModified = isModified
        self.notices = notices
        self.sources = sources
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case credit
        case licence
        case licenceURL = "licence_url"
        case termsURL = "terms_url"
        case isModified = "modified"
        case notices
        case sources
    }
}

/// One data source (a model, an observation network, ...) and its provider.
public struct AttributionSource: Sendable, Hashable, Codable {
    /// Id.
    public var id: String
    /// Name.
    public var name: String
    /// Kind.
    public var kind: AttributionSourceKind
    /// Provider.
    public var provider: String

    /// Creates a value; the SDK builds these from responses, and tests or previews can build their own.
    public init(id: String, name: String, kind: AttributionSourceKind, provider: String) {
        self.id = id
        self.name = name
        self.kind = kind
        self.provider = provider
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case kind
        case provider
    }
}
