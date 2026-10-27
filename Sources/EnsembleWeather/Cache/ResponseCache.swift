// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// A store for responses the client revalidates with `ETag` (BEHAVIOR 10).
///
/// The client is a private cache: it sends `If-None-Match` with the stored
/// `ETag` and, on `304 Not Modified`, returns the stored body. Keys are the
/// full request URL plus a SHA-256 digest of the API key the request carried
/// (never the key itself), so keyless and keyed entries never mix.
///
/// The default is an in-memory ``MemoryResponseCache``. Conform your own type
/// to share entries across processes; pass `cache: nil` in
/// ``EnsembleWeatherClient/Configuration`` to turn caching off.
public protocol ResponseCache: Sendable {
    /// The entry stored under `key`, if any.
    func entry(forKey key: String) async -> CachedResponse?
    /// Stores `entry` under `key`, replacing any earlier entry.
    func store(_ entry: CachedResponse, forKey key: String) async
    /// Removes the entry under `key`.
    func removeEntry(forKey key: String) async
}

/// A stored response.
public struct CachedResponse: Sendable, Hashable, Codable {
    /// The response body.
    public var body: Data
    /// The response headers, as received (or as refreshed by a `304`).
    public var headers: [String: String]
    /// The `ETag`, byte for byte as received (including any `W/`).
    public var etag: String?
    /// When the response was stored or last revalidated.
    public var storedAt: Date
    /// The `max-age` freshness lifetime in seconds; `0` means revalidate every time.
    public var maxAge: TimeInterval

    /// Creates a stored response.
    public init(
        body: Data, headers: [String: String], etag: String?, storedAt: Date, maxAge: TimeInterval
    ) {
        self.body = body
        self.headers = headers
        self.etag = etag
        self.storedAt = storedAt
        self.maxAge = maxAge
    }

    /// The size counted against a cache's byte bound.
    public var cost: Int {
        body.count + headers.reduce(0) { $0 + $1.key.utf8.count + $1.value.utf8.count }
    }
}

/// An in-memory least-recently-used cache, bounded by entry count and bytes.
public actor MemoryResponseCache: ResponseCache {
    /// The most entries kept.
    public let maximumEntries: Int
    /// The most bytes of bodies and headers kept.
    public let maximumBytes: Int

    private var entries: [String: CachedResponse] = [:]
    private var order: [String] = []
    private var totalBytes = 0

    /// Creates a cache; the defaults are 256 entries and 32 MiB.
    public init(maximumEntries: Int = 256, maximumBytes: Int = 32 * 1024 * 1024) {
        self.maximumEntries = maximumEntries
        self.maximumBytes = maximumBytes
    }

    /// The entry under `key`, marked as most recently used.
    public func entry(forKey key: String) -> CachedResponse? {
        guard let entry = entries[key] else { return nil }
        touch(key)
        return entry
    }

    /// Stores `entry`, evicting the least recently used entries past the bounds.
    public func store(_ entry: CachedResponse, forKey key: String) {
        removeEntry(forKey: key)
        guard entry.cost <= maximumBytes, maximumEntries > 0 else { return }
        entries[key] = entry
        order.append(key)
        totalBytes += entry.cost
        while entries.count > maximumEntries || totalBytes > maximumBytes, let oldest = order.first
        {
            removeEntry(forKey: oldest)
        }
    }

    /// Removes the entry under `key`.
    public func removeEntry(forKey key: String) {
        guard let entry = entries.removeValue(forKey: key) else { return }
        totalBytes -= entry.cost
        order.removeAll { $0 == key }
    }

    /// The number of entries held.
    public var count: Int { entries.count }

    private func touch(_ key: String) {
        order.removeAll { $0 == key }
        order.append(key)
    }
}
