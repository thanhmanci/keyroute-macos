import AppKit
import Foundation
import KeyRouteKit

final class RulesWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {
    private let settingsStore: SettingsStore
    private let focusMonitor: FocusMonitor

    private let statusLabel = NSTextField(labelWithString: "")
    private let windowPopup = NSPopUpButton()
    private let matchPopup = NSPopUpButton()
    private let tableView = NSTableView()
    private let autoSwitchCheckbox = NSButton(checkboxWithTitle: "Auto switch", target: nil, action: nil)
    private let removeButton = NSButton(title: "Remove Selected", target: nil, action: nil)
    private let refreshButton = NSButton(title: "Refresh Windows", target: nil, action: nil)
    private let grantButton = NSButton(title: "Grant Accessibility Permission", target: nil, action: nil)

    private var snapshots: [WindowSnapshot] = []

    init(settingsStore: SettingsStore, focusMonitor: FocusMonitor) {
        self.settingsStore = settingsStore
        self.focusMonitor = focusMonitor

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 460),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "KeyRoute Whitelist"
        window.minSize = NSSize(width: 640, height: 380)

        super.init(window: window)

        buildUI()
        observeSettings()
        reloadAll()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func showWindow(_ sender: Any?) {
        reloadAll()
        super.showWindow(sender)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        settingsStore.settings.whitelistRules.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < settingsStore.settings.whitelistRules.count,
              let identifier = tableColumn?.identifier.rawValue else {
            return nil
        }

        let rule = settingsStore.settings.whitelistRules[row]
        switch identifier {
        case "enabled":
            return rule.isEnabled ? "Yes" : "No"
        case "scope":
            return rule.matchKind.displayName
        case "app":
            return rule.appName
        case "bundle":
            return rule.bundleIdentifier ?? "-"
        case "title":
            return rule.windowTitle ?? "-"
        default:
            return nil
        }
    }

    private func buildUI() {
        guard let contentView = window?.contentView else {
            return
        }

        statusLabel.lineBreakMode = .byTruncatingMiddle

        matchPopup.addItem(withTitle: RuleMatchKind.windowTitleContains.displayName)
        matchPopup.lastItem?.representedObject = RuleMatchKind.windowTitleContains.rawValue
        matchPopup.addItem(withTitle: RuleMatchKind.windowTitleExact.displayName)
        matchPopup.lastItem?.representedObject = RuleMatchKind.windowTitleExact.rawValue

        let addWindowButton = NSButton(title: "Add Window Rule", target: self, action: #selector(addWindowRule(_:)))
        let addAppButton = NSButton(title: "Add App Rule", target: self, action: #selector(addAppRule(_:)))

        removeButton.target = self
        removeButton.action = #selector(removeSelectedRules(_:))
        refreshButton.target = self
        refreshButton.action = #selector(refreshWindows(_:))
        grantButton.target = self
        grantButton.action = #selector(grantAccessibility(_:))
        autoSwitchCheckbox.target = self
        autoSwitchCheckbox.action = #selector(toggleAutoSwitch(_:))

        let pickerStack = NSStackView(views: [windowPopup, matchPopup, addWindowButton, addAppButton])
        pickerStack.orientation = .horizontal
        pickerStack.spacing = 8
        pickerStack.alignment = .centerY
        windowPopup.setContentHuggingPriority(.defaultLow, for: .horizontal)
        matchPopup.widthAnchor.constraint(equalToConstant: 150).isActive = true

        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.headerView = NSTableHeaderView()

        addColumn(id: "enabled", title: "Enabled", width: 72)
        addColumn(id: "scope", title: "Scope", width: 120)
        addColumn(id: "app", title: "App", width: 130)
        addColumn(id: "bundle", title: "Bundle ID", width: 210)
        addColumn(id: "title", title: "Window Title", width: 260)

        let scrollView = NSScrollView()
        scrollView.borderType = .bezelBorder
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView

        let footerStack = NSStackView(views: [autoSwitchCheckbox, grantButton, NSView(), refreshButton, removeButton])
        footerStack.orientation = .horizontal
        footerStack.spacing = 8
        footerStack.alignment = .centerY

        let rootStack = NSStackView(views: [statusLabel, pickerStack, scrollView, footerStack])
        rootStack.orientation = .vertical
        rootStack.spacing = 12
        rootStack.alignment = .leading
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            statusLabel.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            pickerStack.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            scrollView.widthAnchor.constraint(equalTo: rootStack.widthAnchor),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 230),
            footerStack.widthAnchor.constraint(equalTo: rootStack.widthAnchor)
        ])
    }

    private func addColumn(id: String, title: String, width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
        column.title = title
        column.width = width
        tableView.addTableColumn(column)
    }

    private func observeSettings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange(_:)),
            name: .keyRouteSettingsDidChange,
            object: settingsStore
        )
    }

    private func reloadAll() {
        refreshContextLabel()
        refreshWindowPopup()
        refreshControls()
        tableView.reloadData()
    }

    private func refreshContextLabel() {
        focusMonitor.refreshNow()
        if let context = focusMonitor.currentContext {
            statusLabel.stringValue = "Focused: \(context.appDisplayName) - \(context.windowDisplayTitle)"
        } else {
            statusLabel.stringValue = "Focused: Unknown"
        }
    }

    private func refreshWindowPopup() {
        snapshots = focusMonitor.visibleWindows()
        if let context = focusMonitor.currentContext {
            let focusedSnapshot = WindowSnapshot(
                processID: context.processID,
                appName: context.appDisplayName,
                bundleIdentifier: context.bundleIdentifier,
                windowTitle: context.windowTitle
            )
            let alreadyPresent = snapshots.contains {
                $0.processID == focusedSnapshot.processID &&
                    $0.bundleIdentifier == focusedSnapshot.bundleIdentifier &&
                    $0.windowTitle == focusedSnapshot.windowTitle
            }
            if !alreadyPresent {
                snapshots.insert(focusedSnapshot, at: 0)
            }
        }

        windowPopup.removeAllItems()

        if snapshots.isEmpty {
            windowPopup.addItem(withTitle: "No visible windows found")
            windowPopup.isEnabled = false
            return
        }

        windowPopup.isEnabled = true
        for (index, snapshot) in snapshots.enumerated() {
            windowPopup.addItem(withTitle: popupTitle(for: snapshot))
            windowPopup.lastItem?.representedObject = index
        }

        if let context = focusMonitor.currentContext,
           let selectedIndex = snapshots.firstIndex(where: {
               $0.processID == context.processID && $0.windowTitle == context.windowTitle
           }) {
            windowPopup.selectItem(at: selectedIndex)
        }
    }

    private func refreshControls() {
        autoSwitchCheckbox.state = settingsStore.settings.isEnabled ? .on : .off
        grantButton.isEnabled = !focusMonitor.isAccessibilityTrusted
        grantButton.title = focusMonitor.isAccessibilityTrusted ? "Accessibility Granted" : "Grant Accessibility Permission"
    }

    private func selectedSnapshot() -> WindowSnapshot? {
        guard windowPopup.isEnabled,
              let index = windowPopup.selectedItem?.representedObject as? Int,
              snapshots.indices.contains(index) else {
            return nil
        }
        return snapshots[index]
    }

    private func selectedMatchKind() -> RuleMatchKind {
        guard let rawValue = matchPopup.selectedItem?.representedObject as? String,
              let kind = RuleMatchKind(rawValue: rawValue) else {
            return .windowTitleContains
        }
        return kind
    }

    private func popupTitle(for snapshot: WindowSnapshot) -> String {
        let title = snapshot.windowTitle ?? "No title"
        return "\(snapshot.appName) - \(shorten(title, maxLength: 96))"
    }

    private func shorten(_ value: String, maxLength: Int) -> String {
        guard value.count > maxLength else {
            return value
        }
        let index = value.index(value.startIndex, offsetBy: maxLength)
        return String(value[..<index]) + "..."
    }

    @objc private func settingsDidChange(_ notification: Notification) {
        refreshControls()
        tableView.reloadData()
    }

    @objc private func addWindowRule(_ sender: NSButton) {
        guard let snapshot = selectedSnapshot(),
              let rule = WhitelistRule.windowRule(from: snapshot.asContext, matchKind: selectedMatchKind()) else {
            NSSound.beep()
            return
        }
        settingsStore.addRule(rule)
    }

    @objc private func addAppRule(_ sender: NSButton) {
        guard let snapshot = selectedSnapshot() else {
            NSSound.beep()
            return
        }
        settingsStore.addRule(.appRule(from: snapshot.asContext))
    }

    @objc private func removeSelectedRules(_ sender: NSButton) {
        let indexes = tableView.selectedRowIndexes
        guard !indexes.isEmpty else {
            NSSound.beep()
            return
        }

        let rules = settingsStore.settings.whitelistRules
        let ids = Set(indexes.compactMap { index -> UUID? in
            guard rules.indices.contains(index) else {
                return nil
            }
            return rules[index].id
        })

        settingsStore.removeRules(withIDs: ids)
    }

    @objc private func refreshWindows(_ sender: NSButton) {
        reloadAll()
    }

    @objc private func grantAccessibility(_ sender: NSButton) {
        _ = focusMonitor.requestAccessibilityPermission(prompt: true)
        focusMonitor.openAccessibilitySettings()
        refreshControls()
    }

    @objc private func toggleAutoSwitch(_ sender: NSButton) {
        settingsStore.setEnabled(sender.state == .on)
    }
}
