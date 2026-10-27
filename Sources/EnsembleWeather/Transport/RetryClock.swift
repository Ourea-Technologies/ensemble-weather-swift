// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

/// The clock the client waits on between retries and reads the time from
/// (to interpret an HTTP-date `Retry-After` and cache freshness).
///
/// The default is ``SystemRetryClock``. Inject your own to make retry
/// timing deterministic in tests.
public protocol RetryClock: Sendable {
    /// The current time.
    var now: Date { get }
    /// Suspends for `seconds`, throwing `CancellationError` if the task is cancelled.
    func sleep(seconds: TimeInterval) async throws
}

/// The system clock, sleeping with `Task.sleep`.
public struct SystemRetryClock: RetryClock {
    /// Creates the system clock.
    public init() {}

    /// The current time.
    public var now: Date { Date() }

    /// Sleeps for `seconds` with `Task.sleep`.
    public func sleep(seconds: TimeInterval) async throws {
        guard seconds > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
