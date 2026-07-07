import Foundation
import MouseStudioShared

/// Backs the Live Mouse Tester. Enters learning mode on the service and lights up
/// buttons as they are physically pressed, recording which were detected
/// (TDD §7.3, §19). Testable by injecting a stub client that emits live buttons.
public final class MouseTesterViewModel: ObservableObject {
    private let ipc: IPCClient

    @Published public private(set) var isDetecting = false
    /// The most recently pressed button (for the highlight animation).
    @Published public private(set) var lastPressed: ButtonID?
    /// All buttons seen during the current detection session.
    @Published public private(set) var detected: Set<ButtonID> = []

    public init(ipc: IPCClient) {
        self.ipc = ipc
        self.ipc.onEvent = { [weak self] event in
            guard case .liveButton(let button) = event else { return }
            self?.handleLiveButton(button)
        }
    }

    public func startDetecting() {
        detected.removeAll()
        lastPressed = nil
        isDetecting = true
        _ = ipc.send(.enterLearningMode)
    }

    public func stopDetecting() {
        isDetecting = false
        _ = ipc.send(.exitLearningMode)
    }

    private func handleLiveButton(_ button: ButtonID) {
        guard isDetecting else { return }
        lastPressed = button
        detected.insert(button)
    }
}
