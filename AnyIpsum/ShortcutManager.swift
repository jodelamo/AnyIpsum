import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let openMenu = Self(
        "openMenu",
        initial: .init(.a, modifiers: [.control, .command])
    )
}

@MainActor
final class ShortcutManager {
    private static let legacyDefaultsKey = "shortcut"

    init(action: @escaping () -> Void) {
        KeyboardShortcuts.onKeyUp(for: .openMenu, action: action)
    }

    static func migrateLegacyShortcut(defaults: UserDefaults = .standard) {
        if let legacyShortcut = loadLegacyShortcut(from: defaults) {
            let shortcut = KeyboardShortcuts.Shortcut(
                carbonKeyCode: Int(legacyShortcut.keyCode),
                carbonModifiers: Int(legacyShortcut.modifiers)
            )
            KeyboardShortcuts.setShortcut(shortcut, for: .openMenu)
            defaults.removeObject(forKey: legacyDefaultsKey)
        }
    }

    private static func loadLegacyShortcut(from defaults: UserDefaults) -> LegacyShortcut? {
        guard let data = defaults.data(forKey: legacyDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(LegacyShortcut.self, from: data)
    }
}

private struct LegacyShortcut: Codable {
    let keyCode: UInt32
    let modifiers: UInt32
    let keyName: String
}
