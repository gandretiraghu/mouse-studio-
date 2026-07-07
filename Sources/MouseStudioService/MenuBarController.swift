import Foundation
import MouseStudioShared

#if canImport(AppKit)
import AppKit

/// The status-bar menu for the background service: shows engine status and lets
/// the user switch profiles, pause/resume, and quit (TDD §4).
public final class MenuBarController: NSObject, NSMenuDelegate {
    private let host: EngineHost
    private let statusItem: NSStatusItem
    private let openSettings: (() -> Void)?

    public init(host: EngineHost, openSettings: (() -> Void)? = nil) {
        self.host = host
        self.openSettings = openSettings
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "computermouse", accessibilityDescription: "Mouse Studio")
            button.image?.isTemplate = true
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        host.onStatusChange = { [weak self] _ in
            DispatchQueue.main.async { self?.rebuild() }
        }
        rebuild()
    }

    // Rebuild lazily whenever the menu opens so profiles/status stay fresh.
    public func menuNeedsUpdate(_ menu: NSMenu) {
        rebuild(into: menu)
    }

    private func rebuild() {
        if let menu = statusItem.menu { rebuild(into: menu) }
    }

    private func rebuild(into menu: NSMenu) {
        menu.removeAllItems()

        let statusText = "Status: \(host.status.rawValue)"
        let statusMenuItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        // Profiles submenu
        let profilesItem = NSMenuItem(title: "Profiles", action: nil, keyEquivalent: "")
        let profilesMenu = NSMenu()
        for profile in host.availableProfiles() {
            let item = NSMenuItem(title: profile.displayName, action: #selector(selectProfile(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = profile.id
            profilesMenu.addItem(item)
        }
        profilesItem.submenu = profilesMenu
        menu.addItem(profilesItem)

        let pauseTitle = host.isPaused ? "Resume" : "Pause"
        let pauseItem = NSMenuItem(title: pauseTitle, action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)

        if openSettings != nil {
            let settingsItem = NSMenuItem(title: "Open Settings…", action: #selector(openSettingsAction), keyEquivalent: ",")
            settingsItem.target = self
            menu.addItem(settingsItem)
        }

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Mouse Studio", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func selectProfile(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        host.setActiveProfile(id)
    }

    @objc private func togglePause() {
        host.isPaused ? host.resume() : host.pause()
        rebuild()
    }

    @objc private func openSettingsAction() {
        openSettings?()
    }

    @objc private func quit() {
        host.stop()
        NSApplication.shared.terminate(nil)
    }
}
#endif
