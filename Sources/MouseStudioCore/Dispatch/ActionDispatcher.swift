import Foundation
import MouseStudioShared

/// Routes an `ActionSpec` to the provider that owns its namespace and executes
/// it, timing the call and logging the result. Unknown namespaces are ignored
/// (never fatal) — TDD §5.1, §15.
public final class ActionDispatcher {
    private var providers: [String: ActionProvider] = [:]
    private let logger: Logger

    public init(logger: Logger) {
        self.logger = logger
    }

    /// Register a provider. If two providers claim the same namespace, the last
    /// one wins (a warning is logged).
    public func register(_ provider: ActionProvider) {
        if providers[provider.namespace] != nil {
            logger.warn("Provider namespace '\(provider.namespace)' registered more than once; overriding", subsystem: "dispatch")
        }
        providers[provider.namespace] = provider
    }

    public func registeredNamespaces() -> [String] {
        Array(providers.keys).sorted()
    }

    /// All action descriptors across all registered providers (for the GUI).
    public func allSupportedActions() -> [ActionDescriptor] {
        providers.values.flatMap { $0.supportedActions() }
    }

    /// Dispatch an action. Returns the provider's result, or `.ignored` if no
    /// provider owns the namespace.
    @discardableResult
    public func dispatch(_ spec: ActionSpec) -> ActionResult {
        let start = DispatchTime.now().uptimeNanoseconds
        guard let provider = providers[spec.namespace] else {
            let reason = "no provider for namespace '\(spec.namespace)'"
            logger.debug("Ignored action \(spec.type): \(reason)", subsystem: "dispatch")
            return .ignored(reason: reason)
        }

        let result = provider.perform(spec)
        logger.perf("dispatch \(spec.type)", since: start, subsystem: "perf")

        switch result {
        case .ok:
            logger.info("Performed \(spec.type)", subsystem: "dispatch")
        case .ignored(let reason):
            logger.debug("Ignored \(spec.type): \(reason)", subsystem: "dispatch")
        case .failed(let error):
            logger.error("Action \(spec.type) failed: \(error)", subsystem: "dispatch")
        }
        return result
    }
}
