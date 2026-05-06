import Foundation
import KeyRouteKit

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

let zed = KeyboardContext(
    processID: 1,
    appName: "Zed",
    bundleIdentifier: "dev.zed.Zed",
    windowTitle: "main.swift"
)
let finder = KeyboardContext(
    processID: 2,
    appName: "Finder",
    bundleIdentifier: "com.apple.finder",
    windowTitle: "Documents"
)
let safari = KeyboardContext(
    processID: 3,
    appName: "Safari",
    bundleIdentifier: "com.apple.Safari",
    windowTitle: "OpenAI API Reference"
)

let appSettings = KeyRouteSettings(whitelistRules: [.appRule(from: zed)])
require(RuleEngine.target(for: zed, settings: appSettings) == .vietnamese, "app whitelist should target Vietnamese")
require(RuleEngine.target(for: finder, settings: appSettings) == .english, "outside whitelist should target English")

guard let containsRule = WhitelistRule.windowRule(from: safari, matchKind: .windowTitleContains) else {
    fputs("FAIL: expected window contains rule\n", stderr)
    exit(1)
}

let changedSafariTitle = KeyboardContext(
    processID: 3,
    appName: "Safari",
    bundleIdentifier: "com.apple.Safari",
    windowTitle: "Reading openai api reference - Safari"
)
require(containsRule.matches(changedSafariTitle), "contains rule should match case-insensitively")

guard let exactRule = WhitelistRule.windowRule(from: zed, matchKind: .windowTitleExact) else {
    fputs("FAIL: expected exact rule\n", stderr)
    exit(1)
}
let changedZedTitle = KeyboardContext(
    processID: 1,
    appName: "Zed",
    bundleIdentifier: "dev.zed.Zed",
    windowTitle: "README.md"
)
require(!exactRule.matches(changedZedTitle), "exact rule should not match different title")

print("keyroute-selftest: OK")
