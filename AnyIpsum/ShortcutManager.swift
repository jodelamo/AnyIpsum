import Cocoa
import MASShortcut

struct ShortcutManager {
    
    static let defaultsKey = "shortcutDefaultsKey"
    
    static var defaultShortcut: MASShortcut {
        // Returns the default shortcut, Ctrl+Cmd+A
        let keyCode = Int(kVK_ANSI_A)
        let modifierFlags: NSEvent.ModifierFlags = [NSEvent.ModifierFlags.control, NSEvent.ModifierFlags.command]
        return MASShortcut(keyCode: keyCode, modifierFlags: modifierFlags)
    }

}
