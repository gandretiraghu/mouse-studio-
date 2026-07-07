import Foundation

/// The well-known Unix domain socket the service listens on and the GUI connects
/// to. A user-owned socket file (not a network port) keeps IPC local and private
/// (TDD §13).
public enum IPCSocketPath {
    public static func `default`(fileManager: FileManager = .default) -> String {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("MouseStudio/service.sock").path
    }
}
