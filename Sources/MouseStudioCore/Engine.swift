import Foundation
import MouseStudioShared

/// The headless automation engine coordinator. Wires an `EventSource` through the
/// `StateMachine`, `RuleEngine`, and `ActionDispatcher` (TDD §3, §6). Owns no UI.
///
/// Concurrency: intended to run on a single serial queue. In production the
/// service provides that queue (and a `RealScheduler` bound to it); in tests a
/// `ManualScheduler` and `SimulatedEventSource` drive it synchronously.
public final class Engine {
    public let stateMachine: StateMachine
    public let ruleEngine: RuleEngine
    public let dispatcher: ActionDispatcher
    public let logger: Logger

    private var eventSource: EventSource
    private(set) public var status: EngineStatus = .stopped

    /// Learning mode: when set, resolved button presses are forwarded here
    /// (for the "Detect Mouse" Live Tester) instead of being dispatched.
    public var onLearningButton: ((ButtonID) -> Void)?
    private var learning = false

    /// When paused, events are dropped (no gesture resolution or dispatch). The
    /// event tap keeps running so pause/resume is instant.
    public var isPaused = false

    public init(
        eventSource: EventSource,
        scheduler: Scheduler,
        logger: Logger = Logger(),
        timing: TimingConfig = .default
    ) {
        self.eventSource = eventSource
        self.logger = logger
        self.ruleEngine = RuleEngine()
        self.dispatcher = ActionDispatcher(logger: logger)
        self.stateMachine = StateMachine(timing: timing, scheduler: scheduler)

        self.stateMachine.onGesture = { [weak self] gesture in
            self?.handle(gesture)
        }
        self.eventSource.onEvent = { [weak self] raw in
            self?.handle(raw)
        }
    }

    // MARK: Configuration

    /// Load rules and timing into the engine. Recomputes the double-mapped fast
    /// path. Safe to call while running (TDD §7.4).
    public func reload(rules: [Rule], timing: TimingConfig? = nil) {
        if let timing = timing { stateMachine.timing = timing }
        ruleEngine.load(rules)
        stateMachine.setDoubleMappedButtons(ruleEngine.doubleMappedButtons())
        eventSource.setOwnedButtons(ruleEngine.ownedButtons())
        logger.info("Loaded \(ruleEngine.ruleCount) rule(s); shadowed: \(ruleEngine.shadowedRuleIDs.count)", subsystem: "engine")
    }

    // MARK: Lifecycle

    public func start() throws {
        guard status == .stopped else { return }
        status = .starting
        do {
            try eventSource.start()
            status = .running
            logger.info("Engine started", subsystem: "engine")
        } catch {
            status = (error as? EventSourceError) == .accessibilityNotTrusted ? .permissionRequired : .stopped
            logger.error("Engine start failed: \(error)", subsystem: "engine")
            throw error
        }
    }

    public func stop() {
        guard status != .stopped else { return }
        eventSource.stop()
        stateMachine.reset()
        status = .stopped
        logger.info("Engine stopped", subsystem: "engine")
    }

    public func enterLearningMode() {
        learning = true
        status = .learning
        stateMachine.reset()
        logger.info("Entered learning mode", subsystem: "engine")
    }

    public func exitLearningMode() {
        learning = false
        status = .running
        logger.info("Exited learning mode", subsystem: "engine")
    }

    // MARK: Event handling

    /// Feed a raw event directly (used by tests and by the event source callback).
    public func handle(_ raw: RawEvent) {
        if isPaused { return }
        // In learning mode, report button-down events for the Live Tester and skip
        // gesture resolution entirely.
        if learning {
            if raw.type == .buttonDown, let button = raw.button {
                onLearningButton?(button)
            }
            return
        }
        stateMachine.feed(raw)
    }

    private func handle(_ gesture: Gesture) {
        guard let rule = ruleEngine.match(gesture) else {
            logger.debug("No rule for gesture \(gesture.kind.rawValue) on \(gesture.anchor.rawValue)", subsystem: "engine")
            return
        }
        dispatcher.dispatch(rule.action)
    }
}
