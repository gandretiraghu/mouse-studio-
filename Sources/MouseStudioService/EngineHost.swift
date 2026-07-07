import Foundation
import MouseStudioCore
import MouseStudioActions
import MouseStudioConfig
import MouseStudioShared

/// Owns the automation engine and its dependencies inside the background
/// service: loads config + profiles, wires action providers, gates start on
/// Accessibility permission, and services lifecycle/reload/learning requests
/// (TDD §4, §5.1, §7.4, §12).
///
/// Dependencies are injected so the host is unit-testable with a simulated
/// event source, a stub permission checker, spy providers, and a temp config
/// directory. `makeSystem` builds the production wiring.
public final class EngineHost {
    private let store: ConfigStoring
    private let engine: Engine
    private let deviceManager: DeviceManager
    private let permission: PermissionChecking
    private let logger: Logger

    private(set) public var status: EngineStatus = .stopped

    /// Forwarded detected buttons during learning mode (for the Live Tester).
    public var onLearningButton: ((ButtonID) -> Void)? {
        didSet { engine.onLearningButton = onLearningButton }
    }
    /// Notified whenever `status` changes (for menu bar / IPC push).
    public var onStatusChange: ((EngineStatus) -> Void)?

    public init(
        store: ConfigStoring,
        eventSource: EventSource,
        scheduler: Scheduler,
        deviceProfiles: [DeviceProfile] = [],
        providers: [ActionProvider],
        permission: PermissionChecking,
        logger: Logger
    ) {
        self.store = store
        self.permission = permission
        self.logger = logger
        self.engine = Engine(eventSource: eventSource, scheduler: scheduler, logger: logger)
        self.deviceManager = DeviceManager(profiles: deviceProfiles, logger: logger)
        for provider in providers {
            engine.dispatcher.register(provider)
        }
    }

    // MARK: Lifecycle

    /// Bootstrap config, load rules, detect device, and (if permitted) start the tap.
    @discardableResult
    public func startup() -> EngineStatus {
        do {
            try (store as? FileConfigStore)?.bootstrapIfNeeded()
            try applyConfig()
        } catch {
            logger.error("Config load failed: \(error)", subsystem: "host")
        }

        deviceManager.detectActiveProfile()

        guard permission.isAccessibilityTrusted() else {
            logger.warn("Accessibility permission required; not starting event tap", subsystem: "host")
            permission.promptForAccessibility()
            setStatus(.permissionRequired)
            return status
        }

        do {
            try engine.start()
            setStatus(.running)
        } catch {
            logger.error("Engine start failed: \(error)", subsystem: "host")
            setStatus(.stopped)
        }
        return status
    }

    public func stop() {
        engine.stop()
        setStatus(.stopped)
    }

    // MARK: Config

    /// Re-read config + active profile and apply to the running engine.
    public func reloadConfig() {
        setStatus(.reloading)
        do {
            try applyConfig()
            setStatus(engine.isPaused ? .running : (permission.isAccessibilityTrusted() ? .running : .permissionRequired))
        } catch {
            logger.error("Reload failed: \(error)", subsystem: "host")
            setStatus(.running)
        }
    }

    public func setActiveProfile(_ id: String) {
        do {
            var config = try store.loadConfig()
            config.activeProfile = id
            try store.saveConfig(config)
            reloadConfig()
        } catch {
            logger.error("setActiveProfile failed: \(error)", subsystem: "host")
        }
    }

    public func availableProfiles() -> [Profile] {
        (try? store.loadProfiles()) ?? []
    }

    private func applyConfig() throws {
        let config = try store.loadConfig()
        logger.setLevel(config.logging.level)
        let profiles = try store.loadProfiles()
        let active = profiles.first { $0.id == config.activeProfile }
        let rules = active?.rules ?? []
        engine.reload(rules: rules, timing: config.timing)
        logger.info("Applied profile '\(config.activeProfile)' with \(rules.count) rule(s)", subsystem: "host")
    }

    // MARK: Pause / resume

    public func pause() {
        engine.isPaused = true
        logger.info("Engine paused", subsystem: "host")
    }

    public func resume() {
        engine.isPaused = false
        logger.info("Engine resumed", subsystem: "host")
    }

    public var isPaused: Bool { engine.isPaused }

    // MARK: Learning mode

    public func enterLearningMode() {
        engine.onLearningButton = onLearningButton
        engine.enterLearningMode()
        setStatus(.learning)
    }

    public func exitLearningMode() {
        engine.exitLearningMode()
        setStatus(.running)
    }

    // MARK: Introspection

    public func recentLogs(limit: Int) -> [LogEntry] {
        logger.recent(limit)
    }

    /// Dry-run a rule against a temporary engine (no side effects) — TDD §19.4.
    public func testRule(_ rule: Rule) -> TestResult {
        let ruleEngine = RuleEngine()
        ruleEngine.load([rule])
        let t = rule.trigger
        let gesture = Gesture(
            anchor: t.button,
            kind: t.gesture,
            chordButton: t.gesture == .chordClick ? t.chordWith : nil,
            scroll: t.gesture == .chordScrollUp ? .up : (t.gesture == .chordScrollDown ? .down : nil)
        )
        if let matched = ruleEngine.match(gesture) {
            return TestResult(matched: true, actionType: matched.action.type)
        }
        return TestResult(matched: false, error: "rule did not match its own trigger")
    }

    // MARK: Private

    private func setStatus(_ new: EngineStatus) {
        guard new != status else { return }
        status = new
        onStatusChange?(new)
    }
}
