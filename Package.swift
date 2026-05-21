// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Nook",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // SPM executable. Backed by a tiny trampoline target so the underlying
        // `NookApp` module can also be consumed as a library by the Xcode app
        // target (see `project.yml`). `swift run Nook` keeps working for the
        // headless dev loop.
        .executable(name: "Nook", targets: ["NookExecutable"]),
        // Library product so the Xcode app target can `import NookApp` and
        // call `NookApp.main()` from `App/main.swift`. Same module the SPM
        // trampoline links against — behavior cannot drift between the two
        // launch surfaces.
        .library(name: "NookApp", targets: ["NookApp"])
    ],
    targets: [
        .target(
            name: "NookSurface",
            path: "Sources/NookSurface"
        ),
        .target(
            name: "NookKit",
            dependencies: ["NookSurface"],
            path: "Sources/NookKit"
        ),
        .target(
            // Library, not executable, so both the SPM trampoline and the Xcode app
            // target can consume the same module. The `@main` annotation is gone from
            // `NookApp.swift`; entry points call `NookApp.main()` explicitly.
            name: "NookApp",
            dependencies: ["NookKit"],
            path: "Sources/NookApp"
        ),
        .executableTarget(
            // SPM trampoline. Three-line `main.swift` that imports `NookApp` and calls
            // `NookApp.main()`. The product name `Nook` (above) is preserved so
            // `swift run Nook` is unchanged. The Xcode app target has its own
            // identical trampoline at `App/main.swift`.
            name: "NookExecutable",
            dependencies: ["NookApp"],
            path: "Sources/NookExecutable"
        ),
        .testTarget(
            name: "NookKitTests",
            dependencies: ["NookKit", "NookSurface"],
            path: "Tests/NookKitTests"
        )
    ]
)
