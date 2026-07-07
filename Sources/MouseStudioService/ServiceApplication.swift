import Foundation
import MouseStudioCore
import MouseStudioConfig
import MouseStudioShared

#if canImport(AppKit)
import AppKit

/// Runs the background service as a menu-bar (accessory) application: builds the
/// production `EngineHost`, starts it, installs the status-bar menu, and enters
/// the main run loop (which drives the CGEvent tap) — TDD §4, §11.
public final class ServiceApplication: NSObject, NSApplicationDelegate {
    private var host: EngineHost!
    private var menuBar: MenuBarController!
    private var configWatchers: [ConfigWatcher] = []
    private var ipcServer: SocketIPCServer?
    private let logger = Logger(level: .info)

    public static func run() -> Never {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)   // LSUIElement: no Dock icon
        let delegate = ServiceApplication()
        app.delegate = delegate
        app.run()
        exit(0)
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        logger.sink = { entry in
            FileHandle.standardError.write(Data("[\(entry.level.label)] \(entry.subsystem): \(entry.message)\n".utf8))
        }

        let deviceProfilesDir = Self.bundledDeviceProfilesDirectory()
        host = EngineHost.makeSystem(deviceProfilesDirectory: deviceProfilesDir, logger: logger)
        menuBar = MenuBarController(host: host)

        let status = host.startup()
        if status == .permissionRequired {
            logger.warn("Grant Accessibility in System Settings › Privacy & Security, then reopen.", subsystem: "app")
        }

        // Apply GUI config edits live by watching both the config root (config.json)
        // and the profiles subdirectory (rule files live there).
        let paths = ConfigPaths.defaultUserPaths()
        let reload: () -> Void = { [weak self] in self?.host.reloadConfig() }
        let rootWatcher = ConfigWatcher(directory: paths.root, onChange: reload)
        let profilesWatcher = ConfigWatcher(directory: paths.profilesDir, onChange: reload)
        rootWatcher.start()
        profilesWatcher.start()
        configWatchers = [rootWatcher, profilesWatcher]

        // Start the IPC server so the GUI can drive status, live tester, and logs.
        let server = SocketIPCServer(host: host)
        do {
            try server.start()
            ipcServer = server
            logger.info("IPC server listening", subsystem: "app")
        } catch {
            logger.error("IPC server failed to start: \(error)", subsystem: "app")
        }
    }

    /// Locate device profiles shipped next to the executable or in the app bundle.
    private static func bundledDeviceProfilesDirectory() -> URL? {
        if let resourceURL = Bundle.main.resourceURL {
            let candidate = resourceURL.appendingPathComponent("DeviceProfiles", isDirectory: true)
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }
}
#endif
