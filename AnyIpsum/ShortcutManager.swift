import AppKit
import Carbon.HIToolbox

struct ShortcutKey: Identifiable, Hashable, Sendable {
    let keyCode: UInt32
    let name: String

    var id: UInt32 { keyCode }
}

struct Shortcut: Codable, Equatable, Sendable {
    let keyCode: UInt32
    let modifiers: UInt32
    let keyName: String

    static let `default` = Shortcut(
        keyCode: UInt32(kVK_ANSI_A),
        modifiers: UInt32(controlKey | cmdKey),
        keyName: "A"
    )

    static let availableKeys = [
        ShortcutKey(keyCode: UInt32(kVK_ANSI_A), name: "A"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_B), name: "B"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_C), name: "C"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_D), name: "D"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_E), name: "E"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_F), name: "F"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_G), name: "G"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_H), name: "H"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_I), name: "I"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_J), name: "J"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_K), name: "K"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_L), name: "L"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_M), name: "M"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_N), name: "N"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_O), name: "O"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_P), name: "P"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_Q), name: "Q"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_R), name: "R"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_S), name: "S"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_T), name: "T"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_U), name: "U"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_V), name: "V"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_W), name: "W"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_X), name: "X"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_Y), name: "Y"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_Z), name: "Z"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_0), name: "0"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_1), name: "1"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_2), name: "2"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_3), name: "3"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_4), name: "4"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_5), name: "5"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_6), name: "6"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_7), name: "7"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_8), name: "8"),
        ShortcutKey(keyCode: UInt32(kVK_ANSI_9), name: "9")
    ]

    var displayName: String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result + keyName
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        return modifiers
    }
}

final class ShortcutManager {
    private static let defaultsKey = "shortcut"
    private static let hotKeyID: UInt32 = 1

    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    init(action: @escaping () -> Void) {
        self.action = action
    }

    deinit {
        stop()
    }

    func start(with shortcut: Shortcut) {
        installEventHandler()
        update(shortcut)
    }

    func update(_ shortcut: Shortcut) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        let hotKey = EventHotKeyID(signature: OSType(0x41495053), id: Self.hotKeyID)
        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKey,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func stop() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    static func loadShortcut(defaults: UserDefaults = .standard) -> Shortcut {
        guard let data = defaults.data(forKey: defaultsKey),
              let shortcut = try? JSONDecoder().decode(Shortcut.self, from: data) else {
            return .default
        }
        return shortcut
    }

    static func saveShortcut(_ shortcut: Shortcut, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(shortcut) else { return }
        defaults.set(data, forKey: defaultsKey)
    }

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, _, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<ShortcutManager>.fromOpaque(userData).takeUnretainedValue()
            manager.action()
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }
}
