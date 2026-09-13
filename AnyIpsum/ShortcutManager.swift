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

enum ShortcutManagerError: LocalizedError {
    case eventHandlerInstallationFailed(OSStatus)
    case hotKeyUnregistrationFailed(OSStatus)
    case hotKeyRegistrationFailed(OSStatus)
    case hotKeyRestorationFailed(registrationStatus: OSStatus, restorationStatus: OSStatus)

    var errorDescription: String? {
        switch self {
        case let .eventHandlerInstallationFailed(status):
            return "The global shortcut handler could not be installed: \(Self.describe(status))."
        case let .hotKeyUnregistrationFailed(status):
            return "The current global shortcut could not be replaced: \(Self.describe(status))."
        case let .hotKeyRegistrationFailed(status):
            return "That global shortcut is unavailable: \(Self.describe(status))."
        case let .hotKeyRestorationFailed(registrationStatus, restorationStatus):
            return "The new shortcut could not be registered (\(Self.describe(registrationStatus))), "
                + "and the previous shortcut could not be restored (\(Self.describe(restorationStatus)))."
        }
    }

    private static func describe(_ status: OSStatus) -> String {
        let error = NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        return "\(error.localizedDescription) (\(status))"
    }
}

final class ShortcutManager {
    typealias RegisterHotKey = (Shortcut, UnsafeMutablePointer<EventHotKeyRef?>) -> OSStatus
    typealias UnregisterHotKey = (EventHotKeyRef) -> OSStatus

    private static let defaultsKey = "shortcut"
    private static let hotKeyID: UInt32 = 1
    private static let missingReferenceStatus = OSStatus(-1)

    private let action: () -> Void
    private let registerHotKey: RegisterHotKey
    private let unregisterHotKey: UnregisterHotKey
    private var hotKeyRef: EventHotKeyRef?
    private var registeredShortcut: Shortcut?
    private var eventHandler: EventHandlerRef?

    init(action: @escaping () -> Void) {
        self.action = action
        registerHotKey = Self.registerSystemHotKey
        unregisterHotKey = UnregisterEventHotKey
    }

    init(
        action: @escaping () -> Void,
        registerHotKey: @escaping RegisterHotKey,
        unregisterHotKey: @escaping UnregisterHotKey
    ) {
        self.action = action
        self.registerHotKey = registerHotKey
        self.unregisterHotKey = unregisterHotKey
    }

    deinit {
        stop()
    }

    func start(with shortcut: Shortcut) throws {
        try installEventHandler()
        try update(shortcut)
    }

    func update(_ shortcut: Shortcut) throws {
        guard shortcut != registeredShortcut else { return }

        let previousShortcut = registeredShortcut
        if let hotKeyRef {
            let status = unregisterHotKey(hotKeyRef)
            guard status == noErr else {
                throw ShortcutManagerError.hotKeyUnregistrationFailed(status)
            }
            self.hotKeyRef = nil
            registeredShortcut = nil
        }

        let registration = register(shortcut)
        guard registration.status == noErr, let hotKeyRef = registration.reference else {
            let registrationStatus = registration.status == noErr
                ? Self.missingReferenceStatus
                : registration.status

            if let previousShortcut {
                let restoration = register(previousShortcut)
                if restoration.status == noErr, let restoredRef = restoration.reference {
                    self.hotKeyRef = restoredRef
                    registeredShortcut = previousShortcut
                    throw ShortcutManagerError.hotKeyRegistrationFailed(registrationStatus)
                }

                let restorationStatus = restoration.status == noErr
                    ? Self.missingReferenceStatus
                    : restoration.status
                throw ShortcutManagerError.hotKeyRestorationFailed(
                    registrationStatus: registrationStatus,
                    restorationStatus: restorationStatus
                )
            }

            throw ShortcutManagerError.hotKeyRegistrationFailed(registrationStatus)
        }

        self.hotKeyRef = hotKeyRef
        registeredShortcut = shortcut
    }

    func stop() {
        if let hotKeyRef {
            unregisterHotKey(hotKeyRef)
            self.hotKeyRef = nil
            registeredShortcut = nil
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

    private func register(_ shortcut: Shortcut) -> (status: OSStatus, reference: EventHotKeyRef?) {
        var reference: EventHotKeyRef?
        let status = registerHotKey(shortcut, &reference)
        return (status, reference)
    }

    private func installEventHandler() throws {
        guard eventHandler == nil else { return }

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, _, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<ShortcutManager>.fromOpaque(userData).takeUnretainedValue()
            manager.action()
            return noErr
        }

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        guard status == noErr, eventHandler != nil else {
            throw ShortcutManagerError.eventHandlerInstallationFailed(
                status == noErr ? Self.missingReferenceStatus : status
            )
        }
    }

    private static func registerSystemHotKey(
        _ shortcut: Shortcut,
        _ reference: UnsafeMutablePointer<EventHotKeyRef?>
    ) -> OSStatus {
        let hotKey = EventHotKeyID(signature: OSType(0x41495053), id: hotKeyID)
        return RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKey,
            GetApplicationEventTarget(),
            0,
            reference
        )
    }
}
