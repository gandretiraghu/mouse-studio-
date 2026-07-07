import Foundation
import MouseStudioCore
import MouseStudioActions
import MouseStudioConfig
import MouseStudioShared

#if canImport(CoreGraphics)
import CoreGraphics
#endif

public extension EngineHost {
    /// Build the production host: real config store, event tap on the main run
    /// loop, real action providers, and the Accessibility permission checker.
    static func makeSystem(
        configRoot: URL? = nil,
        deviceProfilesDirectory: URL? = nil,
        logger: Logger = Logger(level: .info)
    ) -> EngineHost {
        let paths = configRoot.map { ConfigPaths(root: $0) } ?? ConfigPaths.defaultUserPaths()
        let store = FileConfigStore(paths: paths)

        let deviceProfiles = deviceProfilesDirectory
            .map { DeviceProfileStore(directory: $0).load() } ?? []

        // The event tap must run on a run loop; in the menu-bar app that's main.
        #if canImport(CoreGraphics)
        let eventSource: EventSource = EventTap(runLoop: CFRunLoopGetMain())
        #else
        let eventSource: EventSource = SimulatedEventSource()
        #endif
        let scheduler = RealScheduler(queue: .main)

        return EngineHost(
            store: store,
            eventSource: eventSource,
            scheduler: scheduler,
            deviceProfiles: deviceProfiles,
            providers: MouseStudioActions.makeDefaultProviders(),
            permission: SystemPermissionChecker(),
            logger: logger
        )
    }
}
