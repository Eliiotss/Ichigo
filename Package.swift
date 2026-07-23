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
        .executableTarget(
            name: "AppModule",
            path: "Sources/AppModule",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "AppModuleTests",
            dependencies: ["AppModule"],
            path: "Tests/AppModuleTests"
        )
    ]
)
