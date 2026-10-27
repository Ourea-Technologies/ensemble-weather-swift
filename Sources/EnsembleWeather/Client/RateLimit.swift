// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The rate-limit state a response reported in its `RateLimit-*` headers.
///
/// Budgets differ by tier and change over time, so read them here rather
/// than hard-coding numbers. Responses a shared cache may store (anonymous
/// forecasts, search) carry no rate-limit headers, so their state is `nil`.
public struct RateLimit: Sendable, Hashable {
    /// `RateLimit-Limit`: requests allowed in the current window.
    public var limit: Int?
    /// `RateLimit-Remaining`: requests left in the current window.
    public var remaining: Int?
    /// `RateLimit-Reset`: seconds until the window resets.
    public var resetSeconds: Int?
    /// `RateLimit-Policy`, verbatim (for example `60;w=60`).
    public var policy: String?

    /// Creates a rate-limit state.
    public init(
        limit: Int? = nil, remaining: Int? = nil, resetSeconds: Int? = nil, policy: String? = nil
    ) {
        self.limit = limit
        self.remaining = remaining
        self.resetSeconds = resetSeconds
        self.policy = policy
    }

    /// Reads the state from response headers; `nil` when none is present.
    init?(headers: HTTPHeaders) {
        func integer(_ name: String) -> Int? {
            headers[name].flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        let state = RateLimit(
            limit: integer("RateLimit-Limit"),
            remaining: integer("RateLimit-Remaining"),
            resetSeconds: integer("RateLimit-Reset"),
            policy: headers["RateLimit-Policy"])
        if state == RateLimit() { return nil }
        self = state
    }
}
