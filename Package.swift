// swift-tools-version: 5.9

// Ichigo — a Japanese (JLPT) learning app built with SwiftUI.
//
// This is a Swift Playgrounds / Xcode App package (`.swiftpm` style). The whole
// app is a single iOS application product backed by the `AppModule` target, which
// bundles the app's source and its JSON datasets under `Resources`. A separate
// `AppModuleTests` target holds the pure-logic unit tests.
//
// Build & test with Xcode 15+ (the SwiftUI/UIKit sources require the iOS SDK):
//   xcodebuild -scheme Ichigo -destination 'platform=iOS Simulator,name=iPhone 15' build
//   xcodebuild -scheme Ichigo -destination 'platform=iOS Simulator,name=iPhone 15' test

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Ichigo",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "Ichigo",
            targets: ["AppModule"],
            bundleIdentifier: "com.ichigo.app",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        // All app logic and UI lives in a library target so it can be imported
        // by both the app executable and the XCTest target. (An executable target
        // that carries `@main` cannot be `@testable import`-ed under xcodebuild.)
        .target(
            name: "AppFeature",
            path: "Sources/AppFeature",
            resources: [
                .process("Resources")
            ]
        ),
        // Thin executable that hosts the library's RootView; this is the app.
        .executableTarget(
            name: "AppModule",
            dependencies: ["AppFeature"],
            path: "Sources/AppModule"
        ),
        .testTarget(
            name: "AppFeatureTests",
            dependencies: ["AppFeature"],
            path: "Tests/AppFeatureTests"
        )
    ]
)
