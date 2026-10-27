// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import Foundation

#if canImport(os)
    import os
#endif

/// A deprecation the API announced on a response (`Deprecation`, `Sunset`
/// and `Link rel="deprecation"` headers).
public struct DeprecationNotice: Sendable, Hashable, CustomStringConvertible {
    /// The operation whose response carried the headers (an OpenAPI
    /// `operationId`, such as `getLocationForecast`).
    public var operation: String
    /// The `Deprecation` header, verbatim (for example `@1798761600`).
    public var deprecation: String?
    /// The `Sunset` header, verbatim: when the deprecated feature stops working.
    public var sunset: String?
    /// The `Link` target with `rel="deprecation"`: where the change is documented.
    public var link: URL?

    /// Creates a notice.
    public init(operation: String, deprecation: String?, sunset: String?, link: URL?) {
        self.operation = operation
        self.deprecation = deprecation
        self.sunset = sunset
        self.link = link
    }

    /// A one-line warning naming the operation, the sunset and the link.
    public var description: String {
        var text = "Ourea API: \(operation) uses a deprecated feature"
        if let sunset { text += " (sunset \(sunset))" }
        if let link { text += "; see \(link.absoluteString)" }
        return text
    }

    init?(operation: String, headers: HTTPHeaders) {
        let deprecation = headers["Deprecation"]
        let sunset = headers["Sunset"]
        guard deprecation != nil || sunset != nil else { return nil }
        self.init(
            operation: operation, deprecation: deprecation, sunset: sunset,
            link: headers["Link"].flatMap(Self.deprecationLink))
    }

    /// The target of the first `Link` entry whose `rel` includes `deprecation`.
    static func deprecationLink(in header: String) -> URL? {
        for entry in header.split(separator: ",") {
            let parts = entry.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let target = parts.first, target.hasPrefix("<"), target.hasSuffix(">") else {
                continue
            }
            let isDeprecation = parts.dropFirst().contains { parameter in
                let pair = parameter.split(separator: "=", maxSplits: 1)
                guard pair.count == 2,
                    pair[0].trimmingCharacters(in: .whitespaces).lowercased() == "rel"
                else { return false }
                let values = pair[1].trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
                return values.split(separator: " ").contains("deprecation")
            }
            if isDeprecation { return URL(string: String(target.dropFirst().dropLast())) }
        }
        return nil
    }
}

/// Reports each operation's deprecation once (BEHAVIOR 11).
///
/// ``shared`` (the default) reports once per operation per process, to the
/// system log on Apple platforms and to standard error elsewhere. Create
/// your own to route notices to your logger or to observe them in tests.
public final class DeprecationReporter: Sendable {
    /// The process-wide reporter, logging each operation's notice once.
    public static let shared = DeprecationReporter(handler: DeprecationReporter.log)

    private let handler: @Sendable (DeprecationNotice) -> Void
    private let reported = Locked<Set<String>>([])

    /// Creates a reporter that passes each operation's first notice to `handler`.
    public init(handler: @escaping @Sendable (DeprecationNotice) -> Void) {
        self.handler = handler
    }

    func report(_ notice: DeprecationNotice) {
        let isFirst = reported.withLock { $0.insert(notice.operation).inserted }
        if isFirst { handler(notice) }
    }

    /// Writes `notice` to the system log, or to standard error where there is none.
    @Sendable public static func log(_ notice: DeprecationNotice) {
        #if canImport(os)
            Logger(subsystem: "com.oureawx.ensemble-weather", category: "deprecation")
                .warning("\(notice.description, privacy: .public)")
        #else
            FileHandle.standardError.write(Data("warning: \(notice.description)\n".utf8))
        #endif
    }
}
