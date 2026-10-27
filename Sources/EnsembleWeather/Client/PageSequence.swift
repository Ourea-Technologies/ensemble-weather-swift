// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

/// A lazy sequence over every item of a cursor-paged list: it fetches a page
/// only when the items before it are used up, and ends when the server's
/// `next_cursor` is `null`.
///
/// ```swift
/// for try await location in client.catalogLocations() {
///     print(location.slug)
/// }
/// ```
public struct PageSequence<Element: Sendable>: AsyncSequence, Sendable {
    typealias Fetch =
        @Sendable (_ cursor: String?) async throws -> (items: [Element], nextCursor: String?)

    private let fetch: Fetch

    init(fetch: @escaping Fetch) {
        self.fetch = fetch
    }

    /// Creates the iterator.
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(fetch: fetch)
    }

    /// Iterates over the items, fetching pages on demand.
    public struct AsyncIterator: AsyncIteratorProtocol {
        private let fetch: Fetch
        private var buffer: [Element] = []
        private var index = 0
        private var cursor: String?
        private var isFinished = false
        private var hasFetched = false

        init(fetch: @escaping Fetch) {
            self.fetch = fetch
        }

        /// The next item, fetching the next page when needed; `nil` at the end.
        public mutating func next() async throws -> Element? {
            while index >= buffer.count {
                if isFinished || (hasFetched && cursor == nil) { return nil }
                let page = try await fetch(cursor)
                hasFetched = true
                buffer = page.items
                index = 0
                cursor = page.nextCursor?.isEmpty == true ? nil : page.nextCursor
                if page.items.isEmpty && cursor == nil { isFinished = true }
            }
            defer { index += 1 }
            return buffer[index]
        }
    }
}
