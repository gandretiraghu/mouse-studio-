import Foundation

/// A cancellable handle for a scheduled piece of work.
public protocol ScheduledToken: AnyObject {
    func cancel()
}

/// Abstraction over delayed, cancellable work. The state machine depends on this
/// (not on real timers) so its timing behavior can be tested deterministically
/// with `ManualScheduler` (TDD §16.4).
public protocol Scheduler: AnyObject {
    /// Schedule `work` to run after `afterMs` milliseconds. Returns a token that
    /// can cancel the pending work before it fires.
    @discardableResult
    func schedule(afterMs: Int, _ work: @escaping () -> Void) -> ScheduledToken
}

// MARK: - Real scheduler (production)

/// Schedules work on a target `DispatchQueue` using cancellable work items.
public final class RealScheduler: Scheduler {
    private let queue: DispatchQueue

    public init(queue: DispatchQueue) {
        self.queue = queue
    }

    @discardableResult
    public func schedule(afterMs: Int, _ work: @escaping () -> Void) -> ScheduledToken {
        let item = DispatchWorkItem(block: work)
        queue.asyncAfter(deadline: .now() + .milliseconds(max(0, afterMs)), execute: item)
        return WorkItemToken(item)
    }

    private final class WorkItemToken: ScheduledToken {
        private let item: DispatchWorkItem
        init(_ item: DispatchWorkItem) { self.item = item }
        func cancel() { item.cancel() }
    }
}

// MARK: - Manual scheduler (tests)

/// A virtual-clock scheduler for deterministic tests. Work only runs when the
/// test advances time via `advance(byMs:)`.
public final class ManualScheduler: Scheduler {
    private final class Task: ScheduledToken {
        var fireAtMs: Int
        let work: () -> Void
        var cancelled = false
        init(fireAtMs: Int, work: @escaping () -> Void) {
            self.fireAtMs = fireAtMs
            self.work = work
        }
        func cancel() { cancelled = true }
    }

    private(set) public var nowMs: Int = 0
    private var tasks: [Task] = []

    public init() {}

    @discardableResult
    public func schedule(afterMs: Int, _ work: @escaping () -> Void) -> ScheduledToken {
        let task = Task(fireAtMs: nowMs + max(0, afterMs), work: work)
        tasks.append(task)
        return task
    }

    /// Advance the virtual clock, firing any due, non-cancelled tasks in order.
    public func advance(byMs delta: Int) {
        let target = nowMs + max(0, delta)
        while true {
            // Find the earliest due, non-cancelled task within [now, target].
            let due = tasks
                .filter { !$0.cancelled && $0.fireAtMs <= target }
                .min(by: { $0.fireAtMs < $1.fireAtMs })
            guard let task = due else { break }
            nowMs = task.fireAtMs
            tasks.removeAll { $0 === task }
            task.work()
        }
        nowMs = target
        tasks.removeAll { $0.cancelled }
    }
}
