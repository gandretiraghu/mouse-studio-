import Foundation
import MouseStudioShared

/// Fetches recent engine logs from the service for the Logs view (TDD §15).
public final class LogsViewModel: ObservableObject {
    private let ipc: IPCClient
    @Published public private(set) var entries: [LogEntry] = []

    public init(ipc: IPCClient) {
        self.ipc = ipc
    }

    public func refresh(limit: Int = 200) {
        if case .logs(let entries) = ipc.send(.getRecentLogs(limit: limit)) {
            self.entries = entries
        }
    }
}
