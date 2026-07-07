// swift-tools-version:5.9
import PackageDescription

// Mouse Studio — a generic, open-source native macOS mouse automation platform.
// Layered architecture (see docs/TechnicalDesignDocument.md):
//   Shared  → pure models, enums, IPC contracts (no internal deps)
//   Core    → automation engine (depends on Shared only; no UI)
//   Actions → concrete ActionProviders (depends on Core, Shared)
//   Config  → JSON config store (depends on Shared)
//   Service → background daemon + IPC server, hosts the engine (executable)
//   GUI     → SwiftUI configuration app, IPC client (executable)
let package = Package(
    name: "MouseStudio",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MouseStudioShared", targets: ["MouseStudioShared"]),
        .library(name: "MouseStudioCore", targets: ["MouseStudioCore"]),
        .library(name: "MouseStudioActions", targets: ["MouseStudioActions"]),
        .library(name: "MouseStudioConfig", targets: ["MouseStudioConfig"]),
        .executable(name: "mousestudio-service", targets: ["MouseStudioService"]),
        .executable(name: "mousestudio-gui", targets: ["MouseStudioGUI"])
    ],
    dependencies: [],
    targets: [
        // MARK: - Shared (foundation, zero internal dependencies)
        .target(
            name: "MouseStudioShared",
            dependencies: []
        ),

        // MARK: - Core engine (no UI)
        .target(
            name: "MouseStudioCore",
            dependencies: ["MouseStudioShared"]
        ),

        // MARK: - Actions
        .target(
            name: "MouseStudioActions",
            dependencies: ["MouseStudioCore", "MouseStudioShared"]
        ),

        // MARK: - Config store
        .target(
            name: "MouseStudioConfig",
            dependencies: ["MouseStudioShared"]
        ),

        // MARK: - Background service (executable)
        .executableTarget(
            name: "MouseStudioService",
            dependencies: [
                "MouseStudioCore",
                "MouseStudioActions",
                "MouseStudioConfig",
                "MouseStudioShared"
            ]
        ),

        // MARK: - GUI app (executable; SwiftUI wired in Phase 5)
        .executableTarget(
            name: "MouseStudioGUI",
            dependencies: [
                "MouseStudioConfig",
                "MouseStudioShared"
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "CoreTests",
            dependencies: ["MouseStudioCore", "MouseStudioShared"]
        ),
        .testTarget(
            name: "ConfigTests",
            dependencies: ["MouseStudioConfig", "MouseStudioShared"]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "MouseStudioCore",
                "MouseStudioActions",
                "MouseStudioConfig",
                "MouseStudioShared"
            ]
        )
    ]
)
