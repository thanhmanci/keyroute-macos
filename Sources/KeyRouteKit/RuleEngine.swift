import Foundation

public enum InputTarget: String, Codable, Equatable {
    case english
    case vietnamese

    public var shortLabel: String {
        switch self {
        case .english:
            return "EN"
        case .vietnamese:
            return "VI"
        }
    }
}

public struct KeyRouteSettings: Codable, Equatable {
    public static let defaultEnglishInputSourceID = "com.apple.keylayout.ABC"
    public static let defaultVietnameseInputSourceID = "com.apple.inputmethod.VietnameseIM.VietnameseSimpleTelex"

    public var isEnabled: Bool
    public var englishInputSourceID: String
    public var vietnameseInputSourceID: String
    public var whitelistRules: [WhitelistRule]

    public init(
        isEnabled: Bool = true,
        englishInputSourceID: String = Self.defaultEnglishInputSourceID,
        vietnameseInputSourceID: String = Self.defaultVietnameseInputSourceID,
        whitelistRules: [WhitelistRule] = []
    ) {
        self.isEnabled = isEnabled
        self.englishInputSourceID = englishInputSourceID
        self.vietnameseInputSourceID = vietnameseInputSourceID
        self.whitelistRules = whitelistRules
    }
}

public enum RuleEngine {
    public static func target(for context: KeyboardContext, settings: KeyRouteSettings) -> InputTarget {
        let matchesWhitelist = settings.whitelistRules.contains { $0.matches(context) }
        return matchesWhitelist ? .vietnamese : .english
    }

    public static func inputSourceID(for target: InputTarget, settings: KeyRouteSettings) -> String {
        switch target {
        case .english:
            return settings.englishInputSourceID
        case .vietnamese:
            return settings.vietnameseInputSourceID
        }
    }
}
