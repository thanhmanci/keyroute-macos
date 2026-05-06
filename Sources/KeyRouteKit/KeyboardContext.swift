import Foundation

public struct KeyboardContext: Codable, Equatable, Hashable {
    public var processID: Int32
    public var appName: String
    public var bundleIdentifier: String?
    public var windowTitle: String?

    public init(
        processID: Int32,
        appName: String,
        bundleIdentifier: String?,
        windowTitle: String?
    ) {
        self.processID = processID
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier?.nilIfBlank
        self.windowTitle = windowTitle?.nilIfBlank
    }

    public var appDisplayName: String {
        if !appName.isEmpty {
            return appName
        }
        return bundleIdentifier ?? "Unknown App"
    }

    public var windowDisplayTitle: String {
        windowTitle ?? "No focused window title"
    }
}

public struct WindowSnapshot: Codable, Equatable, Hashable {
    public var processID: Int32
    public var appName: String
    public var bundleIdentifier: String?
    public var windowTitle: String?

    public init(
        processID: Int32,
        appName: String,
        bundleIdentifier: String?,
        windowTitle: String?
    ) {
        self.processID = processID
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier?.nilIfBlank
        self.windowTitle = windowTitle?.nilIfBlank
    }

    public var asContext: KeyboardContext {
        KeyboardContext(
            processID: processID,
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            windowTitle: windowTitle
        )
    }
}

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
