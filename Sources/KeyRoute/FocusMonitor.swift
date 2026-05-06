import AppKit
import ApplicationServices
import Foundation
import KeyRouteKit

final class FocusMonitor {
    var onContextChanged: ((KeyboardContext) -> Void)?
    private(set) var currentContext: KeyboardContext?

    private var pollTimer: Timer?
    private var pendingRefresh = false
    private var axObserver: AXObserver?
    private var observedPID: pid_t?

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func start() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(frontmostApplicationDidChange(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        pollTimer?.tolerance = 0.15

        refresh()
    }

    func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        pollTimer?.invalidate()
        pollTimer = nil
        uninstallAXObserver()
    }

    func requestAccessibilityPermission(prompt: Bool) -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func refreshNow() {
        refresh()
    }

    func visibleWindows() -> [WindowSnapshot] {
        let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
        guard let rawList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var snapshots: [WindowSnapshot] = []
        var seen = Set<String>()

        for item in rawList {
            guard let layer = item[kCGWindowLayer as String] as? Int,
                  layer == 0,
                  let pidNumber = item[kCGWindowOwnerPID as String] as? NSNumber else {
                continue
            }

            let pid = pid_t(pidNumber.int32Value)
            let runningApp = NSRunningApplication(processIdentifier: pid)
            let appName = runningApp?.localizedName ?? item[kCGWindowOwnerName as String] as? String ?? "Unknown App"
            let bundleID = runningApp?.bundleIdentifier
            let title = (item[kCGWindowName as String] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = "\(pidNumber.int32Value)|\(bundleID ?? appName)|\(title ?? "")"

            guard !seen.contains(key) else {
                continue
            }

            seen.insert(key)
            snapshots.append(
                WindowSnapshot(
                    processID: pidNumber.int32Value,
                    appName: appName,
                    bundleIdentifier: bundleID,
                    windowTitle: title
                )
            )
        }

        return snapshots.sorted {
            if $0.appName == $1.appName {
                return ($0.windowTitle ?? "") < ($1.windowTitle ?? "")
            }
            return $0.appName < $1.appName
        }
    }

    @objc private func frontmostApplicationDidChange(_ notification: Notification) {
        refreshSoon()
    }

    private func refreshSoon() {
        guard !pendingRefresh else {
            return
        }
        pendingRefresh = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
            guard let self else {
                return
            }
            self.pendingRefresh = false
            self.refresh()
        }
    }

    private func refresh() {
        guard let context = captureCurrentContext() else {
            return
        }

        installAXObserverIfNeeded(for: pid_t(context.processID))

        if context != currentContext {
            currentContext = context
            onContextChanged?(context)
        }
    }

    private func captureCurrentContext() -> KeyboardContext? {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let pid = app.processIdentifier
        let appName = app.localizedName ?? app.bundleIdentifier ?? "Unknown App"
        let title = focusedWindowTitle(for: pid)

        return KeyboardContext(
            processID: pid,
            appName: appName,
            bundleIdentifier: app.bundleIdentifier,
            windowTitle: title
        )
    }

    private func focusedWindowTitle(for pid: pid_t) -> String? {
        guard isAccessibilityTrusted else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(pid)
        var windowValue: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &windowValue
        )

        guard windowResult == .success,
              let windowValue,
              CFGetTypeID(windowValue) == AXUIElementGetTypeID() else {
            return nil
        }

        let windowElement = windowValue as! AXUIElement
        return axStringAttribute(windowElement, key: kAXTitleAttribute as CFString)
    }

    private func axStringAttribute(_ element: AXUIElement, key: CFString) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, key, &value)
        guard result == .success,
              let string = value as? String else {
            return nil
        }
        return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : string
    }

    private func installAXObserverIfNeeded(for pid: pid_t) {
        guard isAccessibilityTrusted else {
            uninstallAXObserver()
            return
        }

        guard observedPID != pid else {
            return
        }

        uninstallAXObserver()

        var observer: AXObserver?
        let callback: AXObserverCallback = { _, _, _, refcon in
            guard let refcon else {
                return
            }
            let monitor = Unmanaged<FocusMonitor>.fromOpaque(refcon).takeUnretainedValue()
            monitor.refreshSoon()
        }

        guard AXObserverCreate(pid, callback, &observer) == .success,
              let observer else {
            return
        }

        let appElement = AXUIElementCreateApplication(pid)
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        AXObserverAddNotification(
            observer,
            appElement,
            kAXFocusedWindowChangedNotification as CFString,
            refcon
        )
        AXObserverAddNotification(
            observer,
            appElement,
            kAXMainWindowChangedNotification as CFString,
            refcon
        )
        AXObserverAddNotification(
            observer,
            appElement,
            kAXWindowCreatedNotification as CFString,
            refcon
        )

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observer),
            .defaultMode
        )

        axObserver = observer
        observedPID = pid
    }

    private func uninstallAXObserver() {
        guard let axObserver else {
            observedPID = nil
            return
        }

        CFRunLoopRemoveSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(axObserver),
            .defaultMode
        )

        self.axObserver = nil
        observedPID = nil
    }
}
