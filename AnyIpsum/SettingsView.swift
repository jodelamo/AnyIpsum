import AppKit
import Carbon.HIToolbox
import SwiftUI

struct SettingsView: View {
    let model: AppModel

    private let githubURL = URL(string: "https://github.com/jodelamo/AnyIpsum")!

    var body: some View {
        HStack(spacing: 0) {
            sidebar

            Divider()

            generalSettings
        }
        .frame(width: 860, height: 560)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var sidebar: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .accessibilityHidden(true)

            Text("AnyIpsum")
                .font(.system(size: 34, weight: .bold))

            Text("Version \(appVersion)")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text("A simple lorem ipsum generator.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Spacer()

            Link(destination: githubURL) {
                HStack(spacing: 5) {
                    Text("Visit AnyIpsum on GitHub")
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                }
            }
            .font(.callout)
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 42)
        .frame(width: 300)
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("General")
                .font(.system(size: 28, weight: .bold))

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 8) {
                    Text("Open menu shortcut")
                        .font(.headline)

                    Spacer()

                    modifierButton("⌃", name: "Control", mask: UInt32(controlKey))
                    modifierButton("⌥", name: "Option", mask: UInt32(optionKey))
                    modifierButton("⇧", name: "Shift", mask: UInt32(shiftKey))
                    modifierButton("⌘", name: "Command", mask: UInt32(cmdKey))

                    Picker("Key", selection: keyCode) {
                        ForEach(Shortcut.availableKeys) { key in
                            Text(key.name).tag(key.keyCode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 72)
                }

                Divider()

                Text("Use this shortcut from anywhere to open the AnyIpsum menu.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack {
                    Spacer()
                    Button("Use Default Shortcut") {
                        model.resetShortcut()
                    }
                    .buttonStyle(.link)
                }

                if let shortcutError = model.shortcutError {
                    Label(shortcutError, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor.opacity(0.10))
            }

            Spacer()

            HStack(spacing: 8) {
                Spacer()
                Text("Made by Joacim de la Motte")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .accessibilityHidden(true)
            }
        }
        .padding(36)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
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

    private func modifierButton(_ symbol: String, name: String, mask: UInt32) -> some View {
        let isEnabled = model.shortcut.modifiers & mask != 0

        return Button {
            var modifiers = model.shortcut.modifiers
            if isEnabled {
                modifiers &= ~mask
            } else {
                modifiers |= mask
            }

            guard modifiers != 0 else { return }
            model.updateShortcut(Shortcut(
                keyCode: model.shortcut.keyCode,
                modifiers: modifiers,
                keyName: model.shortcut.keyName
            ))
        } label: {
            Text(symbol)
                .font(.system(size: 18, weight: .medium))
                .frame(width: 30, height: 28)
                .background {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isEnabled ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                }
                .foregroundStyle(isEnabled ? Color.white : Color.primary)
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.primary.opacity(isEnabled ? 0 : 0.12))
                }
        }
        .buttonStyle(.plain)
        .help("\(name) modifier")
        .accessibilityLabel(name)
        .accessibilityValue(isEnabled ? "On" : "Off")
    }
}
