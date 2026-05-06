import AppKit
import Foundation
import KeyRouteKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settingsStore = SettingsStore()
    private let inputSwitcher = InputSourceSwitcher()
    private let focusMonitor = FocusMonitor()
    private let statusBarController = StatusBarController()

    private var rulesWindowController: RulesWindowController?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        wireActions()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange(_:)),
            name: .keyRouteSettingsDidChange,
            object: settingsStore
        )

        focusMonitor.onContextChanged = { [weak self] context in
            self?.apply(context: context)
        }

        _ = focusMonitor.requestAccessibilityPermission(prompt: false)
        focusMonitor.start()
        renderStatus()
    }

    func applicationWillTerminate(_ notification: Notification) {
        focusMonitor.stop()
    }

    private func wireActions() {
        statusBarController.onToggleEnabled = { [weak self] isEnabled in
            self?.settingsStore.setEnabled(isEnabled)
        }

        statusBarController.onAddFocusedApp = { [weak self] in
            self?.addFocusedAppRule()
        }

        statusBarController.onAddFocusedWindow = { [weak self] in
            self?.addFocusedWindowRule()
        }

        statusBarController.onOpenRules = { [weak self] in
            self?.openRulesWindow()
        }

        statusBarController.onGrantAccessibility = { [weak self] in
            guard let self else {
                return
            }
            _ = self.focusMonitor.requestAccessibilityPermission(prompt: true)
            self.focusMonitor.openAccessibilitySettings()
            self.renderStatus()
        }

        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }
    }

    private func apply(context: KeyboardContext) {
        let settings = settingsStore.settings

        guard settings.isEnabled else {
            renderStatus()
            return
        }

        let target = RuleEngine.target(for: context, settings: settings)
        let targetInputSourceID = RuleEngine.inputSourceID(for: target, settings: settings)
        let currentInputSourceID = inputSwitcher.currentInputSourceID()

        if currentInputSourceID != targetInputSourceID {
            _ = inputSwitcher.selectInputSource(id: targetInputSourceID)
        }

        renderStatus()
    }

    private func renderStatus() {
        let context = focusMonitor.currentContext
        let target = context.map { RuleEngine.target(for: $0, settings: settingsStore.settings) }
        statusBarController.render(
            context: context,
            target: target,
            currentInputSourceID: inputSwitcher.currentInputSourceID(),
            isEnabled: settingsStore.settings.isEnabled,
            isAccessibilityTrusted: focusMonitor.isAccessibilityTrusted
        )
    }

    private func addFocusedAppRule() {
        focusMonitor.refreshNow()
        guard let context = focusMonitor.currentContext else {
            NSSound.beep()
            return
        }
        settingsStore.addRule(.appRule(from: context))
        apply(context: context)
    }

    private func addFocusedWindowRule() {
        focusMonitor.refreshNow()
        guard let context = focusMonitor.currentContext,
              let rule = WhitelistRule.windowRule(from: context, matchKind: .windowTitleContains) else {
            NSSound.beep()
            return
        }
        settingsStore.addRule(rule)
        apply(context: context)
    }

    private func openRulesWindow() {
        if rulesWindowController == nil {
            rulesWindowController = RulesWindowController(
                settingsStore: settingsStore,
                focusMonitor: focusMonitor
            )
        }

        rulesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func settingsDidChange(_ notification: Notification) {
        if let context = focusMonitor.currentContext {
            apply(context: context)
        } else {
            renderStatus()
        }
    }
}
