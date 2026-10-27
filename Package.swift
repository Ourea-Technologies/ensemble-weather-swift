// swift-tools-version: 6.0
// SPDX-License-Identifier: BSD-2-Clause
// Copyright (c) 2026 Ourea Technologies

import PackageDescription

let package = Package(
    name: "ensemble-weather-swift",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        .library(name: "EnsembleWeather", targets: ["EnsembleWeather"])
    ],
    dependencies: [
        // Documentation only (`swift package generate-documentation`); the
        // library target depends on nothing.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0")
    ],
    targets: [
        .target(name: "EnsembleWeather"),
        .testTarget(
            name: "EnsembleWeatherTests",
            dependencies: ["EnsembleWeather"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
