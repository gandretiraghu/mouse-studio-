import Foundation
import MouseStudioConfig
import MouseStudioShared

#if canImport(Combine)
import Combine
#endif

/// The GUI's central state: loads and mutates config + profiles through the
/// `ConfigStore` and notifies the service to reload after changes (TDD §4, §19).
///
/// This is deliberately UI-framework-light (an `ObservableObject` when Combine is
/// available) so its logic is unit-testable without rendering any views.
public final class AppState: ObservableObject {
    private let store: ConfigStoring
    private let ipc: IPCClient
    private let validator = ConfigValidator()

    @Published public private(set) var config: Config
    @Published public private(set) var profiles: [Profile]
    @Published public private(set) var lastError: String?

    public init(store: ConfigStoring, ipc: IPCClient) {
        self.store = store
        self.ipc = ipc
        // Bootstrap defaults if this is a fresh install.
        try? (store as? FileConfigStore)?.bootstrapIfNeeded()
        self.config = (try? store.loadConfig()) ?? Config(activeProfile: DefaultConfig.defaultProfileID)
        self.profiles = (try? store.loadProfiles()) ?? []
    }

    // MARK: Derived

    public var activeProfile: Profile? {
        profiles.first { $0.id == config.activeProfile }
    }

    public func profile(withID id: String) -> Profile? {
        profiles.first { $0.id == id }
    }

    // MARK: Loading

    public func reload() {
        config = (try? store.loadConfig()) ?? config
        profiles = (try? store.loadProfiles()) ?? profiles
    }

    // MARK: Profiles

    public func setActiveProfile(_ id: String) {
        config.activeProfile = id
        persistConfig()
    }

    public func addProfile(_ profile: Profile) {
        saveProfile(profile)
    }

    public func deleteProfile(id: String) {
        guard profiles.count > 1 else { lastError = "Cannot delete the last profile"; return }
        do {
            _ = try? store.snapshot()   // restore point before a destructive change
            try store.deleteProfile(id: id)
            profiles.removeAll { $0.id == id }
            if config.activeProfile == id, let first = profiles.first {
                config.activeProfile = first.id
                persistConfig()
            }
            notifyReload()
        } catch { lastError = "\(error)" }
    }

    // MARK: Rules (operate on a target profile, default = active)

    public func addRule(_ rule: Rule, toProfile profileID: String? = nil) {
        mutateProfile(profileID) { $0.rules.append(rule) }
    }

    public func updateRule(_ rule: Rule, inProfile profileID: String? = nil) {
        mutateProfile(profileID) { profile in
            if let idx = profile.rules.firstIndex(where: { $0.id == rule.id }) {
                profile.rules[idx] = rule
            }
        }
    }

    public func deleteRule(id: String, fromProfile profileID: String? = nil) {
        mutateProfile(profileID) { $0.rules.removeAll { $0.id == id } }
    }

    public func setRuleEnabled(id: String, enabled: Bool, inProfile profileID: String? = nil) {
        mutateProfile(profileID) { profile in
            if let idx = profile.rules.firstIndex(where: { $0.id == id }) {
                profile.rules[idx].enabled = enabled
            }
        }
    }

    // MARK: Validation

    public func conflicts(inProfile profileID: String? = nil) -> [ValidationError] {
        guard let profile = targetProfile(profileID) else { return [] }
        return validator.conflicts(in: profile)
    }

    /// Rule ids that lose a conflict (shadowed) — used to badge the list.
    public func conflictingRuleIDs(inProfile profileID: String? = nil) -> Set<String> {
        var ids = Set<String>()
        for case .conflict(let ruleIDs) in conflicts(inProfile: profileID) {
            ids.formUnion(ruleIDs)
        }
        return ids
    }

    // MARK: Import / Export / Backup

    public func exportBundle(to url: URL) {
        do { try store.exportBundle(to: url) } catch { lastError = "\(error)" }
    }

    public func importBundle(from url: URL) {
        do {
            _ = try store.importBundle(from: url)
            reload()
            notifyReload()
        } catch { lastError = "Import failed: \(error)" }
    }

    public func backups() -> [BackupInfo] { store.listBackups() }

    public func restore(_ backup: BackupInfo) {
        do { try store.restore(backup); reload(); notifyReload() }
        catch { lastError = "Restore failed: \(error)" }
    }

    // MARK: - Private

    private func targetProfile(_ profileID: String?) -> Profile? {
        let id = profileID ?? config.activeProfile
        return profiles.first { $0.id == id }
    }

    private func mutateProfile(_ profileID: String?, _ transform: (inout Profile) -> Void) {
        let id = profileID ?? config.activeProfile
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        var profile = profiles[idx]
        transform(&profile)
        profiles[idx] = profile
        saveProfile(profile)
    }

    private func saveProfile(_ profile: Profile) {
        do {
            if !profiles.contains(where: { $0.id == profile.id }) {
                profiles.append(profile)
            }
            try store.saveProfile(profile)
            notifyReload()
        } catch { lastError = "\(error)" }
    }

    private func persistConfig() {
        do { try store.saveConfig(config); notifyReload() }
        catch { lastError = "\(error)" }
    }

    private func notifyReload() {
        _ = ipc.send(.reloadConfig)
    }
}
