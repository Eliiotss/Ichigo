// swift-tools-version: 5.9

// Ichigo — a Japanese (JLPT) learning app built with SwiftUI.
//
// This is a Swift Playgrounds / Xcode App package (`.swiftpm` style). It is a
// single-target app: the `@main` entry, the SwiftUI screens and the JSON datasets
// (under `Resources`) all live in one `AppFeature` target. Swift Playgrounds
// requires the `@main` app entry to live in the application target itself — a
// split into a separate library + thin executable fails to link `_main` there —
// so the app is kept in one target.
//
// Build with Xcode 15+ (the SwiftUI/UIKit sources require the iOS SDK):
//   xcodebuild -scheme Ichigo -destination 'platform=iOS Simulator,name=iPhone 15' build
// or open Package.swift in Xcode / the folder in Swift Playgrounds and Run.

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
            targets: ["AppFeature"],
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
        // The whole app: @main entry, SwiftUI screens and bundled JSON datasets.
        .executableTarget(
            name: "AppFeature",
            path: "Sources/AppFeature",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
