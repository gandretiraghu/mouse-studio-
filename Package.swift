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
        .macOS(.v14)
    ],
    products: [
        .library(name: "MouseStudioShared", targets: ["MouseStudioShared"]),
        .library(name: "MouseStudioCore", targets: ["MouseStudioCore"]),
        .library(name: "MouseStudioActions", targets: ["MouseStudioActions"]),
        .library(name: "MouseStudioConfig", targets: ["MouseStudioConfig"]),
        .library(name: "MouseStudioService", targets: ["MouseStudioService"]),
        .library(name: "MouseStudioGUI", targets: ["MouseStudioGUI"]),
        .executable(name: "mousestudio-service", targets: ["MouseStudioServiceApp"]),
        .executable(name: "mousestudio-gui", targets: ["MouseStudioGUIApp"])
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

        // MARK: - Background service (library: EngineHost, IPC, menu bar)
        .target(
            name: "MouseStudioService",
            dependencies: [
                "MouseStudioCore",
                "MouseStudioActions",
                "MouseStudioConfig",
                "MouseStudioShared"
            ]
        ),

        // MARK: - Background service (thin executable)
        .executableTarget(
            name: "MouseStudioServiceApp",
            dependencies: ["MouseStudioService"]
        ),

        // MARK: - GUI (library: SwiftUI views + testable view models)
        .target(
            name: "MouseStudioGUI",
            dependencies: [
                "MouseStudioConfig",
                "MouseStudioShared"
            ]
        ),

        // MARK: - GUI (thin executable; @main App)
        .executableTarget(
            name: "MouseStudioGUIApp",
            dependencies: ["MouseStudioGUI"]
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
        ),
        .testTarget(
            name: "ActionsTests",
            dependencies: ["MouseStudioActions", "MouseStudioShared"]
        ),
        .testTarget(
            name: "ServiceTests",
            dependencies: ["MouseStudioService", "MouseStudioShared"]
        ),
        .testTarget(
            name: "GUITests",
            dependencies: ["MouseStudioGUI", "MouseStudioConfig", "MouseStudioShared"]
        )
    ]
)
