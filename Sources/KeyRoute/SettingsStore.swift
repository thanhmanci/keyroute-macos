import Foundation
import KeyRouteKit

extension Notification.Name {
    static let keyRouteSettingsDidChange = Notification.Name("KeyRouteSettingsDidChange")
}

final class SettingsStore {
    private let defaults: UserDefaults
    private let key = "KeyRouteSettings.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private(set) var settings: KeyRouteSettings

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = defaults.data(forKey: key),
           let decoded = try? decoder.decode(KeyRouteSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = KeyRouteSettings()
        }
    }

    func setEnabled(_ isEnabled: Bool) {
        guard settings.isEnabled != isEnabled else {
            return
        }
        settings.isEnabled = isEnabled
        save()
    }

    func addRule(_ rule: WhitelistRule) {
        guard !settings.whitelistRules.contains(where: { $0.isDuplicate(of: rule) }) else {
            return
        }
        settings.whitelistRules.append(rule)
        save()
    }

    func removeRules(withIDs ids: Set<UUID>) {
        let originalCount = settings.whitelistRules.count
        settings.whitelistRules.removeAll { ids.contains($0.id) }
        if settings.whitelistRules.count != originalCount {
            save()
        }
    }

    func replaceRules(_ rules: [WhitelistRule]) {
        guard settings.whitelistRules != rules else {
            return
        }
        settings.whitelistRules = rules
        save()
    }

    private func save() {
        if let data = try? encoder.encode(settings) {
            defaults.set(data, forKey: key)
        }
        NotificationCenter.default.post(name: .keyRouteSettingsDidChange, object: self)
    }
}
