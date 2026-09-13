import Carbon.HIToolbox
import SwiftUI

struct SettingsView: View {
    let model: AppModel

    var body: some View {
        Form {
            Section("Keyboard Shortcut") {
                HStack {
                    Text("Open menu")
                    Spacer()

                    modifierButton("⌃", mask: UInt32(controlKey))
                    modifierButton("⌥", mask: UInt32(optionKey))
                    modifierButton("⇧", mask: UInt32(shiftKey))
                    modifierButton("⌘", mask: UInt32(cmdKey))

                    Picker("Key", selection: keyCode) {
                        ForEach(Shortcut.availableKeys) { key in
                            Text(key.name).tag(key.keyCode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 80)
                }

                Button("Use Default Shortcut") {
                    model.resetShortcut()
                }

                if let shortcutError = model.shortcutError {
                    Label(shortcutError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Link("Visit AnyIpsum on GitHub", destination: URL(string: "https://github.com/jlowgren/AnyIpsum")!)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .padding()
    }

    private var keyCode: Binding<UInt32> {
        Binding(
            get: { model.shortcut.keyCode },
            set: { keyCode in
                guard let key = Shortcut.availableKeys.first(where: { $0.keyCode == keyCode }) else {
                    return
                }
                model.updateShortcut(Shortcut(
                    keyCode: key.keyCode,
                    modifiers: model.shortcut.modifiers,
                    keyName: key.name
                ))
            }
        )
    }

    private func modifierButton(_ symbol: String, mask: UInt32) -> some View {
        Toggle(symbol, isOn: Binding(
            get: { model.shortcut.modifiers & mask != 0 },
            set: { enabled in
                var modifiers = model.shortcut.modifiers
                if enabled {
                    modifiers |= mask
                } else {
                    modifiers &= ~mask
                }

                guard modifiers != 0 else { return }
                model.updateShortcut(Shortcut(
                    keyCode: model.shortcut.keyCode,
                    modifiers: modifiers,
                    keyName: model.shortcut.keyName
                ))
            }
        ))
        .toggleStyle(.button)
        .help(symbol + " modifier")
    }
}
