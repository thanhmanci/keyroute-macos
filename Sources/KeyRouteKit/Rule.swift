import Foundation

public enum RuleMatchKind: String, Codable, CaseIterable, Equatable {
    case application
    case windowTitleContains
    case windowTitleExact

    public var displayName: String {
        switch self {
        case .application:
            return "App"
        case .windowTitleContains:
            return "Window contains"
        case .windowTitleExact:
            return "Window exact"
        }
    }
}

public struct WhitelistRule: Codable, Equatable, Identifiable {
    public var id: UUID
    public var appName: String
    public var bundleIdentifier: String?
    public var matchKind: RuleMatchKind
    public var windowTitle: String?
    public var isEnabled: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        appName: String,
        bundleIdentifier: String?,
        matchKind: RuleMatchKind,
        windowTitle: String?,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier?.nilIfBlank
        self.matchKind = matchKind
        self.windowTitle = windowTitle?.nilIfBlank
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    public static func appRule(from context: KeyboardContext) -> WhitelistRule {
        WhitelistRule(
            appName: context.appDisplayName,
            bundleIdentifier: context.bundleIdentifier,
            matchKind: .application,
            windowTitle: nil
        )
    }

    public static func windowRule(
        from context: KeyboardContext,
        matchKind: RuleMatchKind = .windowTitleContains
    ) -> WhitelistRule? {
        guard matchKind != .application else {
            return appRule(from: context)
        }
        guard let title = context.windowTitle?.nilIfBlank else {
            return nil
        }
        return WhitelistRule(
            appName: context.appDisplayName,
            bundleIdentifier: context.bundleIdentifier,
            matchKind: matchKind,
            windowTitle: title
        )
    }

    public func matches(_ context: KeyboardContext) -> Bool {
        guard isEnabled else {
            return false
        }

        if let ruleBundleID = bundleIdentifier {
            guard context.bundleIdentifier == ruleBundleID else {
                return false
            }
        } else {
            guard context.appDisplayName.compare(appName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame else {
                return false
            }
        }

        switch matchKind {
        case .application:
            return true
        case .windowTitleContains:
            guard let expected = windowTitle?.nilIfBlank,
                  let actual = context.windowTitle?.nilIfBlank else {
                return false
            }
            return actual.range(of: expected, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        case .windowTitleExact:
            guard let expected = windowTitle?.nilIfBlank,
                  let actual = context.windowTitle?.nilIfBlank else {
                return false
            }
            return actual.compare(expected, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    public func isDuplicate(of other: WhitelistRule) -> Bool {
        bundleIdentifier == other.bundleIdentifier &&
            appName.caseInsensitiveCompare(other.appName) == .orderedSame &&
            matchKind == other.matchKind &&
            (windowTitle ?? "").caseInsensitiveCompare(other.windowTitle ?? "") == .orderedSame
    }
}
