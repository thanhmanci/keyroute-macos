import AppKit
import Foundation
import KeyRouteKit

final class StatusBarController: NSObject {
    var onToggleEnabled: ((Bool) -> Void)?
    var onAddFocusedApp: (() -> Void)?
    var onAddFocusedWindow: (() -> Void)?
    var onOpenRules: (() -> Void)?
    var onGrantAccessibility: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()

    private let contextItem = NSMenuItem(title: "No focused app", action: nil, keyEquivalent: "")
    private let routeItem = NSMenuItem(title: "Route: Unknown", action: nil, keyEquivalent: "")
    private let inputItem = NSMenuItem(title: "Input source: Unknown", action: nil, keyEquivalent: "")
    private let enabledItem = NSMenuItem(title: "Auto switch", action: #selector(toggleEnabled(_:)), keyEquivalent: "")
    private let accessibilityItem = NSMenuItem(title: "Grant Accessibility Permission", action: #selector(grantAccessibility(_:)), keyEquivalent: "")
    private let addAppItem = NSMenuItem(title: "Add Focused App to Vietnamese Whitelist", action: #selector(addFocusedApp(_:)), keyEquivalent: "")
    private let addWindowItem = NSMenuItem(title: "Add Focused Window to Vietnamese Whitelist", action: #selector(addFocusedWindow(_:)), keyEquivalent: "")
    private let manageItem = NSMenuItem(title: "Manage Whitelist...", action: #selector(openRules(_:)), keyEquivalent: ",")
    private let quitItem = NSMenuItem(title: "Quit KeyRoute", action: #selector(quit(_:)), keyEquivalent: "q")

    private var enabled = true

    override init() {
        super.init()
        buildMenu()
    }

    func render(
        context: KeyboardContext?,
        target: InputTarget?,
        currentInputSourceID: String?,
        isEnabled: Bool,
        isAccessibilityTrusted: Bool
    ) {
        enabled = isEnabled

        statusItem.button?.toolTip = tooltip(context: context, target: target, isEnabled: isEnabled)

        enabledItem.state = isEnabled ? .on : .off

        if let context {
            contextItem.title = "\(context.appDisplayName): \(shorten(context.windowDisplayTitle, maxLength: 72))"
        } else {
            contextItem.title = "No focused app"
        }

        if isEnabled {
            routeItem.title = "Route: \(routeName(for: target))"
        } else {
            routeItem.title = "Route: Off"
        }

        if let currentInputSourceID {
            inputItem.title = "Input source: \(currentInputSourceID)"
        } else {
            inputItem.title = "Input source: Unknown"
        }

        accessibilityItem.title = isAccessibilityTrusted ? "Accessibility Permission: Granted" : "Grant Accessibility Permission"
        accessibilityItem.isEnabled = !isAccessibilityTrusted

        addAppItem.isEnabled = context != nil
        addWindowItem.isEnabled = context?.windowTitle != nil
    }

    private func buildMenu() {
        contextItem.isEnabled = false
        routeItem.isEnabled = false
        inputItem.isEnabled = false

        for item in [enabledItem, accessibilityItem, addAppItem, addWindowItem, manageItem, quitItem] {
            item.target = self
        }

        menu.addItem(contextItem)
        menu.addItem(routeItem)
        menu.addItem(inputItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(enabledItem)
        menu.addItem(accessibilityItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(addAppItem)
        menu.addItem(addWindowItem)
        menu.addItem(manageItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitItem)

        configureStatusButton()
        statusItem.menu = menu
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        button.title = ""
        button.image = StatusBarIcon.make()
        button.imagePosition = .imageOnly
    }

    private func tooltip(context: KeyboardContext?, target: InputTarget?, isEnabled: Bool) -> String {
        guard isEnabled else {
            return "KeyRoute auto switch is off"
        }

        let targetName = target == .vietnamese ? "Vietnamese Telex" : "English ABC"
        if let context {
            return "\(targetName) for \(context.appDisplayName)"
        }
        return "KeyRoute: \(targetName)"
    }

    private func routeName(for target: InputTarget?) -> String {
        switch target {
        case .english:
            return "English ABC"
        case .vietnamese:
            return "Vietnamese Telex"
        case nil:
            return "Unknown"
        }
    }

    private func shorten(_ value: String, maxLength: Int) -> String {
        guard value.count > maxLength else {
            return value
        }
        let index = value.index(value.startIndex, offsetBy: maxLength)
        return String(value[..<index]) + "..."
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        onToggleEnabled?(!enabled)
    }

    @objc private func addFocusedApp(_ sender: NSMenuItem) {
        onAddFocusedApp?()
    }

    @objc private func addFocusedWindow(_ sender: NSMenuItem) {
        onAddFocusedWindow?()
    }

    @objc private func openRules(_ sender: NSMenuItem) {
        onOpenRules?()
    }

    @objc private func grantAccessibility(_ sender: NSMenuItem) {
        onGrantAccessibility?()
    }

    @objc private func quit(_ sender: NSMenuItem) {
        onQuit?()
    }
}
